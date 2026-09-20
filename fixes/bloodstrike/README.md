# BLOODSTRIKE en Steam Deck / Steam Machine — pantalla negra al salir del launcher

Script de **MT3K** para cuando *BLOODSTRIKE* (Steam, appid 3199170) se queda en **pantalla negra** después de que su launcher llega a "Loading the game... 95%".

## El problema

El launcher abre, llega al 95% y arranca el juego. A partir de ahí la pantalla se queda negra. El juego **no se ha colgado**: sigue gastando CPU y GPU, y el audio sale a nivel de sistema (`pactl list sink-inputs` muestra `BloodStrike.exe` sin pausar y al 100%).

No es ninguna de las causas típicas, todas descartadas midiendo:

- **No es el HDR.** El juego crea su superficie en SDR (`VK_FORMAT_R8G8B8A8_UNORM`, sRGB). Apagándolo en caliente (`gamescopectl hdr_enabled 0`) sigue negro.
- **No es la GPU.** El kernel no registra ni un fallo de amdgpu.
- **No es la versión de Proton.** Igual con Proton estable y con Experimental.
- **No es el anticheat.** En el log sale `ZwLoadDriver ... Services\NEProtect: c0000142` (su driver de kernel no carga bajo Wine), pero el juego arranca y llega a su menú igualmente.

## La causa

El launcher **no cierra sus ventanas** al arrancar el juego, y además **las vuelve a mostrar cada pocos segundos**. Se quedan mapeadas en el XWayland de gamescope, que escoge una de ellas (ya en blanco) y la escala a pantalla completa en lugar de la ventana del juego.

Se ve así:

```bash
DISPLAY=:1 xwininfo -root -tree | grep steam_app_3199170
```

Salen la ventana del juego (`"BloodStrike"`, del tamaño de render) y dos del launcher (unas 750x530 y 720x500), las tres en `IsViewable`.

## Lo que se probó antes de dar con el arreglo

| Intento | Resultado |
|---|---|
| Lanzar `BloodStrike.exe` directo, saltándose el launcher (el launcher lo arranca **sin argumentos**) | El juego se cierra solo: necesita al launcher |
| Ocultar las ventanas del launcher (`xdotool windowunmap`) | Se ve el juego, pero Wine las mantiene en primer plano: **sin audio y sin mando** |
| Minimizarlas una sola vez | Funciona (imagen, audio y mando), hasta que el launcher las vuelve a mostrar y todo se pone negro otra vez |

## Lo que hace el script

Es un envoltorio para las opciones de lanzamiento. Arranca el juego normal y, en paralelo, mientras el juego esté abierto:

1. Espera a que exista la ventana `BloodStrike`.
2. Cada 2 segundos **minimiza** (`xdotool windowminimize`) las ventanas del launcher que vuelvan a estar visibles. Minimizar, y no ocultar, es la clave: Wine procesa la iconificación y le pasa el primer plano al juego, así que vuelven el audio y el mando.
3. Le devuelve el foco a la ventana del juego.

Se limita a ventanas de entre 300 y 1200 px de ancho, para no tocar las de entrada ni las del sistema. No modifica archivos del juego, ni Steam, ni el registro, y no necesita `sudo`.

Deja registro en `~/.local/share/bloodstrike-fix.log`.

## Uso

```bash
mkdir -p ~/Applications
curl -fsSL https://raw.githubusercontent.com/MondoBoricua/MT3K-SteamOS-Fixes/main/fixes/bloodstrike/mt3k-bloodstrike-black-screen.sh -o ~/Applications/mt3k-bloodstrike-black-screen.sh
chmod +x ~/Applications/mt3k-bloodstrike-black-screen.sh
```

Después, en Steam: **BLOODSTRIKE → Propiedades → Opciones de lanzamiento**:

```
~/Applications/mt3k-bloodstrike-black-screen.sh %command%
```

## Antes de nada: acepta el acuerdo

La primera vez, el juego muestra un **acuerdo de usuario** que hay que aceptar. En modo juego ese diálogo puede no recibir foco. Si es tu primera partida en esta máquina, abre el juego una vez desde el **modo escritorio**, acepta el acuerdo, ciérralo, y ya en modo juego usa el script.

## Probado en

- Steam Machine (SteamOS, gamescope 3.16.23.4, AMD, TV 4K a 60 Hz), Proton Experimental y Proton 11.0.

## Aviso

BLOODSTRIKE usa el anticheat de NetEase (NEAC/ACE), que **no está habilitado oficialmente para Linux**. Que funcione no significa que el fabricante lo permita: el riesgo de baneo existe y cada quien decide si lo corre.
