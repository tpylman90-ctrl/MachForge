# Blender source assets

Editable Blender project files (`.blend`) are generated here from the procedural source in `tools/build_range_cannon.py`. Keep source models separate from their game exports.

The MachForge cannon uses meter-scale dimensions and includes its firing deck, smoothbore tube, reinforced muzzle, accumulator chamber, elevation cradle, hydraulic actuators, controls, and safety details. Run `blender --background --python tools/build_range_cannon.py` to regenerate the editable `.blend` and matching GLB export.
