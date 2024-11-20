#!/bin/bash
set -e

# Arguments
REPOSITORY=$1
VERSION=$2
OUTPUT_FILE=${3:-"PACKAGES.md"}
REPORT_FILE=${4:-"package_report.md"}
ENV_TYPE=${5:-"prod"}

# Funzione per normalizzare i file di input
normalize_file() {
    local file=$1
    if [ -f "$file" ]; then
        # Verifica se il file termina con newline
        if [ -s "$file" ] && [ "$(tail -c1 "$file" | wc -l)" -eq 0 ]; then
            echo "Adding missing newline to $file"
            echo >> "$file"
        fi
        # Rimuove eventuali righe vuote multiple alla fine
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$file"
        # Assicura una singola riga vuota alla fine
        echo >> "$file"
    fi
}

echo "🏁 Starting package verification process..."

# Normalizza i file di input
echo "📝 Normalizing input files..."
normalize_file "env/${ENV_TYPE}/packagelist.txt"
normalize_file "env/${ENV_TYPE}/binaries.txt"
normalize_file "env/${ENV_TYPE}/krewplugins.txt"

# Crea directory temporanea per i report
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Leggi le piattaforme
mapfile -t PLATFORMS < "env/${ENV_TYPE}/platforms.txt"
echo "📋 Using platforms: ${PLATFORMS[*]}"

# Script per il container
cat > "$TEMP_DIR/check_packages.sh" << 'EOF'
#!/bin/sh
set -e

PLATFORM="$1"
OUTPUT_DIR="/tmp/reports/${PLATFORM}"
mkdir -p "$OUTPUT_DIR"

# Setup environment
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export KREW_ROOT="/.krew"
export PATH="${KREW_ROOT}/bin:$PATH"

# Check Alpine packages
while read -r pkg; do
    if [ -n "$pkg" ]; then
        if apk list -I "${pkg}" >/dev/null 2>&1; then
            version=$(apk list -I "${pkg}" | head -n1 | cut -d' ' -f1 | cut -d'-' -f2-)
            echo "${pkg}|${version}|installed" >> "${OUTPUT_DIR}/packages.txt"
        else
            echo "${pkg}|not installed|not installed" >> "${OUTPUT_DIR}/packages.txt"
        fi
    fi
done < /packages/packagelist.txt

# Check binaries
echo "# Checking binaries in /usr/local/bin"
find /usr/local/bin -type f -executable | while read -r binary_path; do
    binary=$(basename "$binary_path")
    case "$binary" in
        "ctop")
            version=$(ctop -v 2>&1)
            echo "${binary}|${version}|installed" >> "${OUTPUT_DIR}/binaries.txt"
            ;;
        "calicoctl")
            version=$(calicoctl version | grep "Client Version:" | cut -d: -f2 | tr -d ' ')
            echo "${binary}|${version}|installed" >> "${OUTPUT_DIR}/binaries.txt"
            ;;
        "termshark")
            version=$(termshark -v 2>&1)
            echo "${binary}|${version}|installed" >> "${OUTPUT_DIR}/binaries.txt"
            ;;
        "kubectl")
            export KUBECONFIG=/dev/null
            version=$(kubectl version | grep "Client Version:" | cut -d: -f2 | tr -d ' ')
            echo "${binary}|${version}|installed" >> "${OUTPUT_DIR}/binaries.txt"
            ;;
        *)
            echo "${binary}|installed|installed" >> "${OUTPUT_DIR}/binaries.txt"
            ;;
    esac
done

# Check krew plugins
if [ -x "${KREW_ROOT}/bin/kubectl-krew" ]; then
    # Prima ottieni la lista dei plugin
    for plugin in $("${KREW_ROOT}/bin/kubectl-krew" list); do
        # Per ogni plugin, ottieni la versione usando info
        version=$("${KREW_ROOT}/bin/kubectl-krew" info "$plugin" | grep VERSION | cut -d: -f2 | tr -d ' ')
        echo "${plugin}|${version}|installed" >> "${OUTPUT_DIR}/krew.txt"
    done
else
    echo "kubectl-krew not installed" >> "${OUTPUT_DIR}/krew.txt"
fi
EOF

