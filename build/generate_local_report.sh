#!/bin/bash

# Configurazione di default
DEFAULT_VERSION="latest"
DEFAULT_ENV="test"
DEFAULT_OUTPUT="PACKAGES.local.md"
DEFAULT_REPORT="report.local.md"

# Parsing degli argomenti
VERSION="${1:-$DEFAULT_VERSION}"
ENV_TYPE="${2:-$DEFAULT_ENV}"
OUTPUT="${3:-$DEFAULT_OUTPUT}"
REPORT="${4:-$DEFAULT_REPORT}"

echo "🔍 Generating report for:"
echo "   Version: $VERSION"
echo "   Environment: $ENV_TYPE"
echo "   Output file: $OUTPUT"
echo "   Report file: $REPORT"

# Esegui lo script principale
./build/generate_package_report.sh \
  "thekoma/batbelt" \
  "$VERSION" \
  "$OUTPUT" \
  "$REPORT" \
  "$ENV_TYPE"