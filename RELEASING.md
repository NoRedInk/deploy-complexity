# Releasing a new version

This gem is primarily consumed internally at NoRedInk and is not published
to rubygems.org.

1. Create a branch named like `release-x.y.z`.
1. Update the version in `lib/deploy_complexity/version.rb`.
1. Run `bundle install`. This will update `Gemfile.lock`.
1. Commit the `version.rb` and `Gemfile.lock` changes with a message like "Prepare release vX.Y.Z".
1. Push the branch and open a PR. Optionally, ask for a review.
1. Once CI is green, merge the PR.
1. Checkout master, pull, and run `gem_push=no bundle exec rake release`. This will tag the current revision and push it to GitHub.
1. Go to [GitHub releases page][releases] and find the draft release. Set the release title to the version string, write a short description of the changes, and publish it.

[releases]: https://github.com/NoRedInk/deploy-complexity/releases
