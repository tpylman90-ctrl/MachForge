# Project setup

## Engine versions

- Godot: 4.7.2 stable (the GitHub Actions workflow checks this version).
- Blender: latest stable in the GitHub Actions workflow; install Blender locally for authoring `.blend` source assets.

Open this repository's `project.godot` in Godot. The starter scene is `scenes/test_range.tscn`.

## Add-ons and physics

- **Jolt Physics** is selected in project settings. Godot includes Jolt directly; no separate Jolt submodule is needed.
- **TauPlot** is pinned as a Git submodule for in-game speed, range, and flight telemetry graphs.
- **GdUnit4** is pinned as a Git submodule for automated GDScript and scene tests.

Clone with submodules so the plugins are present:

```sh
git clone --recurse-submodules https://github.com/tpylman90-ctrl/MachForge.git
```

If you cloned without them, run `git submodule update --init --recursive`.

## Blender-to-Godot assets

Keep editable source models in `assets/blender_source/`; export game-ready `.glb` files to `assets/godot_models/`. Git LFS rules are set for large model source/export files. Do not commit signing credentials or keystores.
