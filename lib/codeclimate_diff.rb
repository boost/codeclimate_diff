# frozen_string_literal: true

require_relative "codeclimate_diff/version"
require_relative "codeclimate_diff/configuration"

module CodeclimateDiff
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
