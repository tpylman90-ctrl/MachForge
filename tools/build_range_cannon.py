"""Build the editable MachForge range cannon and its Godot GLB export.

Run with: blender --background --python tools/build_range_cannon.py
All dimensions use meters. The Blender model is intentionally texture-free and
uses low-cost geometry and materials for Godot's mobile compatibility renderer.
"""

from pathlib import Path
import bpy
import math
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
BLEND_OUT = ROOT / "assets" / "blender_source" / "machforge_range_cannon.blend"
GLB_OUT = ROOT / "assets" / "godot_models" / "machforge_range_cannon.glb"
PREVIEW_OUT = ROOT / "assets" / "previews" / "machforge_range_cannon.png"


def material(name, color, metallic=0.0, roughness=0.55):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


STEEL = material("Graphite ceramic steel", (0.105, 0.16, 0.19), 0.72, 0.3)
EDGE = material("Machined titanium", (0.38, 0.48, 0.50), 0.82, 0.24)
ACCENT = material("Range safety teal", (0.03, 0.69, 0.63), 0.35, 0.32)
GOLD = material("Warning amber", (0.95, 0.48, 0.07), 0.25, 0.38)
BLACK = material("Bore and rubber", (0.018, 0.027, 0.031), 0.12, 0.8)
DECK = material("Deck composite", (0.16, 0.21, 0.23), 0.25, 0.65)
LIGHT = material("Indicator lens", (0.1, 0.95, 0.77), 0.15, 0.22)
STAGE = material("Preview studio floor", (0.035, 0.075, 0.085), 0.18, 0.72)


def assign(obj, mat):
    obj.data.materials.append(mat)
    return obj


