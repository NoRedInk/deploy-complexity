# deploy-complexity

[![Build Status](https://travis-ci.org/NoRedInk/deploy-complexity.svg?branch=master)](https://travis-ci.org/NoRedInk/deploy-complexity)

Analyze the history and complexity of upcoming and past deploys.

Summarize deploys with statistics like number of PR's, commits, and line changes
as well direct links to the github diff for the deploy, links to migrations, and
individual PRs.

## Examples

```
$ deploy-complexity.rb
Displays code that would be promoted if staging deployed to production, or master
was promoted to staging.
$ deploy-complexity.rb master
Shows the changes between last production deploy and current master
$ deploy-complexity.rb origin/demo origin/master
Displays the changes that would be deployed to demo
$ deploy-complexity.rb -d 3
Displays the last 3 deploys on production
$ deploy-complexity.rb -b staging -d
Show changes from every single staging deploy
$ deploy-complexity.rb --subdir 'subdir/'
Show only PRs that make modifications to files in the subdir/ directory.
```

### For Testing

Use `GIT_DIR` to run a local copy of `pr-checklist` or `deploy-complexity` against another repo directory. Otherwise git may report an "Invalid Symmetric Difference Error" because it's referencing local sha's in deploy-complexity, not the target repo.

```
GIT_DIR=../repo bundle exec ./exe/pr-checklist.rb -b branch
```

Alternatively, `pr-checklist` accepts a `--git-dir` flag. If no git directory is
specified, it will look for a parent directory containing `.git` and if not
fallback to current directory.

### Custom Checklists

If you want to define checklists within your repo, create a ruby file `tools/deploy_complexity/checklists.rb`:

```
module Checklists
  # Example checklist item
  class BlarghDetector < Checklist
    def human_name
      "Blarg!"
    end

    def checklist
    '- [ ] Removed extraneous blargh'.strip
    end

    def relevant_for(changes)
      changes.select do |file|
        file.path.ends_with(".rb") && file.patch =~ /blargh/
      end
    end
  end

  module_function

  # List of checklists to run
  def checklists
    [BlarghDetector].freeze
  end
end
```

And then execute the pr-checklist runner inside of CI using:

```
bundle exec pr-checklist.rb -b branch -c tools/deploy_complexity/checklists.rb
```

#### Overriding `HEAD`

deploy-checklist will, by default, treat current `HEAD` as the `HEAD` commit for change tracking.

It's possible to override that behavior like:

```
bundle exec pr-checklist.rb -b branch -c tools/deploy_complexity/checklists.rb --head-commit fafafafa
```

Where `fafafafa` would be used as the `HEAD`.

This is useful if you run deploy-complexity after merging `master`. Without setting HEAD to the head of the PR pre-merge, the checklists would report on all incoming changes that are completely unrelated to the branch under analysis.

### Github Token

pr-checklist.rb requires a github token with role REPO to edit PR descriptions and comment on a PR. Make sure that `GITHUB_TOKEN` is set in the environment.
