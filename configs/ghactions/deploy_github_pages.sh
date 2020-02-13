#!/bin/sh
# Pushes reposense-report folder generated by RepoSense to gh-pages branch.

set -o errexit # exit with nonzero exit code if any line fails

if [ -z "$GITHUB_TOKEN" ] && [ -z "$GITHUB_DEPLOY_KEY" ]; then
  echo 'GITHUB_TOKEN or GITHUB_DEPLOY_KEY is not set up in Travis. Skipping deploy.'
  exit 0
fi;

cd reposense-report

git init
git config user.name 'Deployment Bot (Travis)'
git config user.email 'deploy@travis-ci.org'
git config core.sshCommand "ssh -i ~/id_git -F /dev/null"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "$GITHUB_DEPLOY_KEY" | base64 -d > ~/id_git
  chmod 400 ~/id_git
  git remote add upstream "git@github.com:${GITHUB_REPOSITORY}.git"
else
  git config credential.helper 'store --file=.git/credentials'
  echo "https://${GITHUB_TOKEN}:@github.com" > .git/credentials
  git remote add upstream "https://github.com/${GITHUB_REPOSITORY}.git"
fi

set -o nounset # exit if variable is unset

# Reset to gh-pages branch, or create orphan branch if gh-pages does not exist in remote.
if git ls-remote --exit-code --heads upstream gh-pages; then
    git fetch --depth=1 upstream gh-pages
    git reset upstream/gh-pages
elif [ $? -eq 2 ]; then # exit code of git ls-remote is 2 if branch does not exist
    git checkout --orphan gh-pages
else # error occurred
    exit $?
fi

# Exit if there are no changes to gh-pages files.
if changes=$(git status --porcelain) && [ -z "$changes" ]; then
    echo 'No changes to GitHub Pages files; exiting.'
    exit 0
fi

git add -A .
git commit -m "Rebuild pages at ${TRAVIS_COMMIT}"
git push --quiet upstream HEAD:gh-pages
