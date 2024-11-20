#!/bin/bash
set -ex
script_dir=$(dirname "$0")
source "$script_dir/functions.sh"

# Aggiungi repository testing una sola volta
echo https://dl-cdn.alpinelinux.org/alpine/edge/testing |tee -a /etc/apk/repositories

# Directory per i report
mkdir -p /root/reports
ARCH=$(uname -m)
REPORT_FILE="/root/reports/packages-${ARCH}.txt"
UNAVAILABLE_FILE="/root/reports/unavailable-${ARCH}.txt"

# Aggiorna gli indici una sola volta
apk update --no-interactive --no-progress

# Simula l'installazione di tutti i pacchetti in una volta sola
if apk add --no-interactive --no-progress --simulate $PACKAGES > /tmp/simulation.log 2>&1; then
  # Se la simulazione ha successo, installa tutto in una volta
  apk add --no-interactive --no-progress $PACKAGES

  # Genera il report dei pacchetti installati
  echo "# Package Report for architecture: ${ARCH}" > $REPORT_FILE
  echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')" >> $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "## Installed Packages" >> $REPORT_FILE
  echo "| Package | Version |" >> $REPORT_FILE
  echo "|---------|----------|" >> $REPORT_FILE

  # Lista tutti i pacchetti installati con le loro versioni
  apk info -v | sort | while read -r pkg; do
    echo "| ${pkg%%-*} | ${pkg#*-} |" >> $REPORT_FILE
  done
else
  # Se la simulazione fallisce, prova pacchetto per pacchetto
  install_list=()
  for pkg in $PACKAGES; do
    if apk add --no-interactive --no-progress --simulate "$pkg" > "/tmp/install_${pkg}.log" 2>&1; then
      install_list+=("$pkg")
    else
      echo "$pkg" >> $UNAVAILABLE_FILE
    fi
  done

  # Installa i pacchetti disponibili in un'unica operazione
  if [ ${#install_list[@]} -gt 0 ]; then
    apk add --no-interactive --no-progress "${install_list[@]}"
  fi
fi

# Pulisci la cache
apk cache clean

exit 0
