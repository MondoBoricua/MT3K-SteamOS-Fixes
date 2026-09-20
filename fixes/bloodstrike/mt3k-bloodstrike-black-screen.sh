#!/usr/bin/env bash
# BLOODSTRIKE en SteamOS: pantalla negra al salir del launcher.
#
# Causa: launcher.exe no cierra sus ventanas al arrancar el juego, y ADEMAS las
# vuelve a mostrar cada cierto tiempo. Quedan mapeadas en el XWayland de
# gamescope, que muestra una de ellas (ya en blanco) a pantalla completa en vez
# de la ventana del juego.
#
# Probado y descartado:
#   - Lanzar BloodStrike.exe directo: el juego se cierra solo, necesita al launcher.
#   - Desmapear las ventanas (xdotool windowunmap): se ve el juego, pero Wine las
#     mantiene en primer plano -> sin audio y sin mando.
#   - Minimizarlas una sola vez: funciona (audio y mando OK) hasta que el launcher
#     las vuelve a mostrar y la pantalla se pone negra otra vez.
#
# Arreglo: minimizarlas de forma continua mientras el juego este abierto.
#
# Uso en Steam -> Propiedades -> Opciones de lanzamiento:
#   ~/Applications/bloodstrike-fix.sh %command%
set -u
LOG=~/.local/share/bloodstrike-fix.log
DISPLAY_X=${DISPLAY:-:1}
INTERVALO=${BS_INTERVALO:-2}

watcher() {
  export DISPLAY="$DISPLAY_X"
  local juego="" vistas=0 ciclos=0
  # esperar a la ventana del juego (hasta 15 min)
  local fin=$(( SECONDS + 900 ))
  while [ $SECONDS -lt $fin ]; do
    juego=$(xwininfo -root -tree 2>/dev/null | awk '/"BloodStrike":/ {print $1; exit}')
    [ -n "$juego" ] && break
    sleep "$INTERVALO"
  done
  if [ -z "$juego" ]; then echo "$(date +%T) timeout: no aparecio la ventana del juego" >> "$LOG"; return; fi
  echo "$(date +%T) ventana del juego: $juego — vigilando" >> "$LOG"

  # vigilar mientras el juego siga vivo
  while pgrep -f "BloodStrike.exe" >/dev/null 2>&1; do
    local minimizada=0
    while read -r id w; do
      [ "$id" = "$juego" ] && continue
      [ -z "${w:-}" ] && continue
      [ "$w" -ge 1200 ] && continue   # la del juego es mas ancha
      [ "$w" -lt 300 ] && continue    # IME / input / ventanas de 1x1
      if xwininfo -id "$id" 2>/dev/null | grep -q "IsViewable"; then
        xdotool windowminimize "$id" 2>/dev/null && { minimizada=1; vistas=$((vistas+1)); }
      fi
    done < <(xwininfo -root -tree 2>/dev/null | awk '/steam_app_3199170/ {
               for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+x[0-9]+\+/) { split($i,a,"x"); print $1, a[1]; break } }')
    if [ "$minimizada" = 1 ]; then
      xdotool windowactivate "$juego" 2>/dev/null
      xdotool windowfocus --sync "$juego" 2>/dev/null
      echo "$(date +%T) launcher minimizado y foco devuelto al juego (total: $vistas)" >> "$LOG"
    fi
    ciclos=$((ciclos+1))
    sleep "$INTERVALO"
  done
  echo "$(date +%T) juego cerrado; el launcher se mostro $vistas veces en $ciclos ciclos" >> "$LOG"
}

echo "=== $(date) lanzando" >> "$LOG"
watcher &
exec "$@"
