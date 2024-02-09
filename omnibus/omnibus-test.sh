#!/bin/bash
set -eo pipefail

export CHEF_LICENSE="accept-no-persist"
project_root="$(pwd)"
export project_root

cd test/artifact

PATH=/opt/inspec/bin:/opt/inspec/embedded/bin:$PATH
export PATH

rake

echo "Generating SBOM"
install_dir="/opt/inspec"

# Install syft
echo "Installing syft"
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Check syft version
echo "Checking syft version"
/usr/local/bin/syft version

# Generate SBOM
echo "Generating SBOM"
/usr/local/bin/syft "$install_dir" --output spdx-json > "$install_dir"/embedded/inspec-sbom.json

# Display SBOM
echo "Displaying SBOM"
cat "$install_dir"/embedded/inspec-sbom.json
echo "SBOM generated successfully"
