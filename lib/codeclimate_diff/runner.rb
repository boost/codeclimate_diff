# frozen_string_literal: true

require "json"
require "colorize"
require_relative "./codeclimate_wrapper"

module CodeclimateDiff
  class Runner
    def self.generate_baseline
      puts "Generating the baseline.  Should take about 5 minutes..."
      result = CodeclimateWrapper.new.run_codeclimate
      File.write("codeclimate_diff_baseline.json", result)
      puts "Done!"
    end

    def self.calculate_changed_filenames(pattern)
      extra_grep_filter = pattern ? " | grep '#{pattern}'" : ""
      files_changed = `git diff --name-only main | grep --invert-match spec/ | grep --extended-regexp '.js$|.rb$'#{extra_grep_filter}`
      files_changed.split("\n")
    end

    def self.calculate_issues_in_changed_files(changed_filenames)
      changed_file_issues = []

      changed_filenames.each do |filename|
        next if filename == "codeclimate_diff.rb" # TODO: fix this file's code quality issues when we make a Gem!

        puts "Analysing '#{filename}'..."
        result = CodeclimateWrapper.new.run_codeclimate(filename)
        JSON.parse(result).each do |issue|
          next if issue["type"] != "issue"

          changed_file_issues.append(issue)
        end
      end

      changed_file_issues
    end

    def self.calculate_preexisting_issues_in_changed_files(changed_filenames)
      puts "Extracting relevant preexisting issues..."
      all_issues = JSON.parse(File.read("./codeclimate_diff_baseline.json"))

      all_issues.filter { |issue| issue.key?("location") && changed_filenames.include?(issue["location"]["path"]) }
    end

    def self.remove_closest_match_from_list(issue_to_match, list)
      # check for exact match first
      index = list.index do |issue|
        issue["fingerprint"] == issue_to_match["fingerprint"] &&
          issue["location"]["lines"]["begin"] == issue_to_match["location"]["lines"]["begin"] &&
          issue["description"] == issue_to_match["description"]
      end

      if index
        list.delete_at(index)
        return
      end

      # check for same method name (description often has method name or variable name in it)
      index = list.index do |issue|
        issue["fingerprint"] == issue_to_match["fingerprint"] &&
          issue["description"] == issue_to_match["description"]
      end

      if index
        list.delete_at(index)
        return
      end

      # otherwise just remove the first one
      list.pop
    end

    def self.sort_issues(preexisting_issues, changed_file_issues)
      puts "Sorting into :preexisting, :new and :fixed lists..."

      result = {}
      result[:preexisting] = []
      result[:new] = []
      result[:fixed] = []

      # fingerprints are unique per issue type and file
      # so there could be multiple if the same issue shows up multiple times
      # plus line numbers and method names could have changed
      unique_fingerprints = (preexisting_issues + changed_file_issues).map { |issue| issue["fingerprint"] }.uniq

      unique_fingerprints.each do |fingerprint|
        baseline_issues = preexisting_issues.filter { |issue| issue["fingerprint"] == fingerprint }
        current_issues = changed_file_issues.filter { |issue| issue["fingerprint"] == fingerprint }

        if baseline_issues.count == current_issues.count
          # current issues are most up to date (line numbers could have changed etc.)
          result[:preexisting] += current_issues
        elsif current_issues.count < baseline_issues.count
          # less issues than there were before
          current_issues.each do |issue_to_match|
            CodeclimateDiff.remove_closest_match_from_list(issue_to_match, baseline_issues)
          end
          result[:fixed] += baseline_issues
        else
          # more issues than there were before
          baseline_issues.each do |issue_to_match|
            CodeclimateDiff.remove_closest_match_from_list(issue_to_match, current_issues)
          end
          result[:new] += current_issues
        end
      end

      # do a check to make sure the maths works out
      puts "#{preexisting_issues.count} issues in matching files in baseline"
      puts "#{changed_file_issues.count} current issues in matching files"

      result
    end

    def self.print_issues_in_category(issues_list)
      issues_list.each do |issue|
        filename = issue["location"]["path"]
        line_number = issue["location"]["lines"]["begin"]
        description = issue["description"]

        print "\u2022 #{filename}:#{line_number}".encode("utf-8").bold
        puts " #{description}"
      end
      puts "\n"
    end

    def self.print_category(bullet_emoji, severity, engine_name, check_name, color)
      message = "#{bullet_emoji} [#{severity}] #{engine_name} #{check_name}:".encode("utf-8")

      case color
      when "red"
        puts message.red
      when "yellow"
        puts message.yellow
      when "green"
        puts message.green
      else
        puts message
      end
    end

    def self.print_issues(issues_list, color, bullet_emoji)
      issue_categories = issues_list.map { |issue| [issue["engine_name"], issue["check_name"], issue["severity"]] }.uniq
      issue_categories.each do |issue_category|
        engine_name = issue_category[0]
        check_name = issue_category[1]
        severity = issue_category[2]
        issues = issues_list.filter do |issue|
          issue["engine_name"] == engine_name &&
            issue["check_name"] == check_name &&
            issue["severity"] == severity
        end
        print_category(bullet_emoji, severity, engine_name, check_name, color)
        print_issues_in_category(issues)
      end
    end

    def self.print_result(sorted_issues, show_preexisting)
      if show_preexisting
        preexisting_issues = sorted_issues[:preexisting]
        if preexisting_issues.count.positive?
          puts "\n#{preexisting_issues.count} preexisting issues in changed files:\n".bold.yellow
          print_issues(preexisting_issues, "yellow", "\u2718")
        else
          puts "\n0 issues in changed files!".encode("utf-8").bold.green
        end
      end

      new_issues = sorted_issues[:new]
      if new_issues.count.positive?
        puts "\n#{new_issues.count} new issues:\n".bold.red
        print_issues(new_issues, "red", "\u2718")
      else
        puts "\n0 new issues :)\n".encode("utf-8").bold
      end

      fixed_issues = sorted_issues[:fixed]
      if fixed_issues.count.positive?
        puts "\n#{fixed_issues.count} fixed issues: \n".encode("utf-8").bold.green
        print_issues(fixed_issues, "green", "\u2714")
      else
        puts "\n0 fixed issues\n".bold
      end
    end

    def self.print_call_to_action(sorted_issues)
      fixed_count = sorted_issues[:fixed].count
      new_count = sorted_issues[:new].count
      outstanding_count = sorted_issues[:preexisting].count + new_count
      if  fixed_count > new_count
        puts "\n\u{1F389}\u{1F389} Well done! You made the code even better!! \u{1F389}\u{1F389} \n".bold.green.encode("utf-8")
      elsif new_count > fixed_count
        puts "\n\ Uh oh, you've introduced more issues than you've fixed.  Better fix that! \n".bold.red.encode("utf-8")
      elsif outstanding_count.positive?
        puts "\n\ Why don't you see if you can fix some of those outstanding issues while you're here? \n".bold.encode("utf-8")
      else
        puts "\n\u{1F389}\u{1F389} Nothing to do here, the code is immaculate!! \u{1F389}\u{1F389} \n".bold.green.encode("utf-8")
      end
    end

    def self.run_diff_on_branch(pattern, show_preexisting: true)
      changed_filenames = calculate_changed_filenames(pattern)

      changed_file_issues = calculate_issues_in_changed_files(changed_filenames)

      preexisting_issues = calculate_preexisting_issues_in_changed_files(changed_filenames)

      sorted_issues = sort_issues(preexisting_issues, changed_file_issues)

      print_result(sorted_issues, show_preexisting)
      print_call_to_action(sorted_issues)
    end
  end
end
