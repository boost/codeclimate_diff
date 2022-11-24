# frozen_string_literal: true

require_relative "lib/codeclimate_diff/version"

Gem::Specification.new do |spec|
  spec.name = "codeclimate_diff"
  spec.version = CodeclimateDiff::VERSION
  spec.authors = ["Isabel Anastasiadis"]
  spec.email = ["isabel@boost.co.nz"]

  spec.summary = "A developer command line tool to see how your branch has affected code quality"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["source_code_uri"] = "https://github.com/boost/codeclimate_diff"
  spec.metadata["changelog_uri"] = "https://github.com/boost/codeclimate_diff/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency("colorize")
  spec.add_dependency("json")
  spec.add_dependency("optparse")
  spec.add_dependency("pry-byebug")
  spec.add_dependency("rest-client")

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
