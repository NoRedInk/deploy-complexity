# deploy-complexity
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
```
