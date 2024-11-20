#!/bin/bash
set -e

# Arguments
REPOSITORY=$1
VERSION=$2
OUTPUT_FILE=${3:-"PACKAGES.md"}
REPORT_FILE=${4:-"package_report.md"}

echo "🏁 Starting package verification process..."

# Crea directory temporanea per i report
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Crea script da eseguire nel container
cat > "$TEMP_DIR/check_packages.sh" << 'EOF'
#!/bin/sh
set -e

PLATFORM=$(uname -m)
OUTPUT_FILE="/reports/platform_${PLATFORM}.txt"
BINARY_OUTPUT="/reports/binary_${PLATFORM}.txt"
KREW_OUTPUT="/reports/krew_${PLATFORM}.txt"

# Check Alpine packages
echo "📦 Checking Alpine packages for ${PLATFORM}..."
while read -r pkg; do
  if apk list -I "$pkg" >/dev/null 2>&1; then
    version=$(apk list -I "$pkg" | head -n1 | cut -d' ' -f1 | cut -d'-' -f2-)
    echo "${pkg}|${version}" >> "$OUTPUT_FILE"
  else
    echo "${pkg}|not installed" >> "$OUTPUT_FILE"
  fi
done < /packages/packagelist.txt

# Check binaries
echo "🔧 Checking binaries..."
for binary in ctop calicoctl termshark oc kubectl; do
  if command -v "$binary" >/dev/null 2>&1; then
    version=$($binary --version 2>&1 | head -n1)
    echo "${binary}|${version}" >> "$BINARY_OUTPUT"
  else
    echo "${binary}|not installed" >> "$BINARY_OUTPUT"
  fi
done

# Check krew plugins
echo "🔌 Checking krew plugins..."
while read -r plugin; do
  if kubectl krew list 2>/dev/null | grep -q "^$plugin\$"; then
    echo "${plugin}|installed" >> "$KREW_OUTPUT"
  else
    echo "${plugin}|not installed" >> "$KREW_OUTPUT"
  fi
done < /packages/krewplugins.txt
EOF

chmod +x "$TEMP_DIR/check_packages.sh"

# Crea directory per i report
mkdir -p "$TEMP_DIR/reports"

# Esegui i check per ogni piattaforma in parallelo
for platform in amd64 arm64 "arm/v8" "arm/v7" "arm/v6"; do
  echo "🚀 Checking platform: $platform"
  docker run --rm \
    --platform "linux/$platform" \
    -v "$TEMP_DIR/check_packages.sh:/check_packages.sh:ro" \
    -v "$(pwd)/env/prod:/packages:ro" \
    -v "$TEMP_DIR/reports:/reports" \
    "ghcr.io/${REPOSITORY}:${VERSION}" \
    /check_packages.sh &
done

# Aspetta che tutti i check siano completati
wait

echo "📝 Generating final report..."

# Genera il report finale
{
  echo "# 📦 Batbelt Packages"
  echo ""
  echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo ""

  # Alpine Packages
  echo "## Alpine Packages"
  echo "| Package | Version | amd64 | arm64 | arm/v8 | arm/v7 | arm/v6 |"
  echo "|---------|----------|-------|--------|---------|---------|---------|"

  while read -r pkg; do
    echo -n "| $pkg |"
    # Prendi la versione da amd64 come riferimento
    version=$(grep "^${pkg}|" "$TEMP_DIR/reports/platform_x86_64.txt" | cut -d'|' -f2 || echo "not found")
    echo -n " $version |"

    for platform in x86_64 aarch64 armv8 armv7 armv6; do
      if grep -q "^${pkg}|.*" "$TEMP_DIR/reports/platform_${platform}.txt" 2>/dev/null; then
        echo -n " ✅ |"
      else
        echo -n " ❌ |"
      fi
    done
    echo ""
  done < env/prod/packagelist.txt

  # Custom Binaries
  echo ""
  echo "## Custom Binaries"
  echo "| Binary | Version | amd64 | arm64 | arm/v8 | arm/v7 | arm/v6 |"
  echo "|---------|----------|-------|--------|---------|---------|---------|"

  for binary in ctop calicoctl termshark oc kubectl; do
    echo -n "| $binary |"
    version=$(grep "^${binary}|" "$TEMP_DIR/reports/binary_x86_64.txt" | cut -d'|' -f2 || echo "not found")
    echo -n " $version |"

    for platform in x86_64 aarch64 armv8 armv7 armv6; do
      if grep -q "^${binary}|.*installed" "$TEMP_DIR/reports/binary_${platform}.txt" 2>/dev/null; then
        echo -n " ✅ |"
      else
        echo -n " ❌ |"
      fi
    done
    echo ""
  done

  # Krew Plugins
  echo ""
  echo "## Kubectl Krew Plugins"
  echo "| Plugin | amd64 | arm64 | arm/v8 | arm/v7 | arm/v6 |"
  echo "|---------|-------|--------|---------|---------|---------|"

  while read -r plugin; do
    echo -n "| $plugin |"
    for platform in x86_64 aarch64 armv8 armv7 armv6; do
      if grep -q "^${plugin}|installed" "$TEMP_DIR/reports/krew_${platform}.txt" 2>/dev/null; then
        echo -n " ✅ |"
      else
        echo -n " ❌ |"
      fi
    done
    echo ""
  done < env/prod/krewplugins.txt

} | tee "$OUTPUT_FILE" > "$REPORT_FILE"

echo "🎉 Package report generation completed!"