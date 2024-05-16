#!/bin/bash
set -eo pipefail

export CHEF_LICENSE="accept-no-persist"
project_root="$(pwd)"
export project_root

git_version=$(git --version)
echo "Git version: $git_version"

cd test/artifact

PATH=/opt/inspec/bin:/opt/inspec/embedded/bin:$PATH
export PATH

rake
