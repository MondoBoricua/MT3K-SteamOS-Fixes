#!/usr/bin/env bash
# =============================================================================
#  MT3K — Deadpool (PC, 2013) en Steam Deck / Steam Machine / SteamOS
#  Cambia el idioma del juego (y opcionalmente la resolucion) bajo Proton.
#  https://github.com/MondoBoricua/MT3K-SteamOS-Fixes
# -----------------------------------------------------------------------------
#  POR QUE: Deadpool no elige el idioma por Steam, ni por parametro, ni por el
#  idioma del sistema: lo lee del registro de Windows,
#    HKLM\SOFTWARE\WOW6432Node\Activision\deadpool  ->  language = ESN|INT|FRA|DEU|ITA
#  que normalmente escribe el instalador. Si copiaste el juego o lo añadiste a
#  Steam a mano, esa clave no existe dentro del prefijo de Proton y sale en ingles.
#
#  USO (Modo Escritorio, Konsole, con el juego CERRADO):
#    ./mt3k-deadpool-language.sh                      # espanol (ESN), todo automatico
#    ./mt3k-deadpool-language.sh --lang INT           # volver a ingles
#    ./mt3k-deadpool-language.sh --res 1920x1080      # y de paso fijar la resolucion
#    ./mt3k-deadpool-language.sh --appid 1234567890   # si no encuentra el prefijo solo
# =============================================================================
set -euo pipefail

LANG_CODE="ESN"; RES=""; APPID=""; GAME_DIR=""
say()  { printf '\033[1;36m[MT3K]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  OK \033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !! \033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --lang)  LANG_CODE="$(echo "$2" | tr '[:lower:]' '[:upper:]')"; shift 2 ;;
    --res)   RES="$2"; shift 2 ;;
    --appid) APPID="$2"; shift 2 ;;
    --game)  GAME_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) die "opcion desconocida: $1 (usa --help)" ;;
  esac
done
case "$LANG_CODE" in INT|ESN|FRA|DEU|ITA) ;; *) die "idioma no valido: $LANG_CODE (usa INT, ESN, FRA, DEU o ITA)" ;; esac
if [ -n "$RES" ] && ! [[ "$RES" =~ ^[0-9]{3,4}x[0-9]{3,4}$ ]]; then die "resolucion no valida: $RES (ejemplo: 1920x1080)"; fi

# --- Steam --------------------------------------------------------------------
STEAM=""
for c in "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root"; do
  [ -d "$c/steamapps" ] && STEAM="$(readlink -f "$c")" && break
done
[ -n "$STEAM" ] || die "no encuentro la carpeta de Steam"

if pgrep -f '[D]P\.exe' >/dev/null; then die "Deadpool esta abierto. Cierralo y vuelve a correr esto (al salir reescribe su configuracion)."; fi

# --- prefijo del juego (el juego crea HKCU\Software\Activision\DeadPool al abrirse) ---
if [ -z "$APPID" ]; then
  say "Buscando el prefijo de Proton de Deadpool..."
  mapfile -t found < <(grep -l -a -i 'Software\\\\Activision\\\\DeadPool\]' "$STEAM"/steamapps/compatdata/*/pfx/user.reg 2>/dev/null \
                        | sed -E 's#.*/compatdata/([0-9]+)/.*#\1#')
  case "${#found[@]}" in
    0) die "no encuentro el prefijo. Abre Deadpool una vez desde Steam (con Proton), cierralo y repite; o usa --appid <numero>." ;;
    1) APPID="${found[0]}" ;;
    *) die "hay varios prefijos con Deadpool (${found[*]}). Elige uno con --appid <numero>." ;;
  esac
fi
PFX="$STEAM/steamapps/compatdata/$APPID/pfx"
[ -d "$PFX/drive_c" ] || die "no existe el prefijo $PFX"
say "Prefijo: compatdata/$APPID"