def bevel(obj, amount=0.08, segments=2):
    mod = obj.modifiers.new("Soft machined edges", "BEVEL")
    mod.width = amount
    mod.segments = segments
    obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def box(name, location, dimensions, mat, bevel_size=0.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(obj, mat)
    if bevel_size:
        bevel(obj, bevel_size)
    return obj


def cylinder_y(name, location, radius, length, mat, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=length,
        location=location,
        rotation=(math.pi / 2.0, 0.0, 0.0),
    )
    obj = bpy.context.object
    obj.name = name
    assign(obj, mat)
    bevel(obj, min(0.035, radius * 0.08), 2)
    return obj


def torus_y(name, location, major_radius, minor_radius, mat):
    bpy.ops.mesh.primitive_torus_add(
        major_segments=48,
        minor_segments=12,
        location=location,
        rotation=(math.pi / 2.0, 0.0, 0.0),
        major_radius=major_radius,
        minor_radius=minor_radius,
    )
    obj = bpy.context.object
    obj.name = name
    assign(obj, mat)
    return obj


def cylinder_x(name, location, radius, depth, mat, vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=(0.0, math.pi / 2.0, 0.0),
    )
    obj = bpy.context.object
    obj.name = name
    assign(obj, mat)
    bevel(obj, 0.025, 2)
    return obj


def build():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    # Raised, bolted service deck. Forward is Blender +Y; GLTF converts it to
    # Godot's forward -Z axis during export.
    box("Armored firing deck", (0, 0, 0.56), (17.0, 19.0, 0.75), DECK, 0.2)
    box("Deck top plate", (0, 0, 0.97), (15.9, 18.0, 0.12), STEEL, 0.08)
    for side in (-1, 1):
        x = side * 7.45
        box("Teal deck edge rail", (x, 0, 1.08), (0.16, 17.4, 0.12), ACCENT, 0.035)
        for y in (-7.5, -3.0, 1.5, 6.0):
            cylinder_x("Deck tie-down", (side * 7.13, y, 1.055), 0.11, 0.12, EDGE, 20)

    # Long smoothbore tube and concentric muzzle insert. These pieces share a
    # movable pivot so the visible cannon follows the launch-angle control.
    barrel_parts = []
    barrel_parts.append(cylinder_y("Pressure tube", (0, -1.2, 3.6), 0.91, 10.4, STEEL))
    barrel_parts.append(cylinder_y("Outer barrel jacket", (0, -1.15, 3.6), 1.04, 8.3, EDGE))
    barrel_parts.append(cylinder_y("Recessed black bore", (0, -6.43, 3.6), 0.77, 0.025, BLACK))
    barrel_parts.append(torus_y("Muzzle crown", (0, -6.47, 3.6), 0.91, 0.14, ACCENT))
    barrel_parts.append(torus_y("Muzzle reinforcement", (0, -6.0, 3.6), 1.02, 0.13, EDGE))
    for y in (-4.6, -2.4, -0.2, 1.6):
        barrel_parts.append(torus_y("Barrel reinforcement band", (0, y, 3.6), 1.04, 0.105, STEEL))

    # The rear pressure chamber and breech read as a heavy, engineered machine.
    barrel_parts.append(cylinder_y("Breech block", (0, 4.05, 3.6), 1.38, 2.1, STEEL))
    barrel_parts.append(torus_y("Breech seal ring", (0, 3.05, 3.6), 1.34, 0.14, GOLD))
    barrel_parts.append(cylinder_y("Accumulator chamber", (0, 6.3, 3.6), 1.04, 2.2, EDGE))
    barrel_parts.append(cylinder_y("Accumulator end cap", (0, 7.48, 3.6), 1.17, 0.34, STEEL))
    barrel_parts.append(torus_y("Accumulator seam", (0, 5.2, 3.6), 1.08, 0.08, ACCENT))
    for x in (-0.57, 0.57):
        barrel_parts.append(cylinder_y("Pressure manifold", (x, 6.22, 4.4), 0.2, 2.0, STEEL, 24))
        barrel_parts.append(cylinder_y("Manifold end fitting", (x, 7.25, 4.4), 0.28, 0.18, GOLD, 24))

    barrel_pivot = bpy.data.objects.new("ElevatingTube", None)
    bpy.context.scene.collection.objects.link(barrel_pivot)
    barrel_pivot.location = (0.0, 0.0, 3.6)
    for part in barrel_parts:
        world_matrix = part.matrix_world.copy()
        part.parent = barrel_pivot
        part.matrix_world = world_matrix

    # Cradle, trunnions and visible elevation actuators.
    box("Cradle crossbeam", (0, 0.5, 1.95), (6.8, 3.1, 0.65), STEEL, 0.16)
    for side in (-1, 1):
        cylinder_x("Barrel trunnion", (side * 1.65, 0.5, 3.6), 0.53, 1.4, EDGE)
        box("Trunnion fork", (side * 1.75, 0.15, 3.0), (0.44, 2.2, 2.0), STEEL, 0.17)
        box("Fork safety stripe", (side * 2.0, 0.12, 3.0), (0.025, 1.05, 0.12), GOLD, 0.005)
        # Hydraulic rams angle back from the cradle to the deck.
        ram = cylinder_x("Elevation actuator", (side * 3.08, 2.0, 2.52), 0.18, 2.25, EDGE, 24)
        ram.rotation_euler[1] = math.radians(23.0)
        rod = cylinder_x("Actuator rod", (side * 3.08, 1.58, 2.98), 0.085, 1.1, ACCENT, 20)
        rod.rotation_euler[1] = math.radians(23.0)
        cylinder_x("Actuator pivot", (side * 3.08, 2.84, 1.18), 0.28, 0.6, GOLD, 24)

    # Rear service cabinet, readout face, analog gauge, and indicator lamps.
    box("Pressure control console", (4.0, 5.5, 2.05), (2.2, 2.7, 2.2), STEEL, 0.16)
    box("Console display", (5.13, 4.85, 2.28), (0.035, 1.14, 0.66), BLACK, 0.025)
    box("Display glow", (5.155, 4.86, 2.31), (0.018, 0.86, 0.38), ACCENT, 0.02)
    for z, mat in ((1.68, GOLD), (2.02, LIGHT), (2.36, GOLD)):
        cylinder_x("Status indicator", (5.16, 5.73, z), 0.11, 0.08, mat, 20)
    cylinder_x("Pressure gauge housing", (5.1, 7.0, 3.0), 0.42, 0.22, BLACK)
    cylinder_x("Pressure gauge bezel", (5.23, 7.0, 3.0), 0.35, 0.06, EDGE)
    cylinder_x("Pressure gauge face", (5.27, 7.0, 3.0), 0.29, 0.025, LIGHT, 40)
    needle = box("Gauge needle", (5.292, 7.0, 3.02), (0.025, 0.36, 0.035), GOLD, 0.008)
    needle.rotation_euler[0] = math.radians(-35.0)

    # Thick footings and isolation pads anchor the assembly to the range deck.
    for x in (-4.9, 4.9):
        for y in (-5.9, 0.0, 6.0):
            box("Isolation footing", (x, y, 1.35), (1.25, 1.55, 0.72), BLACK, 0.12)
            box("Footing cap", (x, y, 1.76), (1.38, 1.68, 0.15), GOLD, 0.05)

    # Amber and black hazard bars across the rear lip of the deck.
    for index in range(15):
        x = -6.4 + index * 0.92
        box("Rear hazard stripe", (x, 8.85, 1.06), (0.47, 0.11, 0.06), GOLD if index % 2 == 0 else BLACK, 0.01)


def build_preview_studio():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.render.resolution_x = 1440
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.film_transparent = False
    scene.render.filepath = str(PREVIEW_OUT)
    scene.view_settings.view_transform = "AgX"
    scene.world.use_nodes = True
    world_background = scene.world.node_tree.nodes.get("Background")
    world_background.inputs["Color"].default_value = (0.025, 0.045, 0.055, 1.0)
    world_background.inputs["Strength"].default_value = 0.42

    bpy.ops.mesh.primitive_plane_add(size=200.0, location=(0.0, 0.0, -0.12))
    floor = bpy.context.object
    floor.name = "Preview studio floor"
    assign(floor, STAGE)

    bpy.ops.object.camera_add(location=(26.0, -28.0, 18.0))
    camera = bpy.context.object
    camera.name = "Cannon presentation camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 32.0
    target = Vector((0.0, 0.0, 3.1))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    for name, location, energy, size, color in (
        ("Warm key", (8.0, -10.0, 19.0), 4200.0, 13.0, (1.0, 0.78, 0.55)),
        ("Cool fill", (-15.0, -3.0, 10.0), 3000.0, 16.0, (0.43, 0.76, 0.92)),
        ("Teal rim", (0.0, 13.0, 15.0), 4600.0, 11.0, (0.36, 1.0, 0.86)),
    ):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()

    scene.render.image_settings.color_mode = "RGB"


def main():
    BLEND_OUT.parent.mkdir(parents=True, exist_ok=True)
    GLB_OUT.parent.mkdir(parents=True, exist_ok=True)
    PREVIEW_OUT.parent.mkdir(parents=True, exist_ok=True)
    build()
    asset_objects = list(bpy.context.scene.objects)
    build_preview_studio()
    bpy.ops.render.render(write_still=True)
    bpy.ops.object.select_all(action="SELECT")
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    for obj in asset_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next((obj for obj in asset_objects if obj.name == "Armored firing deck"), asset_objects[0])
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_OUT))
    bpy.ops.export_scene.gltf(filepath=str(GLB_OUT), export_format="GLB", export_apply=True, use_selection=True)
    if not BLEND_OUT.is_file() or not GLB_OUT.is_file() or not PREVIEW_OUT.is_file():
        raise RuntimeError("Blender asset generation did not produce every expected output")
    print(f"Saved Blender source: {BLEND_OUT}")
    print(f"Exported Godot model: {GLB_OUT}")


if __name__ == "__main__":
    main()
