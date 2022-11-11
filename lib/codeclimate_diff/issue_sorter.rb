# frozen_string_literal: true

module CodeclimateDiff
  class IssueSorter
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
  end
end
