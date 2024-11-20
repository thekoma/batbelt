#!/bin/bash
set -ex
script_dir=$(dirname "$0")
source "$script_dir/functions.sh"

echo https://dl-cdn.alpinelinux.org/alpine/edge/testing |tee -a /etc/apk/repositories

# Directory per i report
mkdir -p /root/reports
ARCH=$(uname -m)
REPORT_FILE="/root/reports/packages-${ARCH}.txt"
UNAVAILABLE_FILE="/root/reports/unavailable-${ARCH}.txt"
ERROR_LOG="/root/reports/errors-${ARCH}.txt"

# Create a list to store packages to be installed
install_list=()

# Simulate installation and build the installation list
apk update --no-interactive --no-progress

# Header del report
echo "# Package Report for architecture: ${ARCH}" > $REPORT_FILE
echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')" >> $REPORT_FILE
echo "" >> $REPORT_FILE
echo "## Available Packages" >> $REPORT_FILE
echo "| Package | Version |" >> $REPORT_FILE
echo "|---------|----------|" >> $REPORT_FILE

echo "# Unavailable Packages for architecture: ${ARCH}" > $UNAVAILABLE_FILE
echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')" >> $UNAVAILABLE_FILE
echo "" >> $UNAVAILABLE_FILE

for pkg in $PACKAGES; do
  echo "-------------------------------------------------------------------"
  echo "Simulating installation of previous packages and adding $pkg"
  if apk add --no-interactive --no-progress --simulate "${install_list[@]}" $pkg > "/tmp/install_${pkg}.log" 2>&1; then
    # Get package version
    version=$(apk policy $pkg | grep -m1 "candidate:" | awk '{print $2}')
    color_echo "32" "Simulation successful: $pkg ($version)"
    install_list+=("$pkg")
    echo "| $pkg | $version |" >> $REPORT_FILE
    rm "/tmp/install_${pkg}.log"
  else
    color_echo "31" "Simulation failed: $pkg"
    echo "- $pkg" >> $UNAVAILABLE_FILE
    echo "### Error log for $pkg:" >> $UNAVAILABLE_FILE
    cat "/tmp/install_${pkg}.log" >> $UNAVAILABLE_FILE
    echo "" >> $UNAVAILABLE_FILE
    continue
  fi
done

# Install packages from the built list
if [[ ${#install_list[@]} -gt 0 ]]; then
  echo "Installing packages: ${install_list[*]}"
  if apk add --no-interactive --no-progress ${install_list[*]}; then
    color_echo "32" "All simulated packages installed successfully!"
  else
    color_echo "31" "Error installing some packages. Check the logs."
    # Verifichiamo quali pacchetti sono stati effettivamente installati
    echo "## Actually Installed Packages" >> $REPORT_FILE
    echo "| Package | Version |" >> $REPORT_FILE
    echo "|---------|----------|" >> $REPORT_FILE
    for pkg in "${install_list[@]}"; do
      if apk info -e "$pkg" > /dev/null 2>&1; then
        version=$(apk info "$pkg" | grep -m1 "$pkg-" | cut -d- -f2-)
        echo "| $pkg | $version |" >> $REPORT_FILE
      fi
    done
  fi
fi

# Aggiungiamo statistiche al report
echo "" >> $REPORT_FILE
echo "## Statistics" >> $REPORT_FILE
echo "- Total packages attempted: $(echo "$PACKAGES" | wc -w)" >> $REPORT_FILE
echo "- Successfully installed: ${#install_list[@]}" >> $REPORT_FILE
echo "- Failed/Unavailable: $(cat $UNAVAILABLE_FILE | grep -c "^-")" >> $REPORT_FILE

# Clean the apk cache at the end
apk cache clean

# Always exit with success
exit 0
