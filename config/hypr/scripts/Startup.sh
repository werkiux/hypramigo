#!/bin/bash

SCRIPTSDIR=$HOME/.config/hypr/scripts

# Kill already running process
_ps=(waybar mako)
for _prs in "${_ps[@]}"; do
	if [[ $(pidof ${_prs}) ]]; then
		killall -9 ${_prs}
	fi
done

# Iniciar demonio de notificación (mako).
${SCRIPTSDIR}/Mako.sh &

# Iniciar barra de estado (waybar).
${SCRIPTSDIR}/Waybar.sh &
