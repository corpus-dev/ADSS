get_distribution() {
  lsb_dist=""

  if [ -r /etc/os-release ]; then
    lsb_dist="$(. /etc/os-release && echo "$ID")"
    lsb_dist=$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')
  fi

  echo $lsb_dist
}

get_package_manager() {
  local dist
  dist=$(get_distribution)

  case "$dist" in
    debian|ubuntu)
      echo "apt-get"
      ;;
    fedora|rocky|almalinux|ol)
      echo "dnf"
      ;;
    centos)
      echo "yum"
      ;;
    arch|manjaro)
      echo "pacman"
      ;;
    void)
      echo "xbps-install"
      ;;
    gentoo)
      echo "emerge"
      ;;
    *)
      echo "apt-get"
      ;;
  esac
}

get_init_system() {
  if command -v rc-service >/dev/null 2>&1; then
    echo "openrc"
  elif command -v sv >/dev/null 2>&1; then
    echo "runit"
  else
    echo "systemd"
  fi
}

get_service_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-service"
      ;;
    runit)
      echo "sv"
      ;;
    systemd)
      echo "systemctl"
      ;;
  esac
}

get_service_enable_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-update add"
      ;;
    runit)
      echo ""
      ;;
    systemd)
      echo "systemctl enable"
      ;;
  esac
}

get_service_disable_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-update del"
      ;;
    runit)
      echo ""
      ;;
    systemd)
      echo "systemctl disable"
      ;;
  esac
}

get_service_stop_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-service"
      ;;
    runit)
      echo "sv stop"
      ;;
    systemd)
      echo "systemctl stop"
      ;;
  esac
}

get_service_start_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-service"
      ;;
    runit)
      echo "sv start"
      ;;
    systemd)
      echo "systemctl start"
      ;;
  esac
}

get_service_is_active_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-service is-active"
      ;;
    runit)
      echo "sv status"
      ;;
    systemd)
      echo "systemctl is-active --quiet"
      ;;
  esac
}

get_service_is_enabled_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-update is-active"
      ;;
    runit)
      echo "sv status"
      ;;
    systemd)
      echo "systemctl is-enabled"
      ;;
  esac
}

get_service_restart_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    openrc)
      echo "rc-service"
      ;;
    runit)
      echo "sv restart"
      ;;
    systemd)
      echo "systemctl restart"
      ;;
  esac
}

get_service_daemon_reload_command() {
  local init_system
  init_system=$(get_init_system)

  case "$init_system" in
    systemd)
      echo "systemctl daemon-reload"
      ;;
    *)
      echo ""
      ;;
  esac
}
