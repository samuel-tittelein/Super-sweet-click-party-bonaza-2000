#!/bin/bash
GAME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
flatpak run --filesystem="$GAME_DIR" --socket=pulseaudio --device=all org.love2d.love2d "$GAME_DIR"
