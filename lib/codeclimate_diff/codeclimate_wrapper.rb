# frozen_string_literal: true

require "json"
require "colorize"

module CodeclimateDiff
  class CodeclimateWrapper

    def run_codeclimate(filename = "")
      docker_platform = CodeclimateDiff.configuration["docker_platform"] || "linux/amd64"

      `docker run \
        --interactive --tty --rm \
        --env CODECLIMATE_CODE="$PWD" \
        --volume "$PWD":/code \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        --volume /tmp/cc:/tmp/cc \
        --platform #{docker_platform} \
        codeclimate/codeclimate analyze -f json #{filename}`
    end

    def pull_latest_image
      puts "Downloading latest codeclimate docker image..."
      `docker pull codeclimate/codeclimate`
    end
  end
end
