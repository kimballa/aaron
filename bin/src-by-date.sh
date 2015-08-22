#!/usr/bin/env bash

# Gets commits and dates
commits=`git log --reverse --format='format:%H'`

# Ignore commits that load in giant libraries of 3rd party code.
# Crudely, we ignore all commits greater than this size of additions.
MAX_COMMIT_ADD=${MAX_COMMIT_ADD:-15000}

VERBOSE="${VERBOSE:-false}"

if [[ "$1" == "-v" ]]; then
  VERBOSE="true"
fi

cur=0
for c in `echo "$commits"`; do
  commit_dt=`git log --format='format:%ci' $c | head -1 | awk '{print $1}'`
  adds=`git show $c | grep '^+' | wc -l` 
  dels=`git show $c | grep '^-' | wc -l` 
  if [[ "$adds" -gt "$MAX_COMMIT_ADD" ]]; then
    # Ignore commits that load in libraries
    continue
  fi
  cur=$(( $cur + $adds - $dels ))
  if [[ "$VERBOSE" == "true" ]]; then
    echo "$commit_dt,$c,$adds,$dels,$cur"
  else
    echo "$commit_dt,$cur"
  fi
done