chmod +x "$TEMP_DIR/check_packages.sh"
mkdir -p "$TEMP_DIR/reports"

# Esegui check per ogni piattaforma
for platform in "${PLATFORMS[@]}"; do
    echo "🚀 Checking platform: $platform"
    platform_clean=${platform#linux/}
    mkdir -p "$TEMP_DIR/reports/${platform_clean}"

    docker run --user=root --rm \
        --platform "$platform" \
        --entrypoint="" \
        -v "$TEMP_DIR/check_packages.sh:/check_packages.sh:ro" \
        -v "$(pwd)/env/${ENV_TYPE}:/packages:ro" \
        -v "$TEMP_DIR/reports:/tmp/reports" \
        "ghcr.io/${REPOSITORY}:${VERSION}" \
        /bin/sh /check_packages.sh "${platform_clean}"
done

# Genera il report
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

    while read -r pkg; do
        if [ -n "$pkg" ]; then
            echo -n "| ${pkg} |"
            platform_clean=${PLATFORMS[0]#linux/}
            version=$(grep "^${pkg}|" "$TEMP_DIR/reports/${platform_clean}/packages.txt" | cut -d'|' -f2)
            echo -n " ${version:-not found} |"
            for platform in "${PLATFORMS[@]}"; do
                platform_clean=${platform#linux/}
                if grep -q "^${pkg}|.*|installed" "$TEMP_DIR/reports/${platform_clean}/packages.txt"; then
                    echo -n " ✅ |"
                else
                    echo -n " ❌ |"
                fi
            done
            echo ""
        fi
    done < "env/${ENV_TYPE}/packagelist.txt"

    # Binaries
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

    if [ -s "env/${ENV_TYPE}/binaries.txt" ]; then
        while IFS= read -r binary; do
            binary=$(echo "$binary" | tr -d '\r')
            if [ -n "$binary" ]; then
                echo -n "| ${binary} |"
                platform_clean=${PLATFORMS[0]#linux/}
                version=$(grep "^${binary}|" "$TEMP_DIR/reports/${platform_clean}/binaries.txt" | cut -d'|' -f2)
                echo -n " ${version:-not found} |"
                for platform in "${PLATFORMS[@]}"; do
                    platform_clean=${platform#linux/}
                    if [ -f "$TEMP_DIR/reports/${platform_clean}/binaries.txt" ] && \
                       grep -q "^${binary}|.*|installed" "$TEMP_DIR/reports/${platform_clean}/binaries.txt"; then
                        echo -n " ✅ |"
                    else
                        echo -n " ❌ |"
                    fi
                done
                echo ""
            fi
        done < "env/${ENV_TYPE}/binaries.txt"
    else
        echo "| No binaries configured | - |"
    fi

    # Krew Plugins
    echo ""
    echo "## Kubectl Krew Plugins"
    echo -n "| Plugin | Version |"
    for platform in "${PLATFORMS[@]}"; do
        echo -n " ${platform} |"
    done
    echo ""

    echo -n "|---------|----------|"
    for platform in "${PLATFORMS[@]}"; do
        echo -n "---------|"
    done
    echo ""

    # Usa la prima piattaforma per ottenere la lista dei plugin
    platform_clean=${PLATFORMS[0]#linux/}
    if [ -f "$TEMP_DIR/reports/${platform_clean}/krew.txt" ]; then
        while IFS='|' read -r plugin version status; do
            if [ -n "$plugin" ]; then
                echo -n "| ${plugin} |"
                echo -n " ${version} |"
                for platform in "${PLATFORMS[@]}"; do
                    platform_clean=${platform#linux/}
                    if [ -f "$TEMP_DIR/reports/${platform_clean}/krew.txt" ] && \
                       grep -q "^${plugin}|.*|installed" "$TEMP_DIR/reports/${platform_clean}/krew.txt"; then
                        echo -n " ✅ |"
                    else
                        echo -n " ❌ |"
                    fi
                done
                echo ""
            fi
        done < "$TEMP_DIR/reports/${platform_clean}/krew.txt"
    else
        echo "| No krew plugins installed | - |"
    fi

} | tee "$OUTPUT_FILE" > "$REPORT_FILE"

echo "🎉 Package report generation completed!"