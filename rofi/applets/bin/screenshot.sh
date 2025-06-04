#!/usr/bin/env bash

## Author  : Aditya Shakya (adi1090x)
## Github  : @adi1090x
#
## Applets : Screenshot

# if rofi is open close it
if pidof rofi >/dev/null; then
  pkill rofi
  exit
fi

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Theme Elements
prompt='Screenshot'
mesg="DIR: $(xdg-user-dir PICTURES)/Screenshots"

if [[ "$theme" == *'type-1'* ]]; then
  list_col='1'
  list_row='5'
  win_width='400px'
elif [[ "$theme" == *'type-3'* ]]; then
  list_col='1'
  list_row='5'
  win_width='120px'
elif [[ "$theme" == *'type-5'* ]]; then
  list_col='1'
  list_row='5'
  win_width='520px'
elif [[ ("$theme" == *'type-2'*) || ("$theme" == *'type-4'*) ]]; then
  list_col='5'
  list_row='1'
  win_width='670px'
fi

# Options
layout=$(cat ${theme} | grep 'USE_ICON' | cut -d'=' -f2)
if [[ "$layout" == 'NO' ]]; then
  option_1=" Capture Desktop"
  option_2=" Capture Area"
  option_3=" Capture Window"
  option_4=" Capture in 5s"
  option_5=" Capture in 10s"
else
  option_1=""
  option_2=""
  option_3=""
  option_4=""
  option_5=""
fi

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme ${theme}
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd
}

# Screenshot
time=$(date +%Y-%m-%d-%H-%M-%S)
geometry=$(xrandr | grep 'current' | head -n1 | cut -d',' -f2 | tr -d '[:blank:],current')
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}_${geometry}.png"

active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
active_window_file="Screenshot_${time}_${active_window_class}.png"
active_window_path="${dir}/${active_window_file}"

notify_cmd_base="notify-send -t 10000 -A action1=Open -A action2=Delete -h string:x-canonical-private-synchronous:shot-notify"
notify_cmd_shot="${notify_cmd_base} -i ${iDIR}/picture.png "
notify_cmd_shot_win="${notify_cmd_base} -i ${iDIR}/picture.png "
notify_cmd_NOT="notify-send -u low -i ${iDoR}/note.png "

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

# notify and view screenshot
notify_view() {
  if [[ "$1" == "active" ]]; then
    if [[ -e "${active_window_path}" ]]; then
      "${sDIR}/Sounds.sh" --screenshot
      resp=$(timeout 5 ${notify_cmd_shot_win} " Screenshot of:" " ${active_window_class} Saved.")
      case "$resp" in
      action1)
        xdg-open "${active_window_path}" &
        ;;
      action2)
        rm "${active_window_path}" &
        ;;
      esac
    else
      ${notify_cmd_NOT} " Screenshot of:" " ${active_window_class} NOT Saved."
      "${sDIR}/Sounds.sh" --error
    fi

  elif [[ "$1" == "swappy" ]]; then
    "${sDIR}/Sounds.sh" --screenshot
    resp=$(${notify_cmd_shot} " Screenshot:" " Captured by Swappy")
    case "$resp" in
    action1)
      swappy -f - <"$tmpfile"
      ;;
    action2)
      rm "$tmpfile"
      ;;
    esac

  else
    local check_file="${dir}/${file}"
    if [[ -e "$check_file" ]]; then
      "${sDIR}/Sounds.sh" --screenshot
      resp=$(timeout 5 ${notify_cmd_shot} " Screenshot" " Saved")
      case "$resp" in
      action1)
        xdg-open "${check_file}" &
        ;;
      action2)
        rm "${check_file}" &
        ;;
      esac
    else
      ${notify_cmd_NOT} " Screenshot" " NOT Saved"
      "${sDIR}/Sounds.sh" --error
    fi
  fi
}

# Copy screenshot to clipboard
copy_shot() {
  tee "$file" | xclip -selection clipboard -t image/png
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 -i "$iDIR"/timer.png " Taking shot" " in: $sec secs"
    sleep 1
  done
}

# take shots
shotnow() {
  cd ${dir} && grim - | tee "$file" | wl-copy
  sleep 2
  notify_view
}

shot5() {
  countdown '5'
  sleep 1 && cd ${dir} && maim -u -f png | copy_shot
  notify_view
}

shot10() {
  countdown '10'
  sleep 1 && cd ${dir} && maim -u -f png | copy_shot
  notify_view
}

shotarea() {
  tmpfile=$(mktemp)
  grim -g "$(slurp)" - >"$tmpfile"

  # Copy with saving
  if [[ -s "$tmpfile" ]]; then
    wl-copy <"$tmpfile"
    mv "$tmpfile" "$dir/$file"
  fi
  notify_view
}

shotwin() {
  # get rofi out of the way
  pkill rofi && sleep 0.5
  w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
  w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)
  cd ${dir} && grim -g "$w_pos $w_size" - | tee "$file" | wl-copy
  notify_view
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    shotnow
  elif [[ "$1" == '--opt2' ]]; then
    shotarea
  elif [[ "$1" == '--opt3' ]]; then
    shotwin
  elif [[ "$1" == '--opt4' ]]; then
    shot5
  elif [[ "$1" == '--opt5' ]]; then
    shot10
  fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
$option_1)
  run_cmd --opt1
  ;;
$option_2)
  run_cmd --opt2
  ;;
$option_3)
  run_cmd --opt3
  ;;
$option_4)
  run_cmd --opt4
  ;;
$option_5)
  run_cmd --opt5
  ;;
esac
