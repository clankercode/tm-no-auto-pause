# No Auto-Pause

Openplanet plugin that keeps **Trackmania Turbo** running when the window loses focus.

Without it, alt-tab (or any other window stealing focus) pauses the race, pops the attract / INSERT COIN path, and freezes `rules.Now` — including Openplanet `Update()`. Toggle from **Plugins › No Auto-Pause** or the *Keep running when unfocused* setting. Unload restores the original bytes.

Turbo-only. On other games it loads, warns, and does nothing.

License: **public domain** (Unlicense **or** [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/), at your option).

Authors: [XertroV](https://github.com/XertroV)

Code/issues: https://github.com/clankercode/tm-no-auto-pause

## Install

Needs [Openplanet](https://openplanet.dev) on Trackmania Turbo.

1. Grab the source (or a release `.op` when one exists).
2. Dev copy: `./build.sh dev` stages into `~/OpenplanetTurbo/Plugins/tm-no-auto-pause` and reloads over RemoteBuild `:30002`.
3. Or copy `src/*` plus `info.toml` into `Documents/TrackmaniaTurbo/OpenplanetTurbo/Plugins/tm-no-auto-pause/`.

Reload plugins from the Openplanet menu, or restart the game.

## Log

Transition only (not per frame), Openplanet.log:

```
No Auto-Pause: focus lost paused=no Now=1044941 dNow=+12486
No Auto-Pause: pause started focus=no Now=1032155
```

- **focus** — engine window-has-focus flag (Turbo has no `InputPort.IsFocused`)
- **pause** — cmd-buffer paused, or `rules.Now` stalled ~20 frames in a race
- **dNow** — race-clock delta since the previous focus log

## How it works

Turbo's WndProc writes unfocused flags; WinMain then SleepEx's and `App_NotifyWindowFocus(0)` pauses the app. This plugin patches those sites at load. Details: Openplanet research note `turbo/2026-09-08-Turbo-Unfocus-Pause.md` (sibling `openplanet/research` repo).

## Build

```
./build.sh dev       # stage + RemoteBuild reload (OpenplanetTurbo :30002)
./build.sh release   # tm-no-auto-pause-<version>.op
```

`SKIP_LSP=1` / `SKIP_RELOAD=1` if needed. `TURBO_PLUGINS_DIR` overrides the stage path.
