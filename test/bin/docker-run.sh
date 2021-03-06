#!/bin/bash

export CI=true
export CIRCLECI=true
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

cd /OpenStudio-Beopt
bundle install

rake update_resources

# Run a specific set of tests on each node.
# Test groups are defined in the Rakefile.
# Each group must have a total runtime less
# than 2 hrs.
case $CIRCLE_NODE_INDEX in
  0)
    # We currently only use one node to make Coveralls happy.
    rake test:all
    ;;
  #1)
  #  ;;
  #2)
  #  ;;
  #3)
  #  ;;
  *)
esac