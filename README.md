# MachForge

A Godot and Blender sandbox for designing virtual projectiles and studying their simulated flights.

The current starter slice has live body and nose shaping, fin count and span controls, finish colors, a fixed virtual test cannon, a marked range, and a replay with a trajectory trace and telemetry. The flight solver is a deterministic prototype using game-scale drive settings; it is not yet the final high-fidelity model.

## Get the Android test build

Every push to `main` creates an installable, debug-signed Android APK. Open the repository's [Actions](https://github.com/tpylman90-ctrl/MachForge/actions) page, select the latest **Build Android APK** run, and download the **MachForge-Android-debug-APK** artifact. You can also start a build from the workflow's **Run workflow** button.

This debug APK is for device testing. It is not a Play Store release build.

## Open the project

Open `project.godot` in Godot 4.7.2. Blender source models go in `assets/blender_source/`; game exports go in `assets/godot_models/`.
