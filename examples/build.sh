#!/bin/bash

# Builds every example against the packages in this repository: each package
# is packed and pushed to the local repository, then mirrored into the local
# Ballerina Central cache so the examples resolve them without Central access.
# (Same approach as module-ballerinax-sap.s4hana.* examples, made safe for
# paths containing spaces.)

BAL_EXAMPLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BAL_CENTRAL_DIR="$HOME/.ballerina/repositories/central.ballerina.io"
BAL_HOME_DIR="$BAL_EXAMPLES_DIR/../ballerina"

set -e

case "$1" in
build)
  BAL_CMD="build"
  ;;
run)
  BAL_CMD="run"
  ;;
*)
  echo "Invalid command provided: '$1'. Please provide 'build' or 'run' as the command."
  exit 1
  ;;
esac

# Remove the cache directories in the repositories
for dir in "$BAL_CENTRAL_DIR"/cache-*; do
  [ -d "$dir" ] && rm -r "$dir"
done
echo "Successfully cleaned the cache directories"

find "$BAL_HOME_DIR" -type d -maxdepth 1 -mindepth 1 -print0 | while IFS= read -r -d '' dir; do
  # Skip non-package directories (e.g. the shared test resources/cert folder).
  [ -f "$dir/Ballerina.toml" ] || continue

  # Read Ballerina package name
  BAL_PACKAGE_NAME=$(awk -F'"' '/^name/ {print $2}' "$dir/Ballerina.toml")

  # Push the package to the local repository
  (cd "$dir" && bal pack && bal push --repository=local)

  # Mirror the local repository into the central cache so examples resolve
  # the packages as if they were pulled from Ballerina Central.
  BAL_DESTINATION_DIR="$BAL_CENTRAL_DIR/bala/ballerinax/$BAL_PACKAGE_NAME"
  BAL_SOURCE_DIR="$HOME/.ballerina/repositories/local/bala/ballerinax/$BAL_PACKAGE_NAME"
  mkdir -p "$BAL_DESTINATION_DIR"
  [ -d "$BAL_DESTINATION_DIR" ] && rm -r "$BAL_DESTINATION_DIR"
  [ -d "$BAL_SOURCE_DIR" ] && cp -r "$BAL_SOURCE_DIR" "$BAL_DESTINATION_DIR"
  echo "Successfully updated the local central repository with $BAL_PACKAGE_NAME"
done

# Loop through examples in the examples directory
find "$BAL_EXAMPLES_DIR" -type d -maxdepth 1 -mindepth 1 -print0 | while IFS= read -r -d '' dir; do
  # Skip the build directory
  if [[ "$dir" == *build ]]; then
    continue
  fi
  (cd "$dir" && bal "$BAL_CMD")
done

# Remove generated JAR files
find "$BAL_HOME_DIR" -maxdepth 1 -type f -name "*.jar" -delete
