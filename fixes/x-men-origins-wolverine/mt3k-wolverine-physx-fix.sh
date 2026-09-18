#!/usr/bin/env bash
# =============================================================================
#  MT3K — X-Men Origins: Wolverine (PC) en Steam Deck / Steam Machine / SteamOS
#  Arregla el "se cierra solo al abrir" bajo Proton instalando PhysX 2.8.1
#  dentro del prefijo del juego.  https://github.com/MondoBoricua/MT3K-SteamOS-Fixes
# -----------------------------------------------------------------------------
#  POR QUE: el juego usa PhysX SDK 2.8.1. Su cargador (PhysXLoader.dll) busca
#  Engine\v2.8.1\PhysXCore.dll y, si no existe, el motor muere sin mensaje.
#  El instalador "Legacy" que trae el juego en _Redist NO incluye esa version;
#  la trae el PhysX System Software 9.13.0725 de NVIDIA, que este script
#  descarga e instala en el prefijo con el Proton que use el juego.
#
#  USO (en Modo Escritorio, Konsole):
#    chmod +x mt3k-wolverine-physx-fix.sh
#    ./mt3k-wolverine-physx-fix.sh                # todo automatico
#    ./mt3k-wolverine-physx-fix.sh --appid 123456 # si tienes varios prefijos
#    ./mt3k-wolverine-physx-fix.sh --lang esn     # y de paso ponerlo en espanol
#
#  ANTES: anade Wolverine.exe a Steam como juego no-Steam, ponle un Proton en
#  Propiedades > Compatibilidad (GE-Proton o Experimental) y ABRELO UNA VEZ
#  (se cerrara: es normal, asi Steam crea el prefijo que vamos a arreglar).
# =============================================================================
set -euo pipefail

PHYSX_URL="https://us.download.nvidia.com/Windows/9.13.0725/PhysX-9.13.0725-SystemSoftware.msi"
PHYSX_SHA256="6f20edf8f0030d5e0f30b3b2dec3dea8d978b8de92e39b05558f64fe18aa0fe1"
APPID=""; GAME_DIR=""; LANG_CODE=""; MSI_LOCAL=""

say()  { printf '\033[1;36m[MT3K]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  OK \033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --appid) APPID="$2"; shift 2 ;;
    --game)  GAME_DIR="$2"; shift 2 ;;
    --lang)  LANG_CODE="$2"; shift 2 ;;
    --msi)   MSI_LOCAL="$2"; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) die "opcion desconocida: $1 (usa --help)" ;;
  esac
done

# --- Steam ------------------------------------------------------------------
STEAM=""
for c in "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root"; do
  [ -d "$c/steamapps" ] && STEAM="$(readlink -f "$c")" && break
done
[ -n "$STEAM" ] || die "no encuentro la carpeta de Steam"
say "Steam: $STEAM"

# --- prefijo del juego --------------------------------------------------------
if [ -z "$APPID" ]; then
  say "Buscando el prefijo de Wolverine (Documents/Wolverine dentro de compatdata)..."
  mapfile -t found < <(ls -d "$STEAM"/steamapps/compatdata/*/pfx/drive_c/users/steamuser/Documents/Wolverine 2>/dev/null \
                        | sed -E 's#.*/compatdata/([0-9]+)/.*#\1#')
  case "${#found[@]}" in
    0) die "no hay ningun prefijo con Documents/Wolverine. Anade el juego a Steam, ponle Proton y abrelo UNA vez; luego vuelve a correr esto (o usa --appid)." ;;
    1) APPID="${found[0]}" ;;
    *) die "hay varios prefijos posibles (${found[*]}). Dime cual con --appid <numero>." ;;
  esac
fi
PREFIX="$STEAM/steamapps/compatdata/$APPID"
mkdir -p "$PREFIX"   # Proton necesita que exista para crear pfx.lock
say "AppID: $APPID  ->  $PREFIX"

# --- Proton -------------------------------------------------------------------
# El instalador de PhysX solo funciona desde terminal con GE-Proton (o CachyOS):
# los Proton de Valve (Experimental, 10, 11...) no pueden crear/usar el prefijo
# fuera de Steam. Se usa el GE asignado al juego si lo tiene; si no, el GE mas
# nuevo instalado, y se avisa para que el juego quede con ese mismo GE en Steam.
TOOL="$(grep -A3 "\"$APPID\"" "$STEAM/config/config.vdf" 2>/dev/null | grep -oE '"name"\s+"[^"]+"' | head -1 | sed -E 's/"name"\s+"//; s/"$//' || true)"
PROTON_DIR=""
for d in "$STEAM/compatibilitytools.d/$TOOL" "$HOME/.steam/root/compatibilitytools.d/$TOOL"; do
  [ -n "$TOOL" ] && [ -x "$d/proton" ] && { PROTON_DIR="$d"; break; }
