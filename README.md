# GOG Physical Media Batch Builder

Double-click `Launch GOG Media Builder.bat` to open the builder window. Windows often opens `.ps1` files in a text editor by default, so use the `.bat` launcher rather than double-clicking `GogMediaBuilder.ps1`. The builder needs no separate installation.

Choose the folder already holding one game's downloaded GOG files. The builder finds the first `setup*.exe` as the installer and finds an `.ico` file for the disc icon. Then enter the game's title exactly as GOG shows it in its Library or installer (for example, `DOOM + DOOM II`). You do **not** need to know the game's launch EXE or installed-folder name.

- `install.bat` calls `launch-installed-gog-game.ps1`, which checks Windows' installed-program records for the selected GOG title. If found, it reads GOG's own installed-game metadata to discover and start the correct EXE. Otherwise it opens the GOG installer normally, without silent-install options. The batch closes immediately after starting either program.
- `autorun.inf` identifies `install.bat` as the disc action and uses `game.ico` for the disc icon.

Keep `launch-installed-gog-game.ps1` beside `install.bat`; it is part of the generated launcher. The installed game can be on any drive or in a custom folder, provided its GOG installer registered it in Windows.

The builder copies the selected icon to `game.ico` at the media root if necessary, and overwrites any existing `install.bat`, `autorun.inf`, or `game.ico` in the selected folder. Modern Windows usually blocks AutoRun automatically, but the `autorun.inf` icon and label still apply to the mounted disc; double-click `install.bat` when AutoPlay does not offer the action.
