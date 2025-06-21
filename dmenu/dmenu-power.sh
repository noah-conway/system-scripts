#!/bin/sh
# Simple power menu with dmenu

    
case "$(echo -e "Shutdown\nRestart\nLogout\nSuspend\nQuit" | dmenu \
    -nb "${COLOR_BACKGROUND:-#151515}" \
    -nf "${COLOR_DEFAULT:-#aaaaaa}" \
    -sf "${COLOR_HIGHLIGHT:-#589cc5}" \
    -sb "#1a1a1a" \
    -i -p \
    "Power:" -l 5)" in
        Shutdown) exec systemctl poweroff;;
        Restart) exec systemctl reboot;;
        Logout) exec loginctl terminate-user $(whoami);;
        Suspend) exec systemctl suspend;;
        Lock) exec systemctl --user start lock.target;;
        Quit) exec pkill dwm
esac
