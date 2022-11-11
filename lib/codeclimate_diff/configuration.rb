# frozen_string_literal: true

module CodeclimateDiff
  class Configuration
    attr_accessor :gitlab

    def initialize
      @gitlab = {
        main_branch_name: "main",
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
