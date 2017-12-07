#!/bin/sh
set -euo pipefail

# one argument: component name
if [ $# -ne 1 ]; then
    echo "Usage: $0 <component-name>" >&2
    exit 1
fi
COMPONENT="$1"

# open output file, add static intro
exec > "pkg/${COMPONENT}.pkg.toml"
cat "src/${COMPONENT}.toml"

# add an entry for every installed file and directory
cd pkg/${COMPONENT}
find -type f | grep -v .gitkeep | sed 's+^\./++' | while read FILE; do
    echo '[[file]]'
    echo "path = \"/${FILE}\""
    echo "contentFrom = \"${COMPONENT}/${FILE}\""
    echo "mode = \"$(stat --printf="%04a" "${FILE}")\""
done
find -type d -empty | sed 's+^\./++' | while read DIR; do
    echo '[[directory]]'
    echo "path = \"/${DIR}\""
    echo "mode = \"$(stat --printf="%04a" "${DIR}")\""
done
find -type l | sed 's+^\./++' | while read LINK; do
    echo '[[symlink]]'
    echo "path = \"/${LINK}\""
    echo "target = \"$(readlink "${LINK}")\""
done
