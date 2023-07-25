#!/bin/bash

# Archivos
CONFIG="$HOME/.config/wofi/WofiBig/config"
STYLE="$HOME/.config/wofi/style.css"
COLORS="$HOME/.config/wofi/colors"

WAYBARFILE="$HOME/.config/waybar/config"
WOFIFILE="$HOME/.config/wofi/config"

# Configuración de la ventana wofi (en %)
WIDTH=12
HEIGHT=30

## Comando wofi
wofi_command="wofi --show dmenu \
			--prompt Selecciona...
			--conf $CONFIG --style $STYLE --color $COLORS \
			--width=$WIDTH% --height=$HEIGHT% \
			--cache-file=/dev/null \
			--hide-scroll --no-actions \
			--matching=fuzzy"


menu(){
printf "1. Default\n" 
printf "2. Plasma\n" 
printf "3. Gnome\n"
printf "4. Panel Dual\n"
printf "5. MacOs" 
}

main() {
    choice=$(menu | ${wofi_command} | cut -d. -f1)
    case $choice in
        1)
            ln -sf "$HOME/.config/waybar/configs/config-default" "$WAYBARFILE"
            ln -sf "$HOME/.config/wofi/configs/config-default" "$WOFIFILE"
            ;;
        2)
            ln -sf "$HOME/.config/waybar/configs/config-plasma" "$WAYBARFILE"
            ln -sf "$HOME/.config/wofi/configs/config-plasma" "$WOFIFILE"
            ;;
        3)
            ln -sf "$HOME/.config/waybar/configs/config-gnome" "$WAYBARFILE"
            ln -sf "$HOME/.config/wofi/configs/config-gnome" "$WOFIFILE"
            ;;
        4)
            ln -sf "$HOME/.config/waybar/configs/config-dual" "$WAYBARFILE"
            ln -sf "$HOME/.config/wofi/configs/config-default" "$WOFIFILE"
            ;;
        5)
            ln -sf "$HOME/.config/waybar/configs/config-macOs" "$WAYBARFILE"
            ln -sf "$HOME/.config/wofi/configs/config-default" "$WOFIFILE"
            ;;
    esac
}

# Comprueba si el wifi ya está funcionando.
if pidof wofi >/dev/null; then
    killall wofi
    exit 0
else
    main
fi

# Reinicie Waybar y ejecute otros scripts si se tomó una decisión.
if [[ -n "$choice" ]]; then
    # Reiniciar barra de ruta.
    killall waybar
fi

exec ~/.config/hypr/scripts/Startup.sh &
                