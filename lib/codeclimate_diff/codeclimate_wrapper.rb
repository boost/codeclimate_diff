# frozen_string_literal: true

require "json"
require "colorize"

module CodeclimateDiff
  class CodeclimateWrapper
    def run_codeclimate(filename = "")
      `codeclimate analyze -f json #{filename}`
    end
  end
end
