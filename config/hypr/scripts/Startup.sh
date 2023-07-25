#!/bin/bash

SCRIPTSDIR=$HOME/.config/hypr/scripts

# Kill already running process
_ps=(waybar dunst)
for _prs in "${_ps[@]}"; do
	if [[ $(pidof ${_prs}) ]]; then
		killall -9 ${_prs}
	fi
done

# Iniciar demonio de notificación (mako).
${SCRIPTSDIR}/Dunst.sh &

# Iniciar barra de estado (waybar).
${SCRIPTSDIR}/Waybar.sh &
