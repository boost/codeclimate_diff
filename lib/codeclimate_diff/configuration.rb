# frozen_string_literal: true

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
end
