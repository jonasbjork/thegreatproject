#!/usr/bin/env bash
#
# Conway's Game of Life i ren bash
# Användning:
#   ./life.sh [kolumner] [rader] [delay]
# Exempel:
#   ./life.sh 40 20 0.1

# --- Parametrar / standardvärden ---
cols=${1:-30}      # antal kolumner (bredd)
rows=${2:-15}      # antal rader (höjd)
delay=${3:-0.2}    # paus mellan generationer i sekunder

size=$((rows * cols))

# Två spelbräden: nuvarande (board) och nästa (next)
declare -a board
declare -a next

# --- Initiera med slumpmässigt bräde ---
init_random() {
  for ((i = 0; i < size; i++)); do
    board[$i]=$((RANDOM % 2))   # 0 = död, 1 = levande
  done
}

# --- Rita brädet på skärmen ---
draw_board() {
  # Rensa skärmen
  printf "\033[H\033[2J"
  for ((r = 0; r < rows; r++)); do
    line=""
    for ((c = 0; c < cols; c++)); do
      idx=$((r * cols + c))
      if (( board[idx] == 1 )); then
        line+="#"
      else
        line+="."
      fi
    done
    printf "%s\n" "$line"
  done
}

# --- Räkna grannar med wrap runt (torus) ---
count_neighbors() {
  local r=$1
  local c=$2
  local nr nc idx sum=0

  for dr in -1 0 1; do
    for dc in -1 0 1; do
      # hoppa över cellen själv
      if (( dr == 0 && dc == 0 )); then
        continue
      fi

      # wrap runt kanter
      nr=$(( (r + dr + rows) % rows ))
      nc=$(( (c + dc + cols) % cols ))

      idx=$((nr * cols + nc))
      (( sum += board[idx] ))
    done
  done

  printf "%d" "$sum"
}

# --- Beräkna nästa generation ---
step() {
  local r c idx neighbors

  for ((r = 0; r < rows; r++)); do
    for ((c = 0; c < cols; c++)); do
      idx=$((r * cols + c))
      neighbors=$(count_neighbors "$r" "$c")

      if (( board[idx] == 1 )); then
        # Levande cell:
        # - överlever med 2 eller 3 grannar
        # - dör annars
        if (( neighbors == 2 || neighbors == 3 )); then
          next[idx]=1
        else
          next[idx]=0
        fi
      else
        # Död cell:
        # - föds om den har exakt 3 grannar
        if (( neighbors == 3 )); then
          next[idx]=1
        else
          next[idx]=0
        fi
      fi
    done
  done

  # Kopiera next -> board
  for ((i = 0; i < size; i++)); do
    board[$i]=${next[$i]}
  done
}

# --- Huvudprogram ---
init_random

# Dölj markören (ser snyggare ut)
printf "\033[?25l"

# När scriptet avslutas, visa markören igen
cleanup() {
  printf "\033[?25h\n"
  exit 0
}
trap cleanup SIGINT SIGTERM

while true; do
  draw_board
  step
  sleep "$delay"
done
