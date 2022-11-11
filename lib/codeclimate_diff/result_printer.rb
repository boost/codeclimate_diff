# frozen_string_literal: true

require "json"
require "colorize"

module CodeclimateDiff
  class ResultPrinter
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
  end
end