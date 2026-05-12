display_menu() {
  title="$1"
  shift
  options=("$@")

  if command -v dialog >/dev/null 2>&1; then
    local dialog_args=()
    local index
    for index in "${!options[@]}"; do
      dialog_args+=("${options[index]}" "")
    done
    local selection=$(dialog --ascii-lines --clear --stdout --cancel-label "$(trans "Вихід")" --title "$title" \
      --menu "$(trans "Оберіть опцію:")" 0 0 0 "${dialog_args[@]}")

    if [[ -z "$selection" ]]; then
      clear >$(tty)
      echo "Exiting..."
      exit 0
    fi
    echo "$selection"
  else
    echo -e "\n${title}\n"
    local i=1
    for opt in "${options[@]}"; do
      echo -e "  $i) $opt"
      ((i++))
    done
    echo -ne "\nОберіть опцію: "
    read -r choice
    case "$choice" in
      [0-9]*)
        idx=$((choice - 1))
        if [[ $idx -ge 0 && $idx -lt ${#options[@]} ]]; then
          echo "${options[$idx]}"
        else
          echo "Неправильний вхідний параметр!"
          exit 1
        fi
        ;;
      *)
        echo "${options[0]}"
        ;;
    esac
  fi
}
