source "${SCRIPT_DIR}/utils/definitions.sh"

install_ufw() {
  local pkg_manager
  pkg_manager=$(get_package_manager)
  local init_system
  init_system=$(get_init_system)

  adss_dialog "$(trans "Встановлюємо UFW фаєрвол")"

  case "$pkg_manager" in
    dnf)
      install() {
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
        sudo dnf install ufw -y && sudo ufw disable
        sudo systemctl restart ufw.service
      }
      ;;
    yum)
      install() {
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
        sudo yum install epel-release -y && sudo yum install ufw -y && sudo ufw disable
        sudo systemctl restart ufw.service
      }
      ;;
    pacman)
      install() {
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
        sudo pacman -Sy ufw --noconfirm
        sudo ufw disable
        sudo systemctl restart ufw.service
      }
      ;;
    xbps-install)
      install() {
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
        sudo xbps-install -Su ufw && sudo ufw disable
        sudo systemctl restart ufw.service
      }
      ;;
    emerge)
      install() {
        sudo rc-service firewalld stop
        sudo rc-update del firewalld
        sudo emerge -n net-firewall/ufw && sudo ufw disable
        sudo rc-service ufw restart
      }
      ;;
    *)
      install() {
        sudo apt-get update -y && sudo apt-get install ufw -y && sudo ufw disable
        sudo systemctl restart ufw.service
      }
      ;;
  esac

  install >/dev/null 2>&1
  confirm_dialog "$(trans "Фаєрвол UFW встановлено і деактивовано")"
}

ufw_is_active() {
  local svc_cmd
  svc_cmd=$(get_service_is_active_command)
  if $svc_cmd ufw >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

enable_ufw() {
  local init_system
  init_system=$(get_init_system)

  if [[ "$init_system" == "systemd" ]]; then
    sudo systemctl enable ufw >/dev/null 2>&1
    sudo systemctl start ufw >/dev/null 2>&1
  elif [[ "$init_system" == "openrc" ]]; then
    sudo rc-update add ufw >/dev/null 2>&1
    sudo rc-service ufw start >/dev/null 2>&1
  fi
  confirm_dialog "$(trans "UFW успішно увімкнено")"
}

disable_ufw() {
  local init_system
  init_system=$(get_init_system)

  if [[ "$init_system" == "systemd" ]]; then
    sudo systemctl disable ufw >/dev/null 2>&1
    sudo systemctl stop ufw >/dev/null 2>&1
  elif [[ "$init_system" == "openrc" ]]; then
    sudo rc-update del ufw >/dev/null 2>&1
    sudo rc-service ufw stop >/dev/null 2>&1
  fi
  confirm_dialog "$(trans "UFW успішно вимкнено")"
}

ufw_installed() {
  if [[ -n "$(sudo ufw status 2>/dev/null)" ]]; then
    return 0
  else
    return 1
  fi
}

configure_ufw() {
  ufw_installed
  if [[ $? == 0 ]]; then
    confirm_dialog "$(trans "UFW не встановлений, будь ласка встановіть і спробуйте знову")"
  else
    adss_dialog "$(trans "Налаштовуємо UFW фаєрвол")"
    configure() {
      sudo ufw default deny incoming
      sudo ufw default allow outgoing
      sudo ufw allow 22
      sudo ufw --force enable
    }
    configure >/dev/null 2>&1
    confirm_dialog "$(trans "Фаєрвол UFW налаштовано і активовано")"
  fi
}
