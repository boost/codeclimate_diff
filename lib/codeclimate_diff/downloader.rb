# frozen_string_literal: true

require "rest-client"
require "yaml"

module CodeclimateDiff
  class Downloader

    def self.refresh_baseline_if_configured

      config = YAML.load_file("./.codeclimate_diff.yml")

      puts config

      should_download = config['gitlab']['download_baseline_for_pipeline']
      return unless should_download

      puts "downloading baseline file from gitlab"
      branch_name = config['gitlab']['main_branch_name']
      project_id = config['gitlab']['project_id']
      host = config['gitlab']['host']
      personal_access_token = config['gitlab']['personal_access_token']

      # curl --output codeclimate_diff_baseline.json --header "PRIVATE-TOKEN: MYTOKEN" "https://gitlab.digitalnz.org/api/v4/projects/85/jobs/artifacts/main/raw/codeclimate_diff_baseline.json?job=code_quality"
      url = "#{host}/api/v4/projects/#{project_id}/jobs/artifacts/#{branch_name}/raw/codeclimate_diff_baseline.json?job=code_quality"
      response = RestClient.get(url, { "PRIVATE-TOKEN": personal_access_token })
      File.write("codeclimate_diff_baseline.json", response.body)
    rescue StandardError => e
      puts e
    end
  end
end
