#!/bin/bash

set -e
set -x

# release.sh will:
# 1. Modify changelog
# 2. Modify version in version/version.go
# 4. Commit and push changes
# 5. Create a Git tag

### Script shamelessly taken form hashicorp/terraform-plugin-sdk
function pleaseUseGNUsed {
    echo "Please install GNU sed to your PATH as 'sed'."
    exit 1
}

function init {
  sed --version > /dev/null || pleaseUseGNUsed

  DATE=`date '+%B %d, %Y'`
  START_DIR=`pwd`

  if [ "$CI" = true ] ; then
    git config --global user.email dev@wilkenrivera.com
    git config --global user.name "nywilken"
  fi

  TARGET_VERSION="$(getTargetVersion)"
  TARGET_VERSION_CORE="$(getVersionCore)"
  TARGET_VERSION_PRERELEASE="$(getVersionPrerelease)"
}

semverRegex='\([0-9]\+\.[0-9]\+\.[0-9]\+\)\(-\?\)\([0-9a-zA-Z.]\+\)\?'

function getTargetVersion {
  # parse target version from CHANGELOG
  sed -n 's/^## '"$semverRegex"' (Upcoming)$/\1\2\3/p' CHANGELOG.md || \
     (echo "\nTarget version not found in changelog, exiting" && \
       exit 1)
}

function getVersionCore {
    # extract major.minor.patch version, e.g. 1.2.3
    echo "${TARGET_VERSION}" | sed -n 's/'"$semverRegex"'/\1/p'
}

function getVersionPrerelease {
    # extract prerelease version, e.g. rc.1
    echo "${TARGET_VERSION}" | sed -n 's/'"$semverRegex"'/\3/p'
}

function modifyChangelog {
  sed -i "s/$TARGET_VERSION (Upcoming)$/$TARGET_VERSION ($DATE)/" CHANGELOG.md
}

function changelogLinks {
  ./scripts/release/changelog_links.sh
}

function changelogMain {
  printf "Modifying Changelog..."
  modifyChangelog
  printf "ok!\n"
  printf "Running Changelog Links..."
  #changelogLinks
  printf "ok!\n"
}

function modifyVersionFiles {
  sed -i "s/const Version =.*/const Version = \"${TARGET_VERSION_CORE}\"/" version/version.go
  sed -i "s/const VersionPrerelease =.*/const VersionPrerelease = \"${TARGET_VERSION_CORE}\"/" version/version.go
}

function commitChanges {
  git add CHANGELOG.md
  modifyVersionFiles
  git add version/version.go
  git diff origin/main

  git reset --hard

  #if [ "$CI" = true ] ; then
      #git commit --gpg-sign="${GPG_KEY_ID}" -m "v${TARGET_VERSION} [skip ci]"
      #git tag -a -m "v${TARGET_VERSION}" -s -u "${GPG_KEY_ID}" "v${TARGET_VERSION}"
  #else
      #git commit -m "v${TARGET_VERSION} [skip ci]"
      #git tag -a -m "v${TARGET_VERSION}" -s "v${TARGET_VERSION}"
  #fi

  #git push origin "${CIRCLE_BRANCH}"
  #git push origin "v${TARGET_VERSION}"
}

function commitMain {
  printf "Committing Changes..."
  commitChanges
  printf "ok!\n"
}

function main {
  init
  changelogMain
  commitMain
}

main
