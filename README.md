# CodeclimateDiff

This tool lets you see how changes in your branch will affect the code quality (what issues you've added, fixed, and what issues are outstanding in the files you've touched that could be fixed while you're in the area.)

It runs the https://hub.docker.com/r/codeclimate/codeclimate docker image under the hood, which pays attention to all the normal Code Climate configurations.


## Initial setup

1. Make sure docker is installed and running

2. Add a `.codeclimate.yml` config file eg:
      ```yml
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
        - coverage/ . # simple cov
      ```

3. Add a `.reek.yml` config file eg:

      See https://github.com/troessner/reek#working-with-rails 
      ```yml
      detectors:
        IrresponsibleModule:
          enabled: false

        LongParameterList:
          max_params: 4  # defaults to 3.  You want this number realistic but stretchy so we can move it down

        TooManyStatements:
          max_statements: 10  # defaults to 5.  You want this number realistic but stretchy so we can move it down

        UtilityFunction:
          public_methods_only: true

      directories:
        "app/controllers":
          IrresponsibleModule:
            enabled: false
          NestedIterators:
            max_allowed_nesting: 2
          UnusedPrivateMethod:
            enabled: false
          InstanceVariableAssumption:
            enabled: false
        "app/helpers":
          IrresponsibleModule:
            enabled: false
          UtilityFunction:
            enabled: false
          FeatureEnvy:
            enabled: false
        "app/mailers":
          InstanceVariableAssumption:
            enabled: false
        "app/models":
          InstanceVariableAssumption:
            enabled: false
      ```

4. Add a `.codeclimate_diff.yml` configuration file
      ```
      main_branch_name: master # defaults to main
      threshold_to_run_on_all_files: 8  # when you reach a certain number of files changed, it becomes faster to analyze all files rather than analyze them one by one.
      ```

5. Install the gem

    Add this line to your application's Gemfile:

    ```ruby
    gem 'codeclimate_diff', github: 'boost/codeclimate_diff'
    ```

    Install the gem:

    ```bash
    $ bundle install
    ```

    Then generate the executable:

        $ bundle binstubs codeclimate_diff


6. Run the baseline and commit the result to the repo

    ```
    ./bin/codeclimate_diff --baseline
    ```

## Usage

1. Create a feature branch for your work, and reset the baseline + commit (5 mins)

2. Do some work

3. Check if you've added any issues (about 10 secs per code file changed on your branch):

    ```bash
    # runs on each file changed in your branch (about 10 secs per code file changed on your branch)
    ./bin/codeclimate_diff

    OR

    # filters the changed files in your branch futher by a grep pattern
    ./bin/codeclimate_diff --pattern places

    OR

    # only shows the new and fixed issues
    ./bin/codeclimate_diff --new-only

    OR

    # always analyzes all files rather than the changed files one by one, even if below the 'threshold_to_run_on_all_files' setting.
    # NOTE: similar code issues will only work 100% correctly if you use this setting (otherwise it might miss a similarity with a file you didn't change and think you fixed it)
    ./bin/codeclimate_diff --all
    ```

4. Now you have time to fix the issues, horray!


## Setting it up to download the latest baseline from your CI Pipeline (Gitlab only)

Gitlab has a codeclimate template you can add to your pipeline that runs on main builds and then runs on your branch and outputs a difference (see https://docs.gitlab.com/ee/ci/testing/code_quality.html).

With a few tweaks to your CI configuration, we can pull down the main build baseline from the job so we don't have to do it locally.

1. In your Gitlab CI Configuration where you include the `Code-Quality.gitlab-ci.yml` template:

      ```yml
      include:
        - template: Code-Quality.gitlab-ci.yml

      # add this bit:
      code_quality:
        artifacts:
          paths: [gl-code-quality-report.json] .  # without this, the artifact can't be downloaded
      ```

2. Add your project settings to the `.codecimate_diff.yml` configuration file:
      ```yml
      main_branch_name: main

      # settings to pull down the baseline from the pipeline in Gitlab before checking your branch
      gitlab:
        download_baseline_from_pipeline: true   # If false or excluded, you will need to generate the baseline manually
        project_id: '<project id>'
        host: https://gitlab.digitalnz.org/
        baseline_filename: 'gl-code-quality-report.json'
      ```

3. Create a personal access token with `read_api` access and save it in the `CODECLIMATE_DIFF_GITLAB_PERSONAL_ACCESS_TOKEN` env variable

Now when you run it on the changed files in your branch, it will download the latest baseline first!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/codeclimate_diff.
