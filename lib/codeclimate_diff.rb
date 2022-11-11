# frozen_string_literal: true

require_relative "codeclimate_diff/version"
require "yaml"

module CodeclimateDiff
  class << self
    def configuration
      YAML.load_file("./.codeclimate_diff.yml")
    end
  end
end
