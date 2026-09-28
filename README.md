# LuxCrafter Client Setup

This installs the two pieces your Planet Crafter game needs to connect to a
LuxCrafter-managed server with a verified identity:

- **BepInEx** (5.4.23.5) — the mod loader Planet Crafter needs to run any plugin at all.
- **LuxCrafter.Client** — gives your installation a stable, cryptographic identity, so a
  LuxCrafter server operator can recognise your game and let it load your character. Without
  it, every connection is treated as unknown and only ever gets a fresh, unprogressed character.

Nothing here touches your Steam account, your save data, or any other game. It only adds files
inside your Planet Crafter install folder. It is fully reversible — deleting the `BepInEx` folder
and its two launcher files (`winhttp.dll`, `doorstop_config.ini`) restores a vanilla install.

## Install

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/30-something-programmer/LuxCrafter-public/main/loader.ps1 | iex
```

This downloads the current loader and runs it. The loader will:

1. Look for your Planet Crafter install (Steam registry, then every Steam library folder). If it
   can't find one, it opens a folder picker and tells you where to look in Steam
   (right-click **The Planet Crafter** → **Manage** → **Browse local files**).
2. Show you the exact folder it found and **ask you to confirm** before changing anything -
   type `y`, `yes`, or `ok` to proceed. Anything else cancels, nothing is touched.
3. Download BepInEx and the LuxCrafter client plugin (pinned versions, from this repo's
   [releases](https://github.com/30-something-programmer/LuxCrafter-public/releases)) and install
   them into that folder.

Re-running the installer is always safe - it will not overwrite an identity you already have.

## Uninstall

Delete these from inside your Planet Crafter folder: `BepInEx/`, `winhttp.dll`,
`doorstop_config.ini`.

If you want to remove the game's saved identity too (you will look like a brand-new,
never-seen installation to any server next time), also delete
`BepInEx/config/luxcrafter.client/` before deleting `BepInEx/` itself - it lives inside it.
