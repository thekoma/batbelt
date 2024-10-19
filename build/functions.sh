#!/bin/bash
function validate_url(){
  url=$1
  code=$(curl -Lo /dev/null --silent -Iw '%{http_code}' "${url}")
  if [[  "$code" == "200" ]]; then
    return 0
  else
    return "$code"
  fi
}

color_echo() {
  local color="$1"
  local message="$2"
  echo -e "\033[${color}m$message\033[0m"
}

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

