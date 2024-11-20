#!/bin/bash
set -ex
# PACKAGES="bash zsh unavailable-package"
# Initialize empty files for tracking packages
script_dir=$(dirname "$0")
source "$script_dir/functions.sh"

echo https://dl-cdn.alpinelinux.org/alpine/edge/testing |tee -a /etc/apk/repositories

touch /root/unavailable_packages.txt
touch /root/packages.txt

# Create a list to store packages to be installed
install_list=()

# Simulate installation and build the installation list
apk update --no-interactive --no-progress
for pkg in $PACKAGES; do
  echo "-------------------------------------------------------------------"
  echo "Simulating installation of previous packages and adding $pkg"
  if apk add --no-interactive --no-progress --simulate "${install_list[@]}" $pkg > "/tmp/install_${pkg}.log" 2>&1; then
    color_echo "32" "Simulation successful: $pkg"
    install_list+=("$pkg")
    rm "/tmp/install_${pkg}.log"
  else
    color_echo "31" "Simulation failed: $pkg"
    echo "$pkg" >> /root/unavailable_packages.txt
    cat "/tmp/install_${pkg}.log"
    # Non interrompere il build se un pacchetto non è disponibile
    continue
  fi
done

# Install packages from the built list
if [[ ${#install_list[@]} -gt 0 ]]; then
  echo "Installing packages: ${install_list[*]}"
  if apk add --no-interactive --no-progress ${install_list[*]}; then
    color_echo "32" "All simulated packages installed successfully!"
    echo "${install_list[*]}" >> /root/packages.txt
  else
    color_echo "31" "Error installing some packages. Check the logs."
    # Non interrompere il build se l'installazione fallisce
    # Salviamo comunque i pacchetti che sono stati installati con successo
    apk info | grep -f <(printf "%s\n" "${install_list[@]}") >> /root/packages.txt
  fi
fi

# Moving all error log in a single place
for log in $(find /tmp -name install_\*.log); do
  echo -e "----------------------------------------\nFailed log for $log\n" >> /root/unavailable_packages_error.txt
  cat ${log} >> /root/unavailable_packages_error.txt
done

echo "----------------------------------------"

# Print unavailable packages in red
color_echo "31" "Unavailable Packages:"
cat /root/unavailable_packages.txt

echo "----------------------------------------"

# Print available packages in green
color_echo "32" "Available Packages:"
cat /root/packages.txt

# Clean the apk cache at the end
apk cache clean

# Always exit with successo
exit 0
