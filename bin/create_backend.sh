#!/bin/bash

set -eo pipefail

die() {
    echo "Error: ${1:-No error message provided}" > /dev/stderr
    exit 1
}

[[ -r "$1" ]] || die "First parameter must be the source terraform backend (HCL) file."

[[ -n "$2" ]] || die "Second parameter must be the destination backend configuration file."

[[ -n "$secret_magic_juju" ]] || die "The env. var. $$secret_magic_juju must be non-empty."

if egrep -q 'backend "local"' "$1"; then
    echo "# No configuration required for 'local' provider" > "$2"
    echo "# The secret was: $secret_magic_juju" >> "$2"
else
    die "This example script only supports the local backend type"
fi
