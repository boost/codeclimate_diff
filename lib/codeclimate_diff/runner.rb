# frozen_string_literal: true

require "json"
require "colorize"
require_relative "./codeclimate_wrapper"
require_relative "./result_printer"
require_relative "./issue_sorter"
require_relative "./downloader"

module CodeclimateDiff
  class Runner
    def self.calculate_changed_filenames(pattern)
      extra_grep_filter = pattern ? " | grep '#{pattern}'" : ""
      branch_name = CodeclimateDiff.configuration["main_branch_name"]
      files_changed_str = `git diff --name-only #{branch_name} | grep --invert-match spec/ | grep --extended-regexp '.js$|.rb$'#{extra_grep_filter}`
      puts "Files changed on branch: #{files_changed_str}"

      files_changed_str.split("\n")
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
      Downloader.refresh_baseline_if_configured

      puts "Extracting relevant preexisting issues..."
      all_issues = JSON.parse(File.read("./codeclimate_diff_baseline.json"))

      all_issues.filter { |issue| issue.key?("location") && changed_filenames.include?(issue["location"]["path"]) }
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

      sorted_issues = IssueSorter.sort_issues(preexisting_issues, changed_file_issues)

      ResultPrinter.print_result(sorted_issues, show_preexisting)
      ResultPrinter.print_call_to_action(sorted_issues)
    end
  end
end
