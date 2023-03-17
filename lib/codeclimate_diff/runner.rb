# frozen_string_literal: true

require "json"
require "colorize"
require "pry-byebug"
require_relative "./codeclimate_wrapper"
require_relative "./result_printer"
require_relative "./issue_sorter"
require_relative "./downloader"

module CodeclimateDiff
  class Runner
    def self.calculate_changed_filenames(pattern)
      extra_grep_filter = pattern ? " | grep '#{pattern}'" : ""
      branch_name = CodeclimateDiff.configuration["main_branch_name"] || "main"
      all_files_changed_str = `git diff --name-only #{branch_name} | grep --extended-regexp '.js$|.rb$'#{extra_grep_filter}`
      all_files_changed = all_files_changed_str.split("\n")
                                               .filter { |filename| File.exist?(filename) }

      # load the exclude patterns list from .codeclimate.yml
      exclude_patterns = []
      if File.exist?(".codeclimate.yml")
        config = YAML.load_file(".codeclimate.yml")
        exclude_patterns = config["exclude_patterns"]
      end

      files_and_directories_excluded = exclude_patterns.map { |exclude_pattern| Dir.glob(exclude_pattern) }.flatten

      # filter out any files that match the excluded ones
      all_files_changed.filter do |filename|
        next if files_and_directories_excluded.include? filename

        next if files_and_directories_excluded.any? { |excluded_filename| filename.start_with?(excluded_filename) }

        true
      end
    end

    def self.calculate_issues_in_changed_files(changed_filenames, always_analyze_all_files)
      changed_file_issues = []

      threshold_to_run_on_all_files = CodeclimateDiff.configuration["threshold_to_run_on_all_files"] || 8
      analyze_all_files = always_analyze_all_files || changed_filenames.count > threshold_to_run_on_all_files
      if analyze_all_files
        message = always_analyze_all_files ? "Analyzing all files..." : "The number of changed files is greater than the threshold '#{threshold_to_run_on_all_files}', so analyzing all files..."
        puts message

        result = CodeclimateWrapper.new.run_codeclimate
        JSON.parse(result).each do |issue|
          next if issue["type"] != "issue"
          next unless changed_filenames.include? issue["location"]["path"]

          changed_file_issues.append(issue)
        end

      else
        changed_filenames.each do |filename|
          puts "Analysing '#{filename}'..."
          result = CodeclimateWrapper.new.run_codeclimate(filename)
          JSON.parse(result).each do |issue|
            next if issue["type"] != "issue"

            changed_file_issues.append(issue)
          end
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
      CodeclimateWrapper.new.pull_latest_image

      puts "Generating the baseline.  Should take about 5 minutes..."
      result = CodeclimateWrapper.new.run_codeclimate
      File.write("codeclimate_diff_baseline.json", result)
      puts "Done!"
    end

    def self.run_diff_on_branch(pattern, always_analyze_all_files: false, show_preexisting: true)
      CodeclimateWrapper.new.pull_latest_image

      changed_filenames = calculate_changed_filenames(pattern)

      changed_file_issues = calculate_issues_in_changed_files(changed_filenames, always_analyze_all_files)

      preexisting_issues = calculate_preexisting_issues_in_changed_files(changed_filenames)

      sorted_issues = IssueSorter.sort_issues(preexisting_issues, changed_file_issues)

      ResultPrinter.print_result(sorted_issues, show_preexisting)
      ResultPrinter.print_call_to_action(sorted_issues)
    end
  end
end
