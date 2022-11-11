# frozen_string_literal: true

require_relative "codeclimate_diff/version"

module CodeclimateDiff
  class Configuration
    attr_accessor :gitlab,
                  :github

    def initialize
      @gitlab = {
        main_branch_name: "main",
        download_baseline_from_pipeline: false,
        project_id: nil,
        host: nil,
        personal_access_token: nil
      }

      @github = {
        # TODO: Add GitHub requirements
      }
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
