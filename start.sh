#!/bin/bash
GAME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
flatpak run --filesystem="$GAME_DIR" org.love2d.love2d "$GAME_DIR"
