#!/usr/bin/env bash

export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m'

source "$(dirname "${BASH_SOURCE[0]}")/utils/translate.sh"
localization_file=$(apply_localization "$@")
if [[ -n "$localization_file" ]]; then
  source "$localization_file"
fi

WORKING_DIR="/opt/itarmy"

if [ -r /etc/os-release ]; then
  PACKAGE_MANAGER=""
  lsb_dist="$(. /etc/os-release && echo "$ID")"
  lsb_dist=$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')

  case "$lsb_dist" in
  debian|ubuntu)
    PACKAGE_MANAGER="apt-get"
    ;;
  fedora|rocky|almalinux|ol)
    PACKAGE_MANAGER="dnf"
    ;;
  centos)
    PACKAGE_MANAGER="yum"
    ;;
  arch|manjaro)
    PACKAGE_MANAGER="pacman"
    ;;
  void)
    PACKAGE_MANAGER="xbps-install"
    ;;
  gentoo)
    PACKAGE_MANAGER="emerge"
    ;;
  *)
    PACKAGE_MANAGER="apt-get"
    ;;
  esac

  if [[ -n "$PACKAGE_MANAGER" ]]; then
    TOOLS=('zip' 'unzip' 'gnupg' 'ca-certificates' 'curl' 'git' 'dialog' 'tar' 'cron')
    GENTOO_TOOLS=('app-shells/bash-completion' 'zip' 'unzip' 'app-crypt/gnupg' 'ca-certificates' 'curl' 'dev-vcs/git' 'dialog' 'app-arch/tar')

    if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
      for i in "${!TOOLS[@]}"; do
        echo -e "${GREEN}$(trans "Встановлюємо") ${TOOLS[$i]}${NC}"
        sudo "$PACKAGE_MANAGER" -Sy "${TOOLS[$i]}" --noconfirm
      done
    elif [[ "$PACKAGE_MANAGER" == "xbps-install" ]]; then
      sudo "$PACKAGE_MANAGER" -u xbps -y
      sudo "$PACKAGE_MANAGER" -Su libssh2 -y
      for i in "${!TOOLS[@]}"; do
        echo -e "${GREEN}$(trans "Встановлюємо") ${TOOLS[$i]}${NC}"
        sudo "$PACKAGE_MANAGER" -Su "${TOOLS[$i]}" -y
      done
    elif [[ "$PACKAGE_MANAGER" == "emerge" ]]; then
      sudo "$PACKAGE_MANAGER" -vuDN @world
      for i in "${!GENTOO_TOOLS[@]}"; do
        echo -e "${GREEN}$(trans "Встановлюємо") ${GENTOO_TOOLS[$i]}${NC}"
        sudo "$PACKAGE_MANAGER" -n "${GENTOO_TOOLS[$i]}"
      done
    else
      sudo "$PACKAGE_MANAGER" update -y
      for i in "${!TOOLS[@]}"; do
        echo -e "${GREEN}$(trans "Встановлюємо") ${TOOLS[$i]}${NC}"
        sudo "$PACKAGE_MANAGER" install -y "${TOOLS[$i]}"
      done
    fi

    if [[ -d "$WORKING_DIR" ]] && [[ "$(ls -A "$WORKING_DIR")" ]]; then
      echo -e "${GREEN}$(trans "ADSS вже встановлено. Запускаємо оновлення...")${NC}"
      source "${WORKING_DIR}/utils/updater.sh"
      source "${WORKING_DIR}/utils/translate.sh"
      export SCRIPT_DIR="${WORKING_DIR}/"
      update_adss
    else
      sudo mkdir -p "$WORKING_DIR"
      sudo chown "$(whoami)" "$WORKING_DIR"
      echo -e "${GREEN}$(trans "Клонуємо ADSS...")${NC}"
      git clone https://github.com/corpus-dev/ADSS.git "$WORKING_DIR"

      # Apply v1.0.0 baseline configuration
      envFile="$WORKING_DIR/services/EnvironmentFile"

      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'interface='; then
        sed -i 's/\[\/distress\]/interface=\n\[\/distress\]/g' "$envFile"
      fi

      if ! awk '/\[mhddos\]/,/\[\/mhddos\]/' "$envFile" | grep -q 'source='; then
        sed -i 's/\[\/mhddos\]/source=adss\n\[\/mhddos\]/g' "$envFile"
      fi

      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'udp-packet-size='; then
        sed -i 's/\[\/distress\]/udp-packet-size=1252\n\[\/distress\]/g' "$envFile"
      fi
      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'direct-udp-mixed-flood-packets-per-conn='; then
        sed -i 's/\[\/distress\]/direct-udp-mixed-flood-packets-per-conn=30\n\[\/distress\]/g' "$envFile"
      fi

      sed -i '/\[mhddos\]/,/\[\/mhddos\]/ {
                /^\[mhddos\]/b
                /^\[\/mhddos\]/b
                /^[[:space:]]*$/d
              }' "$envFile"

      if ! awk '/\[mhddos\]/,/\[\/mhddos\]/' "$envFile" | grep -q 'use-my-ip='; then
        sed -i 's/\[\/mhddos\]/use-my-ip=0\n\[\/mhddos\]/g' "$envFile"
      fi
      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'source='; then
        sed -i 's/\[\/distress\]/source=adss\n\[\/distress\]/g' "$envFile"
      fi

      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'enable-icmp-flood='; then
        sed -i 's/\[\/distress\]/enable-icmp-flood=0\n\[\/distress\]/g' "$envFile"
      fi
      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'enable-packet-flood='; then
        sed -i 's/\[\/distress\]/enable-packet-flood=0\n\[\/distress\]/g' "$envFile"
      fi
      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'disable-udp-flood='; then
        use_my_ip=$(sed -n '/\[distress\]/,/\[\/distress\]/ s/use-my-ip=\([0-9]\+\)/\1/p' "$envFile")
        if [[ $use_my_ip -eq 0 ]]; then
          sed -i 's/\[\/distress\]/disable-udp-flood=0\n\[\/distress\]/g' "$envFile"
        else
          sed -i 's/\[\/distress\]/disable-udp-flood=1\n\[\/distress\]/g' "$envFile"
        fi
      fi
      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'proxies-path='; then
        sed -i 's/\[\/distress\]/proxies-path=\n\[\/distress\]/g' "$envFile"
      fi

      if ! awk '/\[mhddos\]/,/\[\/mhddos\]/' "$envFile" | grep -q 'cron-to-run='; then
        sed -i 's/\[\/mhddos\]/cron-to-run=\n\[\/mhddos\]/g' "$envFile"
      fi
      if ! awk '/\[mhddos\]/,/\[\/mhddos\]/' "$envFile" | grep -q 'cron-to-stop='; then
        sed -i 's/\[\/mhddos\]/cron-to-stop=\n\[\/mhddos\]/g' "$envFile"
      fi
      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'cron-to-run='; then
        sed -i 's/\[\/distress\]/cron-to-run=\n\[\/distress\]/g' "$envFile"
      fi
      if ! awk '/\[distress\]/,/\[\/distress\]/' "$envFile" | grep -q 'cron-to-stop='; then
        sed -i 's/\[\/distress\]/cron-to-stop=\n\[\/distress\]/g' "$envFile"
      fi

      if ! grep -q '^\[x100\]$' "$envFile" || ! grep -q '^\[/x100\]$' "$envFile"; then
        echo -e "\n[x100]\n[/x100]" >> "$envFile"
      fi
      if ! awk '/\[x100\]/,/\[\/x100\]/' "$envFile" | grep -q 'cron-to-run='; then
        sed -i 's/\[\/x100\]/cron-to-run=\n\[\/x100\]/g' "$envFile"
      fi
      if ! awk '/\[x100\]/,/\[\/x100\]/' "$envFile" | grep -q 'cron-to-stop='; then
        sed -i 's/\[\/x100\]/cron-to-stop=\n\[\/x100\]/g' "$envFile"
      fi

      sudo ln -sf "$WORKING_DIR/bin/adss" /usr/local/bin/adss
      echo -e "${GREEN}$(trans "ADSS встановлено! Запустіть команду 'adss' для початку.")${NC}"
    fi
  else
    echo -e "${RED}$(trans "Менеджер пакетів не знайдено")${NC}"
  fi
else
  echo -e "${RED}$(trans "Неможливо визначити операційну систему")${NC}"
fi
