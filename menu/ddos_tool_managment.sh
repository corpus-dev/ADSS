check_enabled() {
  local init_system
  init_system=$(get_init_system)
  services=("mhddos" "distress" "x100")
  stop_service=0

  for service in "${services[@]}"; do
    if [[ "$init_system" == "systemd" ]]; then
      sudo systemctl is-active "$service" >/dev/null 2>&1 && stop_service=1 && break
    elif [[ "$init_system" == "openrc" ]]; then
      rc-service "$service" is-active >/dev/null 2>&1 && stop_service=1 && break
    elif [[ "$init_system" == "runit" ]]; then
      sv status "$service" >/dev/null 2>&1 && stop_service=1 && break
    fi
  done

  return "$stop_service"
}

create_symlink() {
  local init_system
  init_system=$(get_init_system)

  sudo rm -f /etc/systemd/system/mhddos.service
  sudo rm -f /etc/systemd/system/distress.service

  sudo rm -f /etc/systemd/system/x100.service

  sudo ln -sf "$SCRIPT_DIR"/services/mhddos.service /etc/systemd/system/mhddos.service >/dev/null 2>&1
  sudo ln -sf "$SCRIPT_DIR"/services/distress.service /etc/systemd/system/distress.service >/dev/null 2>&1

  sudo ln -sf "$SCRIPT_DIR"/services/x100.service /etc/systemd/system/x100.service >/dev/null 2>&1
}

stop_services() {
  adss_dialog "$(trans "Зупиняємо атаку")"
  sudo systemctl stop distress.service >/dev/null
  sudo systemctl stop mhddos.service >/dev/null
  confirm_dialog "$(trans "Атака зупинена")"
  ddos_tool_managment
}

get_ddoss_status() {
  local init_system
  init_system=$(get_init_system)
  services=("mhddos" "distress" "x100")
  service=""

  for element in "${services[@]}"; do
    if [[ "$init_system" == "systemd" ]]; then
      systemctl is-active --quiet "$element.service" && service="$element" && break
    elif [[ "$init_system" == "openrc" ]]; then
      rc-service "$element" is-active >/dev/null 2>&1 && service="$element" && break
    elif [[ "$init_system" == "runit" ]]; then
      sv status "$element" >/dev/null 2>&1 && service="$element" && break
    fi
  done

  if [[ -n "$service" ]]; then
    while true; do
      clear
      echo -e "${GREEN}$(trans "Запущено $service")${NC}"

      lsb_version="$(. /etc/os-release && echo "$VERSION_ID")"
      lsb_id="$(. /etc/os-release && echo "$ID")"

      if [[ "$lsb_id" == "ubuntu" ]] && [[ "$lsb_version" < 19* ]]; then
        journalctl -n 20 -u "$service.service" --no-pager
      else
        if [[ $service == "x100" ]]; then
          tail --lines=20 "$SCRIPT_DIR/x100-for-docker/put-your-ovpn-files-here/x100-log-short.txt"
        else
          tail --lines=20 /var/log/adss.log
        fi
      fi

      echo -e "${ORANGE}$(trans "Нажміть будь яку клавішу щоб продовжити")${NC}"
      sleep 3
      if read -rsn1 -t 0.1; then
        break
      fi
    done
  else
    confirm_dialog "$(trans "Немає запущених процесів")"
  fi
}

ddos_tool_managment() {
  menu_items=("$(trans "Статус атаки")")
  check_enabled
  enabled_tool=$?
  if [[ "$enabled_tool" == 1 ]]; then
    menu_items+=("$(trans "Зупинити атаку")")
  fi
  menu_items+=("$(trans "Налаштування автозапуску")")
  is_not_arm_arch
  if [[ $? == 1 ]]; then
    menu_items+=("MHDDOS")
  fi
  menu_items+=("DISTRESS" "X100" "$(trans "Повернутись назад")")
  res=$(display_menu "$(trans "Управління ддос інструментами")" "${menu_items[@]}")

  case "$res" in
  "$(trans "Статус атаки")")
    get_ddoss_status
    ddos_tool_managment
    ;;
  "$(trans "Зупинити атаку")")
    stop_services
    ;;
  "$(trans "Налаштування автозапуску")")
    autoload_configuration
    ;;
  "MHDDOS")
    initiate_mhddos
    ;;
  "DISTRESS")
    initiate_distress
    ;;
  "X100")
    initiate_x100
    ;;
  "$(trans "Повернутись назад")")
    ddos
    ;;
  esac
}
