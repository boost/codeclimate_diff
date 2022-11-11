# frozen_string_literal: true

require "json"
require "colorize"
require_relative "./codeclimate_wrapper"
require_relative "./result_printer"

module CodeclimateDiff
  class Runner


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

    def self.generate_baseline
      puts "Generating the baseline.  Should take about 5 minutes..."
      result = CodeclimateWrapper.new.run_codeclimate
      File.write("codeclimate_diff_baseline.json", result)
      puts "Done!"
    end

    def self.run_diff_on_branch(pattern, show_preexisting: true)
      changed_filenames = calculate_changed_filenames(pattern)

      changed_file_issues = calculate_issues_in_changed_files(changed_filenames)

      preexisting_issues = calculate_preexisting_issues_in_changed_files(changed_filenames)

      sorted_issues = sort_issues(preexisting_issues, changed_file_issues)

      ResultPrinter.print_result(sorted_issues, show_preexisting)
      ResultPrinter.print_call_to_action(sorted_issues)
    end
  end
end
