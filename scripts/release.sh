#!/bin/bash

set -eu

if [ -z "$1" ]; then
  echo "Need version as argument"
  exit -1
fi

version="$1"
changelog=$(awk -v version="$version" '/^## / { printit = $2 == version }; printit' CHANGELOG.md | grep -v "## $version" | sed '1{/^$/d}')

printf "Changelog will be:\\n\\n%s\\n\\n" "$changelog"

read -p "Are you sure to release? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 0
fi

git tag -s -a "$version" -m "$changelog"

git push origin "$version"