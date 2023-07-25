#!/usr/bin/env bash

CONFIG="$HOME/.config/dunst/config"

if [[ ! $(pidof dunst) ]]; then
	mako --config ${CONFIG}
fi
