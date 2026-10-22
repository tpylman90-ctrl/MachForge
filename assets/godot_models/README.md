# Godot model exports

The Godot range scene loads the Blender-built `machforge_range_cannon.glb` from this directory. The matching editable source is generated under `assets/blender_source/`.

Regenerate both files with `blender --background --python tools/build_range_cannon.py`. CI runs this before Godot imports the project and packages the source and export with the Android build.
