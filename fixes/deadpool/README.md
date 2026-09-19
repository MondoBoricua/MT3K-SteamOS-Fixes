# Deadpool (2013) en Steam Deck / Steam Machine — ponerlo en español (u otro idioma)

Script de **MT3K** para cambiar el idioma de *Deadpool* (PC, 2013, High Moon Studios) cuando lo juegas en SteamOS con Proton, y de paso fijar la resolución.

## El problema

Copiaste el juego o lo añadiste a Steam como juego no-Steam, y sale siempre en inglés aunque tengas los textos en español. Y no sirve nada de lo habitual:

- El parámetro `-language=esn`: lo ignora.
- El idioma de Steam o del sistema: no los mira.
- Poner el archivo de textos en español en lugar del inglés: los menús salen **vacíos**.

## La causa

Deadpool lee el idioma del **registro de Windows**:

```
HKLM\SOFTWARE\WOW6432Node\Activision\deadpool  ->  language = ESN
```

Esa clave la escribe el instalador original según el idioma que elijas. Si el juego no pasó por ese instalador dentro del prefijo de Proton, la clave no existe y el juego cae al inglés. Se descubrió instalando la versión original en español en otra carpeta y comparando el registro antes y después: es lo único que cambia, aparte del archivo de textos.

## Lo que hace el script

1. Encuentra el prefijo de Proton del juego (el que tiene la configuración de Deadpool en su registro).
2. Escribe `language` en el registro de ese prefijo con el `wine` de GE-Proton.
3. Comprueba que tu copia trae los textos de ese idioma (`TransGame/Localization/Cooked/PC/Coalesced.ESN`) y te avisa si no.
4. Opcional: fija la resolución (`--res`), útil si el juego se ve recortado o en 4:3.

No toca los archivos del juego ni Steam, y no necesita `sudo`.

## Requisitos

- **GE-Proton** instalado (ProtonUp-Qt desde Discover, o ProtonPlus).
- El juego abierto **una vez** desde Steam con Proton (para que exista su prefijo) y **cerrado** al correr el script.
- Los textos del idioma en tu copia: `Coalesced.ESN` (español), `.FRA`, `.DEU` o `.ITA` junto a `Coalesced.int`. Si tu copia solo trae `Coalesced.int`, saca el archivo del idioma de una instalación o instalador que lo tenga.

## Uso

En Modo Escritorio, abre Konsole:

```bash
curl -fLO https://raw.githubusercontent.com/MondoBoricua/MT3K-SteamOS-Fixes/main/fixes/deadpool/mt3k-deadpool-language.sh
chmod +x mt3k-deadpool-language.sh
./mt3k-deadpool-language.sh
```

Opciones:

| Opción | Para qué |
|---|---|
| `--lang ESN` | Idioma: `ESN` español (por defecto), `INT` inglés, `FRA`, `DEU`, `ITA`. |
| `--res 1920x1080` | Fija la resolución (pantalla completa). Útil si se ve recortado. En 4K el juego puede cargar texturas borrosas y los subtítulos salen diminutos; `2560x1440` es buen punto medio. |
| `--appid 1234567890` | Si el script no encuentra el prefijo solo, o hay varios. |
| `--game /ruta/al/juego` | Carpeta del juego (la que contiene `Binaries` y `TransGame`), si no la encuentra. |

Ejemplo: `./mt3k-deadpool-language.sh --lang ESN --res 2560x1440`

## Qué esperar

- **Español**: textos y subtítulos en castellano; las **voces siguen en inglés**. Deadpool nunca tuvo doblaje oficial al español en PC: el paquete de español de Steam (depot 224067) pesa 477 KB y es solo el archivo de textos ([SteamDB](https://steamdb.info/app/224060/depots/)).
- Para volver al inglés: `./mt3k-deadpool-language.sh --lang INT`.

## Extra: tirones a 59 fps

El juego se limita a 59 fps y en una tele de 60 Hz da tirones. En Steam, *Propiedades > Opciones de lanzamiento*: `-silent FPS=60` ([PCGamingWiki](https://www.pcgamingwiki.com/wiki/Deadpool)).

---
MT3K · Licencia MIT.
