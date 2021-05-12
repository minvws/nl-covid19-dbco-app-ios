#!/bin/bash

# Config
BASE_REPONAME=nl-covid19-dbco-app-ios

# Helpers
TIMESTAMP=`date '+%Y%m%d-%H%M%S'`
PR_TITLE="Sync+public+repo+from+private+repository" # Use + for spaces as this is used in a URL
PR_BODY="This+PR+proposes+the+latest+changes+from+private+to+public+repository.+Timestamp:+${TIMESTAMP}"
RED="\033[1;31m"
GREEN="\033[1;32m"
ENDCOL="\033[0m"
echo -e "${GREEN}Ensuring a safe environment${ENDCOL}"
if [ -z "$(git status --porcelain)" ]; then 
  # Working directory clean
  echo "Working directory clean"
else 
  # Uncommitted changes
  echo
  echo -e "${RED}Your working directory contains changes.${ENDCOL}"
  echo "To avoid losing changes, this script only works if you have a clean directory."
  echo "Commit any work to the current branch, and try again."
  echo 
  exit
fi

# To ensure the script works regardless of whether you run this from private or public, we ignore origin, and
# add 2 remotes, one for public, one for private
if ! git config remote.public-repo.url > /dev/null; then
    git remote add public-repo git@github.com:minvws/$BASE_REPONAME
    echo -e "${GREEN}Public-repo remote added${ENDCOL}"
fi

if ! git config remote.private-repo.url > /dev/null; then
    git remote add private-repo git@github.com:minvws/$BASE_REPONAME-private
    echo -e "${GREEN}Private-repo remote added${ENDCOL}"
fi

# Create a branch where we sync everything from current private branches
echo -e "${GREEN}Ensuring we are in sync with the private and public repo${ENDCOL}"
git fetch --multiple private-repo public-repo

for BRANCH in main develop
do
  echo -e "${GREEN}Checking if there are changes between the public and private ${BRANCH} branch ${ENDCOL}"
  if [ -z "$(git diff private-repo/${BRANCH}..public-repo/${BRANCH})" ]; then 
    # No PR needed for branch
    echo "No PR needed for ${BRANCH}"
  else 
    # PR needed for branch
    echo -e "${GREEN}Creating a new sync-${BRANCH} branch based on private/${BRANCH}${ENDCOL}"
    git branch sync-${BRANCH}/$TIMESTAMP private-repo/${BRANCH}

    echo -e "${GREEN}Pushing the sync-${BRANCH} branch to public repo${ENDCOL}"
    git push public-repo sync-${BRANCH}/$TIMESTAMP

    echo -e "${GREEN}Constructing a PR request and opening it in the browser${ENDCOL}"
    PR_URL="https://github.com/minvws/$BASE_REPONAME/compare/${BRANCH}...sync-${BRANCH}/$TIMESTAMP?quick_pull=1&title=${PR_TITLE}&body=${PR_BODY}"

    open $PR_URL
  fi
done

echo -e "${GREEN}Done.${ENDCOL}"
