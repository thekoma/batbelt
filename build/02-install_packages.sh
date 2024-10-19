#!/bin/bash
# PACKAGES="bash zsh unavailable-package"
# Initialize empty files for tracking packages

cat > /etc/apk/repositories << EOF; $(echo)

https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/main/
https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community/
https://dl-cdn.alpinelinux.org/alpine/edge/testing/

EOF

> /root/unavailable_packages.txt
> /root/packages.txt

# Function to print in color
color_echo() {
  local color="$1"
  local message="$2"
  echo -e "\033[${color}m$message\033[0m"
}

# Create a list to store packages to be installed
install_list=()

# Simulate installation and build the installation list
apk update --no-interactive --no-progress
for pkg in $PACKAGES; do
  echo "-------------------------------------------------------------------"
  echo "Simulating installation of previous packages and adding $pkg"
  apk add --no-interactive --no-progress --simulate "${install_list[@]}" $pkg > "/tmp/install_${pkg}.log" 2>&1
  RET=$?
  if [ $RET -eq 0 ]; then
    color_echo "32" "Simulation successful: $pkg"
    install_list+=("$pkg")
    rm /tmp/install_${pkg}.log
  else
    color_echo "31" "Simulation failed: $pkg"
    echo "$pkg" >> /root/unavailable_packages.txt
    cat /tmp/install_${pkg}.log
  fi
done

# Install packages from the built list
if [[ ${#install_list[@]} -gt 0 ]]; then
  echo "Installing packages: ${install_list[@]}"
  apk add --no-interactive --no-progress "${install_list[@]}"
  RET=$?
  if [[ $RET -eq 0 ]]; then
    color_echo "32" "All simulated packages installed successfully!"
    echo "${install_list[@]}" >> /root/packages.txt
  else
    color_echo "31" "Error installing some packages. Check the logs."
    # Handle errors, potentially try installing one by one
  fi
fi

# Moving all error log in a single place
for log in $(ls -1 /tmp/install_*.log); do
  echo -e "----------------------------------------\nFailed log for $log\n" > /root/unavailable_packages_error.txt
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
