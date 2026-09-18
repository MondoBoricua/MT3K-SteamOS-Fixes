# MT3K SteamOS Fixes

Scripts y recetas de **MT3K** para hacer funcionar juegos en **Steam Machine, Steam Deck y SteamOS** (Proton) cuando "se cierran solos", no arrancan o necesitan algo que Proton no trae. Cada fix va en su carpeta con su script y un README que explica el síntoma, la causa real y cómo se encontró.

## Fixes

| Juego | Problema | Fix |
|---|---|---|
| [X-Men Origins: Wolverine](fixes/x-men-origins-wolverine/) | Se cierra al abrir bajo Proton: le falta PhysX 2.8.1 (el instalador "Legacy" que trae el juego no la incluye) | Instala el PhysX System Software de NVIDIA en el prefijo del juego, automático |

## Cómo usar un fix

1. Añade el juego a Steam como juego no-Steam, ponle **GE-Proton** en *Propiedades > Compatibilidad* y ábrelo una vez (aunque se cierre: así Steam crea el prefijo).
2. En Modo Escritorio, abre Konsole y sigue el README del fix. Casi siempre es descargar el script con `curl`, darle permiso y ejecutarlo:
   ```bash
   curl -fLO https://raw.githubusercontent.com/MondoBoricua/MT3K-SteamOS-Fixes/main/fixes/<juego>/<script>.sh
   chmod +x <script>.sh
   ./<script>.sh
   ```
3. Vuelve a Modo Juego y abre el juego.

Los scripts no piden `sudo`, no tocan Steam ni los archivos del juego, y solo escriben dentro del prefijo de Proton del juego (`steamapps/compatdata/<appid>/`). Si algo descargan, verifican el hash.

## Requisitos generales

- **GE-Proton** (instálalo con ProtonUp-Qt desde Discover, o con ProtonPlus). Los Proton de Valve no pueden ejecutar instaladores desde fuera de Steam, por eso los scripts usan GE.
- Konsole en Modo Escritorio.

## Método: cómo se encuentran estos fixes

Cuando un juego "se cierra solo" con cualquier Proton, cambiar de Proton, DXVK o DLLs a ciegas casi nunca lo arregla: si el crash sale siempre en la misma dirección, la causa es la misma. Lo que funciona es trazar las llamadas del ejecutable a Windows (`WINEDEBUG=+relay,+seh`) y mirar qué le devolvió NULL justo antes de morir: una DLL que no existe, una clave de registro que falta, un archivo que espera. Ese es el fix.

## Contribuir

Abre un issue con el juego, el síntoma exacto y, si puedes, el backtrace de Proton. Los PR con un fix nuevo deben traer carpeta propia en `fixes/`, script probado en SteamOS y README con causa y verificación.

---
MT3K · Licencia MIT.
