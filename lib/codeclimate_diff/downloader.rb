# frozen_string_literal: true

require "rest-client"

module CodeclimateDiff
  class Downloader
    def self.refresh_baseline_if_configured
      should_download = CodeclimateDiff.configuration["gitlab"]["download_baseline_for_pipeline"]
      return unless should_download

      puts "Downloading baseline file from gitlab"
      branch_name = CodeclimateDiff.configuration["gitlab"]["main_branch_name"]
      project_id = CodeclimateDiff.configuration["gitlab"]["project_id"]
      host = CodeclimateDiff.configuration["gitlab"]["host"]
      personal_access_token = CodeclimateDiff.configuration["gitlab"]["personal_access_token"]

      # curl --output codeclimate_diff_baseline.json --header "PRIVATE-TOKEN: MYTOKEN" "https://gitlab.digitalnz.org/api/v4/projects/85/jobs/artifacts/main/raw/codeclimate_diff_baseline.json?job=code_quality"
      url = "#{host}/api/v4/projects/#{project_id}/jobs/artifacts/#{branch_name}/raw/codeclimate_diff_baseline.json?job=code_quality"
      response = RestClient.get(url, { "PRIVATE-TOKEN": personal_access_token })
      File.write("codeclimate_diff_baseline.json", response.body)
    rescue StandardError => e
      puts e
    end
  end
end
