#!/bin/bash
set -e

# Arguments
REPOSITORY=$1
VERSION=$2
OUTPUT_FILE=${3:-"PACKAGES.md"}
REPORT_FILE=${4:-"package_report.md"}
ENV_TYPE=${5:-"prod"}

echo "🏁 Starting package verification process..."

# Crea directory temporanea per i report
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Leggi le piattaforme dal file corretto
mapfile -t PLATFORMS < "env/${ENV_TYPE}/platforms.txt"
echo "📋 Using platforms: ${PLATFORMS[*]}"

# Crea script da eseguire nel container
cat > "$TEMP_DIR/check_packages.sh" << 'EOF'
#!/bin/sh
set -e

PLATFORM="$1"
OUTPUT_DIR="/reports"

# Check Alpine packages
echo "📦 Checking Alpine packages for ${PLATFORM}..."
while IFS= read -r pkg; do
  if apk list -I "${pkg}" >/dev/null 2>&1; then
    version=$(apk list -I "${pkg}" | head -n1 | cut -d' ' -f1 | cut -d'-' -f2-)
    echo "${pkg}|${version}|installed" >> "${OUTPUT_DIR}/packages.txt"
  else
    echo "${pkg}|not installed|not installed" >> "${OUTPUT_DIR}/packages.txt"
  fi
done < /packages/packagelist.txt

# Check binaries
echo "🔧 Checking binaries..."
while IFS= read -r binary; do
  if command -v "${binary}" >/dev/null 2>&1; then
    version=$("${binary}" --version 2>&1 | head -n1)
    echo "${binary}|${version}|installed" >> "${OUTPUT_DIR}/binaries.txt"
  else
    echo "${binary}|not installed|not installed" >> "${OUTPUT_DIR}/binaries.txt"
  fi
done < /packages/binaries.txt

# Check krew plugins
echo "🔌 Checking krew plugins..."
while IFS= read -r plugin; do
  if kubectl krew list 2>/dev/null | grep -q "^${plugin}\$"; then
    echo "${plugin}|installed" >> "${OUTPUT_DIR}/krew.txt"
  else
    echo "${plugin}|not installed" >> "${OUTPUT_DIR}/krew.txt"
  fi
done < /packages/krewplugins.txt
EOF

chmod +x "$TEMP_DIR/check_packages.sh"
mkdir -p "$TEMP_DIR/reports"

# Esegui i check per ogni piattaforma
for platform in "${PLATFORMS[@]}"; do
  echo "🚀 Checking platform: $platform"
  platform_clean=${platform#linux/}
  docker run --rm \
    --platform "$platform" \
    --entrypoint="" \
    -v "$TEMP_DIR/check_packages.sh:/check_packages.sh:ro" \
    -v "$(pwd)/env/${ENV_TYPE}:/packages:ro" \
    -v "$TEMP_DIR/reports:/reports" \
    "ghcr.io/${REPOSITORY}:${VERSION}" \
    /bin/sh /check_packages.sh "${platform_clean}"
done

# Genera il report finale
{
  echo "# 📦 Batbelt Packages"
  echo ""
  echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo ""

  # Alpine Packages
  echo "## Alpine Packages"
  echo -n "| Package | Version |"
  for platform in "${PLATFORMS[@]}"; do
    echo -n " ${platform} |"
  done
  echo ""

  echo -n "|---------|----------|"
  for platform in "${PLATFORMS[@]}"; do
    echo -n "---------|"
  done
  echo ""

  # Leggi tutti i pacchetti e genera la tabella
  while IFS= read -r pkg; do
    echo -n "| ${pkg} |"
    # Prendi la versione dal primo file disponibile
    version=$(grep "^${pkg}|" "$TEMP_DIR/reports/packages.txt" | cut -d'|' -f2 | head -n1)
    echo -n " ${version:-not found} |"

    for platform in "${PLATFORMS[@]}"; do
      if grep -q "^${pkg}|.*|installed" "$TEMP_DIR/reports/packages.txt"; then
        echo -n " ✅ |"
      else
        echo -n " ❌ |"
      fi
    done
    echo ""
  done < "env/${ENV_TYPE}/packagelist.txt"

  # Custom Binaries
  echo ""
  echo "## Custom Binaries"
  echo -n "| Binary | Version |"
  for platform in "${PLATFORMS[@]}"; do
    echo -n " ${platform} |"
  done
  echo ""

  echo -n "|---------|----------|"
  for platform in "${PLATFORMS[@]}"; do
    echo -n "---------|"
  done
  echo ""

  while IFS= read -r binary; do
    echo -n "| ${binary} |"
    version=$(grep "^${binary}|" "$TEMP_DIR/reports/binaries.txt" | cut -d'|' -f2 | head -n1)
    echo -n " ${version:-not found} |"

    for platform in "${PLATFORMS[@]}"; do
      if grep -q "^${binary}|.*|installed" "$TEMP_DIR/reports/binaries.txt"; then
        echo -n " ✅ |"
      else
        echo -n " ❌ |"
      fi
    done
    echo ""
  done < "env/${ENV_TYPE}/binaries.txt"

  # Krew Plugins
  echo ""
  echo "## Kubectl Krew Plugins"
  echo -n "| Plugin |"
  for platform in "${PLATFORMS[@]}"; do
    echo -n " ${platform} |"
  done
  echo ""

  echo -n "|---------|"
  for platform in "${PLATFORMS[@]}"; do
    echo -n "---------|"
  done
  echo ""

  while IFS= read -r plugin; do
    echo -n "| ${plugin} |"
    for platform in "${PLATFORMS[@]}"; do
      if grep -q "^${plugin}|installed" "$TEMP_DIR/reports/krew.txt"; then
        echo -n " ✅ |"
      else
        echo -n " ❌ |"
      fi
    done
    echo ""
  done < "env/${ENV_TYPE}/krewplugins.txt"

} | tee "$OUTPUT_FILE" > "$REPORT_FILE"

echo "🎉 Package report generation completed!"