done
if [ -z "$PROTON_DIR" ]; then
  mapfile -d '' -t CANDIDATES < <(find "$STEAM/compatibilitytools.d" "$HOME/.steam/root/compatibilitytools.d" -mindepth 1 -maxdepth 1 -type d \
      \( -iname 'GE-Proton*' -o -iname 'Proton-GE*' -o -iname 'Proton-CachyOS*' \) -print0 2>/dev/null | sort -zVr)
  for d in "${CANDIDATES[@]}"; do
    [ -x "$d/proton" ] && { PROTON_DIR="$d"; break; }
  done
  [ -n "$PROTON_DIR" ] || die "no hay GE-Proton instalado. Instalalo con ProtonUp-Qt (Discover) o ProtonPlus, asignaselo al juego en Steam y repite."
  say "AVISO: el juego tiene asignado '${TOOL:-nada}' en Steam; PhysX se instala con $(basename "$PROTON_DIR"). Pon ese mismo Proton al juego en Propiedades > Compatibilidad."
fi
say "Proton: $(basename "$PROTON_DIR")${TOOL:+ (asignado en Steam: $TOOL)}"

# --- PhysX System Software 9.13.0725 -------------------------------------------
MSI="${MSI_LOCAL:-$HOME/Downloads/PhysX-9.13.0725-SystemSoftware.msi}"
if [ ! -s "$MSI" ]; then
  say "Descargando PhysX System Software 9.13.0725 de NVIDIA (28 MB)..."
  mkdir -p "$(dirname "$MSI")"
  curl -fL --progress-bar -o "$MSI" "$PHYSX_URL" || die "fallo la descarga"
fi
if command -v sha256sum >/dev/null && [ -n "$PHYSX_SHA256" ]; then
  echo "$PHYSX_SHA256  $MSI" | sha256sum -c --quiet || die "el MSI descargado no coincide con el hash esperado; borra $MSI y reintenta"
  ok "hash del MSI verificado"
fi

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM"
export STEAM_COMPAT_DATA_PATH="$PREFIX"
WINE="$PROTON_DIR/files/bin/wine"; WINESERVER="$PROTON_DIR/files/bin/wineserver"
[ -x "$WINE" ] || die "no encuentro wine dentro de $PROTON_DIR"
if [ ! -d "$PREFIX/pfx/drive_c" ]; then
  say "El prefijo aun no existe: lo creo con $(basename "$PROTON_DIR")..."
  timeout 300 "$PROTON_DIR/proton" run cmd /c exit >/dev/null 2>&1 || true
  [ -d "$PREFIX/pfx/drive_c" ] || die "no se pudo crear el prefijo. Abre el juego una vez desde Steam y repite."
fi
WINPATH="Z:$(echo "$MSI" | sed 's#/#\\#g')"
LOG="$HOME/mt3k-physx-install.log"
say "Instalando PhysX en el prefijo con el wine de $(basename "$PROTON_DIR") (1-2 min, sin ventanas)..."
# msiexec devuelve enseguida y la instalacion sigue en el servicio de Wine: esperar con wineserver -w
WINEPREFIX="$PREFIX/pfx" WINEDEBUG=-all timeout 600 "$WINE" msiexec /i "$WINPATH" /qn >"$LOG" 2>&1 || true
WINEPREFIX="$PREFIX/pfx" timeout 600 "$WINESERVER" -w 2>/dev/null || true

NV="$PREFIX/pfx/drive_c/Program Files (x86)/NVIDIA Corporation/PhysX"
if [ -f "$NV/Engine/v2.8.1/PhysXCore.dll" ]; then
  ok "PhysX 2.8.1 instalado: $NV/Engine/v2.8.1/PhysXCore.dll"
  ok "versiones disponibles: $(ls "$NV/Engine" | grep '^v2' | sort -V | tr '\n' ' ')"
else
  die "PhysXCore.dll v2.8.1 no aparecio en el prefijo. Log: $LOG. Prueba asignando GE-Proton al juego en Steam (Propiedades > Compatibilidad), abrelo una vez y repite."
fi

# --- idioma (opcional) -----------------------------------------------------------
if [ -n "$LANG_CODE" ]; then
  INI="$PREFIX/pfx/drive_c/users/steamuser/Documents/Wolverine/WGame/Config/WEngine.ini"
  if [ -f "$INI" ]; then
    sed -i "s/^Language=.*/Language=$LANG_CODE/" "$INI" && ok "idioma: Language=$LANG_CODE (int, esn, fra, ita)"
  else
    say "aun no existe WEngine.ini (se crea al primer arranque); vuelve a pasar --lang despues."
  fi
fi

echo
say "Listo. Cierra esto, vuelve a Modo Juego y abre X-Men Origins: Wolverine desde Steam."
say "Si sigue cerrandose: abre Propiedades > Compatibilidad y confirma que usa $(basename "$PROTON_DIR")."