# --- wine: el de GE-Proton / CachyOS (los Proton de Valve no sirven fuera de Steam) ---
mapfile -d '' -t CAND < <(find "$STEAM/compatibilitytools.d" "$HOME/.steam/root/compatibilitytools.d" -mindepth 1 -maxdepth 1 -type d \
    \( -iname 'GE-Proton*' -o -iname 'Proton-GE*' -o -iname 'Proton-CachyOS*' \) -print0 2>/dev/null | sort -zVr)
WINE=""; WINESERVER=""
for d in "${CAND[@]}"; do [ -x "$d/files/bin/wine" ] && { WINE="$d/files/bin/wine"; WINESERVER="$d/files/bin/wineserver"; break; }; done
[ -n "$WINE" ] || die "no hay GE-Proton instalado. Instalalo con ProtonUp-Qt (Discover) o ProtonPlus y repite."
export WINEPREFIX="$PFX" WINEDEBUG=-all

# --- comprobar que el juego tiene los textos de ese idioma ------------------------
if [ -z "$GAME_DIR" ]; then
  GAME_DIR="$(find "$HOME/Games" "$STEAM/steamapps/common" /run/media -maxdepth 5 -type f -iname 'DP.exe' -path '*Binaries*' 2>/dev/null | head -1 | xargs -r -d '\n' dirname | xargs -r -d '\n' dirname || true)"
fi
if [ -n "$GAME_DIR" ]; then
  LOC="$GAME_DIR/TransGame/Localization/Cooked/PC"
  if [ "$LANG_CODE" != "INT" ] && ! ls "$LOC" 2>/dev/null | grep -qi "^Coalesced\.$LANG_CODE$"; then
    warn "tu copia no trae los textos de $LANG_CODE ($LOC/Coalesced.$LANG_CODE)."
    warn "Sin ese archivo el juego seguira en ingles. Copialo de una instalacion con ese idioma y repite."
  else
    ok "juego: $GAME_DIR"
  fi
else
  warn "no encontre la carpeta del juego para comprobar los textos (sigo igual; usa --game para indicarla)."
fi

# --- idioma -------------------------------------------------------------------------
say "Poniendo el idioma en $LANG_CODE..."
"$WINE" reg add 'HKLM\SOFTWARE\Wow6432Node\Activision\deadpool' /v language /t REG_SZ /d "$LANG_CODE" /f /reg:32 >/dev/null 2>&1 || true

# --- resolucion (opcional) ---------------------------------------------------------------
if [ -n "$RES" ]; then
  W="${RES%x*}"; H="${RES#*x}"
  "$WINE" reg add 'HKCU\Software\Activision\DeadPool' /v ScreenResolution /t REG_SZ /d "Width:$W Height:$H Fullscreen:1" /f >/dev/null 2>&1 || true
fi
"$WINESERVER" -w 2>/dev/null || true

# --- verificar -----------------------------------------------------------------------------
GOT="$("$WINE" reg query 'HKLM\SOFTWARE\Wow6432Node\Activision\deadpool' /v language /reg:32 2>/dev/null | grep -aoE 'REG_SZ\s+\S+' | awk '{print $2}' || true)"
"$WINESERVER" -w 2>/dev/null || true
[ "$GOT" = "$LANG_CODE" ] && ok "idioma: language = $GOT" || die "no se pudo escribir la clave de idioma (leido: '${GOT:-nada}')"
if [ -n "$RES" ]; then
  GOTR="$("$WINE" reg query 'HKCU\Software\Activision\DeadPool' /v ScreenResolution 2>/dev/null | grep -ao 'Width:[0-9]* Height:[0-9]*' || true)"
  "$WINESERVER" -w 2>/dev/null || true
  [ -n "$GOTR" ] && ok "resolucion: $GOTR" || warn "no se pudo leer la resolucion"
fi

echo
say "Listo. Vuelve a Modo Juego y abre Deadpool."
[ "$LANG_CODE" = "ESN" ] && say "Nota: la version de PC de Steam trae el espanol como textos y subtitulos; las voces son en ingles."
