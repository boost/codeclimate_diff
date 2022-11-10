# Codeclimate Dev

This tool lets you see how your branch is affecting the code quality (what issues you've added, fixed, and what issues are outstanding in the files you've touched.)

It covers 2/3 of our code quality metrics (code smells, cyclomatic complexity, but not similar code).
Codeclimate supports 'duplication' as a plugin, but it takes twice as long to run on everything and only really works if you run it on everything.


## First setup

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

  3. Give execute permission for `codeclimate_diff`

      ```
      chmod a+x ./codeclimate_diff
      ```

  4. Run the baseline and commit the result to the repo

      ```
      ./codeclimate_diff --baseline
      ```

## Normal workflow

1. Create a feature branch for your work, and reset the baseline + commit (5 mins)

2. Do some work

3. Check if you've added any issues (about 10 secs per code file changed on your branch)

    ```
    # runs on all code files changed in your branch
    ./codeclimate_diff

    OR

    # filters the changed files in your branch futher
    ./codeclimate_diff --pattern places

    OR

    # only shows the new and fixed issues
    ./codeclimate_diff --new-only
    ```
4. Now you have time to fix the issues yay!


## Next Steps

- Extract into a Gem
- See if we can improve performance (it spins up a docker container per file)
- Plug into the pipeline and fail if we've introduced more issues than fixed
- Run duplication in the pipeline.
- Run the baseline in the pipeline and download it from the artifact instead of running locally?

