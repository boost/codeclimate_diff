# CodeclimateDiff

This tool lets you see how your branch is affecting the code quality (what issues you've added, fixed, and what issues are outstanding in the files you've touched.)

It covers 3 kinds of code quality metrics (code smells, cyclomatic complexity, and similar code).

NOTE: similar code will only work correctly if you run a diff on all the files in your branch.


## Installation

1. Install the codeclimate cli:
      ``` 
      brew tap codeclimate/formulae
      brew install codeclimate
      ```

2. Add a `.codeclimate.yml` config file eg:
      ```
      ---
      version: "2"
      plugins:
        rubocop:
          enabled: true
          channel: rubocop-1-36-0
        reek:
          enabled: true

      exclude_patterns:
        - config/
        - db/
        - dist/
        - features/
        - public/
        - "**/node_modules/"
        - script/
        - "**/spec/"
        - "**/test/"
        - "**/tests/"
        - Tests/
        - "**/vendor/"
        - "**/*_test.go"
        - "**/*.d.ts"
        - "**/*.min.js"
        - "**/*.min.css"
        - "**/__tests__/"
        - "**/__mocks__/"
        - "/.gitlab/"
        - coverage/
      ```

3. Install the gem

    Add this line to your application's Gemfile:

    ```ruby
    gem 'codeclimate_diff'
    ```

    Install the gem:

    ```bash
    $ bundle install

    # OR just install it locally
    $ gem install codeclimate_diff
    ```

    Then generate the executable:

        $ bundle binstubs codeclimate_diff


4. Run the baseline and commit the result to the repo

    ```
    ./bin/codeclimate_diff --baseline
    ```

## Usage

1. Create a feature branch for your work, and reset the baseline + commit (5 mins)

2. Do some work

3. Check if you've added any issues (about 10 secs per code file changed on your branch)

    ```
    # runs on all code files changed in your branch
    ./bin/codeclimate_diff

    OR

    # filters the changed files in your branch futher
    ./bin/codeclimate_diff --pattern places

    OR

    # only shows the new and fixed issues
    ./bin/codeclimate_diff --new-only
    ```
4. Now you have time to fix the issues yay!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/codeclimate_diff.
