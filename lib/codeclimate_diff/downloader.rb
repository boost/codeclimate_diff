# frozen_string_literal: true

require "rest-client"

module CodeclimateDiff
  class Downloader
    def self.refresh_baseline_if_configured
      return unless CodeclimateDiff.configuration["gitlab"]
      return unless CodeclimateDiff.configuration["gitlab"]["download_baseline_from_pipeline"]

      personal_access_token = ENV.fetch("CODECLIMATE_DIFF_GITLAB_PERSONAL_ACCESS_TOKEN")

      if !personal_access_token
        puts "Missing environment variable 'CODECLIMATE_DIFF_GITLAB_PERSONAL_ACCESS_TOKEN'. Using current baseline."
        return
      end

      puts "Downloading baseline file from gitlab..."
      branch_name = CodeclimateDiff.configuration["main_branch_name"] || "main"
      project_id = CodeclimateDiff.configuration["gitlab"]["project_id"]
      host = CodeclimateDiff.configuration["gitlab"]["host"]
      baseline_filename = CodeclimateDiff.configuration["gitlab"]["baseline_filename"]

      # curl --output codeclimate_diff_baseline.json --header "PRIVATE-TOKEN: MYTOKEN" "https://gitlab.digitalnz.org/api/v4/projects/85/jobs/artifacts/main/raw/codeclimate_diff_baseline.json?job=code_quality"
      url = "#{host}/api/v4/projects/#{project_id}/jobs/artifacts/#{branch_name}/raw/#{baseline_filename}?job=code_quality"
      response = RestClient.get(url, { "PRIVATE-TOKEN": personal_access_token })

      if response.code < 300
        File.write("codeclimate_diff_baseline.json", response.body)
        puts "Successfully updated the baseline."
      else
        puts "Downloading baseline file failed with status code #{response.code}: #{response.body}"
        puts "Using current baseline."
      end

    rescue StandardError => e
      puts e
      puts "Using current baseline."
    end
  end
end
