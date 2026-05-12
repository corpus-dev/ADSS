env_file="/etc/environment"

check_updates() {
  source "$env_file"
  if [ -z "$ADSS_DEPLOYMENT_VERSION" ]; then
    prepare_for_update
  else
    timestamp=$(date +%s)
    diff=$((timestamp - ADSS_DEPLOYMENT_VERSION))
    five_minutes=300
    if [[ $diff -gt $five_minutes ]]; then
      prepare_for_update
    fi
  fi
}
prepare_for_update() {
  echo -e "${GREEN}$(trans "Перевіряємо наявність оновлень")${NC}"
  remote_version=$(curl -s 'https://raw.githubusercontent.com/corpus-dev/ADSS/main/version.txt')

  echo -e "$(trans "Актуальна версія") = ${ORANGE}$remote_version${NC}"

  if [[ -n "$remote_version" ]]; then
    update_adss
  fi
  write_version $(date +%s)
  sleep 2
}
write_version() {
  sudo sed -i '/ADSS_DEPLOYMENT_VERSION/d' $env_file
  echo "ADSS_DEPLOYMENT_VERSION=\"$1\"" | sudo tee -a $env_file >/dev/null 2>&1
  source $env_file
}

update_adss() {
  source "${SCRIPT_DIR}/utils/definitions.sh"
  echo -e "${GREEN}$(trans "Оновляємо ADSS")${NC}"
  cd $SCRIPT_DIR &&
    git pull --all || adss --restore

  local init_system
  init_system=$(get_init_system)

  if [[ "$init_system" == "systemd" ]]; then
    SERVICES=('mhddos' 'distress')
    for SERVICE in "${!SERVICES[@]}"; do
      source "${SCRIPT_DIR}/utils/${SERVICES[$SERVICE]}.sh"
      regenerate_"${SERVICES[$SERVICE]}"_service_file
    done
  fi

  echo -e "${GREEN}$(trans "ADSS успішно оновлено")${NC}"
}
