# X-Men Origins: Wolverine en Steam Deck / Steam Machine — fix del "se cierra solo"

Script de **MT3K** que arregla el arranque de *X-Men Origins: Wolverine* (PC, 2009) bajo Proton.

## El problema

Añades el juego a Steam, le pones Proton, lo abres... y se cierra a los dos segundos sin ningún mensaje. Con cualquier Proton, con DXVK o sin él, en modo Windows 7 o 10. Siempre igual.

## La causa (de verdad)

El juego usa **PhysX SDK 2.8.1**. Su cargador (`PhysXLoader.dll`) busca `Engine\v2.8.1\PhysXCore.dll` en la instalación de PhysX del sistema. Si no está, recibe un puntero nulo y el motor Unreal muere en su rutina de error fatal antes de abrir ventana.

La trampa: el instalador de PhysX que trae el juego en `_Redist` es el paquete **"Legacy"** (versiones 2.3 a 2.7.2) y **no incluye la 2.8.1**. En Windows funciona porque el driver de NVIDIA u otros juegos ya te instalaron el PhysX System Software normal, que sí la trae. En un prefijo de Proton recién creado no hay nada.

## Lo que hace el script

1. Localiza tu Steam y el prefijo del juego (busca `Documents/Wolverine` dentro de `compatdata`, que el juego crea en su primer intento de arranque).
2. Usa el GE-Proton asignado al juego (o el más nuevo que tengas instalado).
3. Descarga el **PhysX System Software 9.13.0725** directamente de NVIDIA (28 MB) y comprueba su SHA-256.
4. Lo instala en el prefijo con `msiexec`, en silencio.
5. Verifica que `Engine\v2.8.1\PhysXCore.dll` quedó en su sitio.
6. Opcionalmente cambia el idioma del juego.

No toca el juego, no toca Steam, no necesita `sudo` ni internet más allá de la descarga de NVIDIA.

## Requisitos

- Steam Deck, Steam Machine o cualquier SteamOS / Linux con Steam.
- **GE-Proton** instalado (ProtonUp-Qt desde Discover, o ProtonPlus). Los Proton de Valve (Experimental, 10, 11) no pueden ejecutar instaladores desde fuera de Steam, así que el script necesita GE.
- El juego añadido a Steam como **juego no-Steam** apuntando a `Binaries\Wolverine.exe`, con GE-Proton en *Propiedades > Compatibilidad*, y **abierto una vez** (se cerrará: es normal, así Steam crea el prefijo).

## Uso

En Modo Escritorio, abre Konsole y pega esto (descarga el script, le da permiso y lo ejecuta):

```bash
curl -fLO https://raw.githubusercontent.com/MondoBoricua/MT3K-SteamOS-Fixes/main/fixes/x-men-origins-wolverine/mt3k-wolverine-physx-fix.sh
chmod +x mt3k-wolverine-physx-fix.sh
./mt3k-wolverine-physx-fix.sh
```

Si prefieres verlo antes de correrlo, ábrelo con `cat mt3k-wolverine-physx-fix.sh`: son 150 líneas comentadas.

Opciones:

| Opción | Para qué |
|---|---|
| `--appid 1234567890` | Si tienes varios prefijos con Wolverine o el script no lo encuentra solo. El AppID de un juego no-Steam se ve en la URL de su página en Steam o en `steamapps/compatdata/`. |
| `--lang esn` | Poner el juego en español (`int` inglés, `esn` español, `fra` francés, `ita` italiano; lo que traiga tu copia). |
| `--msi /ruta/al.msi` | Usar un `PhysX-9.13.0725-SystemSoftware.msi` que ya tengas descargado. |

Al terminar, vuelve a Modo Juego y abre Wolverine desde Steam.

## Si algo falla

- **"no hay ningún prefijo con Documents/Wolverine"**: no has abierto el juego desde Steam todavía, o lo abriste con otro Proton. Ábrelo una vez y repite.
- **"no hay GE-Proton instalado"**: instala GE-Proton con ProtonUp-Qt y asígnaselo al juego.
- **Sigue cerrándose**: asegúrate de que el juego usa en Steam el **mismo** GE-Proton que muestra el script. El log del instalador queda en `~/mt3k-physx-install.log`.
- **Menús invisibles o texturas raras**: eso ya es otro problema conocido de este juego en Wine; el script solo arregla el arranque.

## Cómo se encontró

Trazando las llamadas a la API de Windows del ejecutable con `WINEDEBUG=+relay,+seh`: la última llamada antes del crash era `LoadLibraryA("...\PhysX\Engine\v2.8.1\PhysXCore.dll")` devolviendo `STATUS_DLL_NOT_FOUND`. El mismo método sirve para cualquier juego viejo que "se cierre solo" bajo Proton: antes de cambiar Protons y DLLs a ciegas, mira qué le devolvió NULL.

---
MT3K · Compártelo libremente, pero deja el crédito.
