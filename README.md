# buckshot-modloader
Very basic modloader for Buckshot Roulette, not finished and will probably break if the game updates.

# Prefer godot-mod-loader over this!
If you just want the UI (which is bad too), you can still use this project, but the [Godot Modloader](https://github.com/GodotModding/godot-mod-loader) is a more generalized project and it **works with Godot 4.x**, if you're on the right branch. Since this was a completely solo project and it was put together in just a few minutes, godot-mod-loader is something you should prefer over this if you want a good modloader for the game.

# Requirements

[Buckshot Roulette](https://mikeklubnika.itch.io/buckshot-roulette) by Mike Klubnika

[GodotPCKExplorer](https://github.com/DmitriySalnikov/GodotPCKExplorer/) by DmitriySalnikov (until godotpcktool supports Godot 4 writing)

# Instructions

Because godotpcktool doesn't currently support writing to Godot 4 pck files or to embedded games, GodotPCKExplorer is currently the best option for it, even though it's a bit complicated to get the modloader running.

For if this is the first time you're patching the game:
- Open GodotPCKExplorer and go in `File` -> `Open File` and select the Buckshot Roulette executable.
- After it loads, click `Extract` -> `Extract All` and extract all the files in a **new folder**.
- After it's done, make a copy of the Buckshot Roulette executable and click `File` -> `Remove Pack from File`, then select the copy you made.
- Now you can continue to the following steps, or start directly from those if you're updating your patched version.

For if you've already patched the game before or you have everything ready:

- Copy the contents of the `MenuManager.gd` file in this repo, then open the real file in the `scripts` folder (in the folder you've extracted the game to) and replace the line `func _ready():` with the contents of the script in the repo.
- In GodotPCKExplorer, go to `File` -> `Pack or Embed folder` and select the folder you've extracted the game to.
- Once it loads, click `Pack` and write it to anywhere you want.
- When it's done, click `File` -> `Merge Pack Into File`. For the first selection, choose the `.pck` file you made with `Pack or Embed folder`, and for the second selection, choose the game executable you removed the pack file from.

When you launch the game, a `mods` folder should appear in the game's user data folder.
