# Window Transparency (`robbie.transparency`)

A single slider for the [Omarchy](https://omarchy.org) bar that controls how
transparent every window is, plus a checkbox that keeps **video players and web
pages fully opaque** so video and web content never goes see-through.

<img alt="sliders" src="">

<!-- preview: drop a screenshot next to this file and reference it here -->

## What it does

- **OPACITY slider** — sets the active/inactive opacity applied to every normal
  window, from 30% (very transparent) to 100% (fully opaque). Applies on
  release, which is when the change is written and Hyprland is reloaded.
- **"Ignore video & web pages" checkbox** — when checked, browsers and video
  players are kept fully opaque. When unchecked, the slider applies to them
  too.

The slider drives Omarchy's own `default-opacity` window tag, so Omarchy's
existing exclusions (games, `qemu`, Steam, webcam overlays, the shell itself)
keep working. The checkbox only decides whether the *browser* and *video
player* classes opt back out of that tag.

### Apps treated as "video or web pages"

Matched by window class:

- **Browsers / web pages:** Chrome, Chromium, Brave, Microsoft Edge, Vivaldi,
  Helium, Firefox, Zen, LibreWolf, qutebrowser, Opera, Falkon, Epiphany.
- **Video players:** mpv, VLC, Celluloid, Totem, Clapper, SMPlayer, MPlayer,
  Dragon Player, Parole.

Window classes are matched as regexes, so Chromium web-app windows (e.g. a
YouTube PWA) are covered too.

## Bar gestures

- **Left-click** the icon — open the panel.
- The icon doubles as a status dot for the current opacity.

There is also IPC and a CLI (below).

## Install

One line:

```sh
omarchy plugin add https://github.com/RobbieUK1/omarchy-transparency.git --enable
```

That clones the repo, validates it, installs it to
`~/.config/omarchy/plugins/robbie.transparency/`, rescans the shell and enables
the widget. Without `--enable` it installs but leaves the widget off; you can
then run `omarchy plugin enable robbie.transparency right`.

Update to a newer revision with:

```sh
omarchy plugin update robbie.transparency
```

From a local checkout instead:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/robbie.transparency
omarchy plugin enable robbie.transparency right
```

## What it writes

Nothing is written until you move the slider or toggle the checkbox. Changes
splice a **managed block** between these markers in
`~/.config/hypr/looknfeel.lua`:

```lua
-- BEGIN robbie.transparency (managed by the Window Transparency bar panel ...)
-- END robbie.transparency
```

Only that block is ever touched; a backup of the previous file is kept at
`~/.config/hypr/looknfeel.lua.transparency.bak`. State (opacity + checkbox)
lives in `~/.local/state/omarchy/transparency.json`.

## CLI

The panel is a front-end for `scripts/transparency-ctl`:

```
transparency-ctl get                     # persisted state
transparency-ctl readback                # state parsed from the live block
transparency-ctl set '<json>'            # merge, persist, rewrite, reload
transparency-ctl apply                   # rewrite from state + reload
transparency-ctl clear                   # remove the block + reload
transparency-ctl toggle                  # flip the checkbox + reload
```

Example:

```sh
transparency-ctl set '{"opacity":0.85,"ignoreVideoWeb":true}'
```

Shell IPC (same panel open/close, plus the JSON surface):

```sh
omarchy-shell transparency open
```

## Notes

- **Glass (`khwan.glass`) conflict:** Glass's FROST slider writes a catch-all
  `o.window(".*", { opacity = ... })` to the same file. If you use both, the
  rule written last wins, and Glass's catch-all can make the ignore checkbox
  appear to do nothing for non-browser apps. Use one or the other. If you are
  removing Glass, pick its **Stock** style first so its block is cleaned out of
  `looknfeel.lua`.
- User space only: no elevated permissions, no daemon, no network access.
- `python3` and `hyprctl` are already present on Omarchy.

## Settings & Exclusions

Click the settings icon (gear) in the panel to open a settings page.

- **Keep video & web pages opaque** — toggle this on/off. When on, the built-in browser and video player classes above stay at 100% opacity. When off, they follow the global opacity slider.
- **Exclude apps (always opaque)** — add any window class that should never become transparent. Use the input to add a class manually, or click any class listed under "Currently running" to exclude it with one click. Remove excluded entries with the X button.

The `exclude add|remove|list` and `running` commands are also available via the backend script:

```bash
~/.config/omarchy/plugins/robbie.transparency/scripts/transparency-ctl exclude add discord
~/.config/omarchy/plugins/robbie.transparency/scripts/transparency-ctl running
~/.config/omarchy/plugins/robbie.transparency/scripts/transparency-ctl exclude list
```

## State & files

- State: `~/.local/state/omarchy/transparency.json` (keys: `opacity`, `ignoreVideoWeb`, `excludedApps`, `version`)
- Managed Hyprland block: `~/.config/hypr/looknfeel.lua` between `-- BEGIN robbie.transparency ...` and `-- END robbie.transparency` (edits there are overwritten)
- Backup: `~/.config/hypr/looknfeel.lua.transparency.bak`
- IPC target: `robbie.transparency`

## Tips

- To see exact Hyprland window classes: `hyprctl clients` (look for `class:`).
