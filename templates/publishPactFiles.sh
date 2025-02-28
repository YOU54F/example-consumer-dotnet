#!/usr/bin/env bash

MISSING=()
[ ! "$PACT_BROKER_BASE_URL" ] && MISSING+=("PACT_BROKER_BASE_URL")
[ ! "$pactfiles" ] && MISSING+=("pactfiles")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ERROR: The following environment variables are not set:"
  printf '\t%s\n' "${MISSING[@]}"
  exit 1
fi

if [ -z "$BUILD_URI" ]; then
# todo update to read these env vars
  build_url="$(System.CollectionUri)$(System.TeamProject)/_build/results?buildId=$(Build.BuildId)"
else
  build_url="$BUILD_URI"
fi

echo """
PACT_BROKER_BASE_URL: $PACT_BROKER_BASE_URL
version: $COMMIT
pactfiles: $pactfiles
branch: $BRANCH
build_url: $build_url
tag: $tag
"""

BRANCH_COMMAND=
if [ "$BRANCH" ]; then
  echo "You set branch"
  BRANCH_COMMAND="--branch $BRANCH"
fi
TAG_COMMAND=
if [ "$tag" ]; then
  echo "You set tag"
  TAG_COMMAND="--tag $tag"
fi
TAG_WITH_BRANCH_COMMAND=
if [ "$tag_with_git_branch" ]; then
  echo "You set tag_with_git_branch"
  TAG_WITH_BRANCH_COMMAND="--tag-with-git-branch"
fi
VERSION_COMMAND=
if [ "$version" ]; then
  echo "You set set"
  VERSION_COMMAND="--consumer-app-version $COMMIT"
else 
# todo update to azure
  VERSION_COMMAND="--consumer-app-version $GITHUB_SHA"
fi

if [ "$PACT_BROKER_TOKEN" ]; then
  echo "You set token"
  PACT_BROKER_TOKEN_ENV_VAR_CMD="-e PACT_BROKER_TOKEN=$PACT_BROKER_TOKEN"
fi

if [ "$PACT_BROKER_USERNAME" ]; then
  echo "You set username"
  PACT_BROKER_USERNAME_ENV_VAR_CMD="-e PACT_BROKER_USERNAME=$PACT_BROKER_USERNAME"
fi

if [ "$PACT_BROKER_PASSWORD" ]; then
  echo "You set password"
  PACT_BROKER_PASSWORD_ENV_VAR_CMD="-e PACT_BROKER_PASSWORD=$PACT_BROKER_PASSWORD"
fi



docker run --rm \
  -w ${PWD} \
  -v ${PWD}:${PWD} \
  -e PACT_BROKER_BASE_URL=$PACT_BROKER_BASE_URL \
  $PACT_BROKER_TOKEN_ENV_VAR_CMD \
  $PACT_BROKER_USERNAME_ENV_VAR_CMD \
  $PACT_BROKER_PASSWORD_ENV_VAR_CMD \
  pactfoundation/pact-cli:latest \
  publish \
  $pactfiles \
  --build-url $build_url \
  $VERSION_COMMAND \
  $BRANCH_COMMAND \
  $TAG_COMMAND \
  $TAG_WITH_BRANCH_COMMAND
