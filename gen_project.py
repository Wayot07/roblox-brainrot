#!/usr/bin/env python3
"""Build default.project.json for Brainrot Bonanza (roblox-brainrot-01).

Writes the 3D world the server expects: a grass baseplate, the central
conveyor lane with neon edges and chevrons, eight coloured base plots
(each with a platform, a back wall and a sign board on a pole), the spawn
pad, the totem, corner pillars with beacons, trees, lamps, boundary walls
and the WaveWall — the glass tsunami wall the server sweeps across the
map. Run it from the repo root; it overwrites default.project.json.
"""
import json


def rgb(r, g, b):
    """Roblox colours are 0..1 floats; the file stores them rounded."""
    return [round(r / 255, 5), round(g / 255, 5), round(b / 255, 5)]


def make_part(name, pos, size, color, material="SmoothPlastic", shape=None,
              anchored=True, collide=True, extra=None):
    """One Workspace Part entry for the Rojo project tree."""
    props = {
        "Anchored": anchored,
        "CanCollide": collide,
        "Color": rgb(*color),
        "Locked": True,
        "Material": material,
        "Position": list(pos),
        "Size": list(size),
    }
    if shape:
        props["Shape"] = shape
    if extra:
        props.update(extra)
    return {name: {"$className": "Part", "$properties": props}}


# The eight base plots: id, display name, centre (x, z), plot colour.
# North row at z = -60, south row at z = 60 — must match Config.luau.
BASES = [
    (1, "Red", (-70, -60), (255, 80, 80)),
    (2, "Orange", (-25, -60), (255, 170, 0)),
    (3, "Blue", (20, -60), (80, 200, 255)),
    (4, "Purple", (65, -60), (170, 90, 255)),
    (5, "Green", (-70, 60), (90, 255, 140)),
    (6, "Pink", (-25, 60), (255, 120, 200)),
    (7, "Yellow", (20, 60), (255, 255, 90)),
    (8, "White", (65, 60), (255, 255, 255)),
]

world = {}

# --- Ground: a big grass baseplate and the plaza slab under the lane.
world.update(make_part("Baseplate", (0, -10, 0), (512, 20, 512), (110, 190, 90), "Grass"))
world.update(make_part("Plaza", (0, -0.2, 0), (170, 0.6, 40), (70, 70, 90), "Slate"))

# --- Conveyor lane down the middle (z = 0), with glowing gold edges.
world.update(make_part("Conveyor", (0, 0.25, 0), (150, 0.5, 10), (40, 40, 55), "Slate"))
world.update(make_part("ConveyorEdgeN", (0, 0.6, -5.2), (150, 0.3, 0.6), (255, 215, 0), "Neon"))
world.update(make_part("ConveyorEdgeS", (0, 0.6, 5.2), (150, 0.3, 0.6), (255, 215, 0), "Neon"))

# Chevron arrows on the lane, pointing the way the brainrots walk.
for i, x in enumerate(range(-60, 61, 20)):
    world.update(make_part("Arrow%d" % i, (x, 0.6, 0), (4, 0.3, 4), (255, 215, 0), "Neon"))

# --- Base plots: platform, back wall, and a sign board on a pole.
for bid, _name, (bx, bz), color in BASES:
    world.update(make_part("Base%d" % bid, (bx, 0, bz), (26, 1, 18), color))
    back_z = bz - 9.5 if bz < 0 else bz + 9.5
    world.update(make_part("Base%dWall" % bid, (bx, 3, back_z), (26, 6, 1), color))
    sign_z = bz + 10.5 if bz < 0 else bz - 10.5
    world.update(make_part("Sign%dPole" % bid, (bx - 10, 2, sign_z), (0.6, 4, 0.6), (60, 60, 60)))
    world.update(make_part("Sign%d" % bid, (bx - 10, 5, sign_z), (7, 3, 0.5), (25, 25, 40)))

# --- Spawn pad (south centre, matches Config.SPAWN_POS).
world["SpawnLocation"] = {"$className": "SpawnLocation", "$properties": {
    "Anchored": True,
    "CanCollide": True,
    "Color": rgb(90, 255, 140),
    "Neutral": True,
    "Position": [0, 1, 85],
    "Size": [10, 1, 10],
    "Duration": 0,
    "AllowTeamChangeOnTouch": False,
    "Enabled": True,
}}

# --- Brainrot Totem: a stepped pyramid with a gold ball, north of the lane.
world.update(make_part("TotemBase", (0, 1, -35), (16, 2, 16), (120, 120, 140), "Slate"))
world.update(make_part("TotemMid", (0, 3, -35), (11, 2, 11), (150, 150, 160), "Slate"))
world.update(make_part("TotemTop", (0, 5, -35), (6, 2, 6), (180, 180, 190), "Slate"))
world.update(make_part("TotemBall", (0, 8, -35), (5, 5, 5), (255, 215, 0), "Neon", shape="Ball"))

# --- Four corner pillars, each topped with a glowing beacon.
for i, (px, pz) in enumerate([(-88, -88), (88, -88), (-88, 88), (88, 88)]):
    world.update(make_part("Pillar%d" % i, (px, 7, pz), (4, 14, 4), (40, 45, 70)))
    world.update(make_part("Beacon%d" % i, (px, 15.5, pz), (5, 5, 5), (90, 200, 255), "Neon", shape="Ball"))

# --- Trees around the edges: a wooden trunk and a round leafy top.
TREE_SPOTS = [(-95, -40), (-95, 40), (95, -40), (95, 40), (-45, -85), (45, -85),
              (-45, 85), (45, 85), (-95, 0), (95, 0)]
for i, (tx, tz) in enumerate(TREE_SPOTS):
    world.update(make_part("Tree%dTrunk" % i, (tx, 2.5, tz), (1.5, 5, 1.5), (120, 80, 40), "Wood"))
    world.update(make_part("Tree%dLeaves" % i, (tx, 7, tz), (6, 6, 6), (60, 180, 80), "Grass", shape="Ball"))

# --- Lamps lining the conveyor, one pair per post position.
for i, lx in enumerate([-60, -30, 0, 30, 60]):
    for lz in (-8, 8):
        side = "N" if lz < 0 else "S"
        world.update(make_part("Lamp%d_%sPole" % (i, side), (lx, 2.5, lz), (0.5, 5, 0.5), (50, 50, 60)))
        world.update(make_part("Lamp%d_%sBulb" % (i, side), (lx, 5.5, lz), (1.6, 1.6, 1.6), (255, 240, 160), "Neon", shape="Ball"))

# --- Boundary walls around the whole map.
world.update(make_part("WallNorth", (0, 5, -100), (204, 10, 2), (40, 45, 70)))
world.update(make_part("WallSouth", (0, 5, 100), (204, 10, 2), (40, 45, 70)))
world.update(make_part("WallWest", (-100, 5, 0), (2, 10, 204), (40, 45, 70)))
world.update(make_part("WallEast", (100, 5, 0), (2, 10, 204), (40, 45, 70)))

# --- The tsunami wall: parked off the west edge; the server sweeps it
# east across the map during a wave. Glass, see-through, no collision.
world.update(make_part("WaveWall", (-120, 15, 0), (2, 30, 210), (60, 140, 255), "Glass",
                       anchored=True, collide=False, extra={"Transparency": 0.35}))

project = {
    "name": "brainrot-bonanza",
    "tree": {
        "$className": "DataModel",
        "Lighting": {"$properties": {
            "Ambient": [0.4, 0.4, 0.45],
            "Brightness": 2,
            "ClockTime": 14,
            "GlobalShadows": True,
            "Outlines": False,
            "Technology": "Voxel",
        }},
        "Players": {"$properties": {"CharacterAutoLoads": True, "RespawnTime": 3}},
        "ReplicatedStorage": {"Shared": {"$path": "src/shared"}},
        "ServerScriptService": {"Server": {"$path": "src/server"}},
        "SoundService": {"$properties": {"RespectFilteringEnabled": True}},
        "StarterPlayer": {"StarterPlayerScripts": {"Client": {"$path": "src/client"}}},
        "Workspace": {"$properties": {"FilteringEnabled": True}, **world},
    },
}

with open("default.project.json", "w") as f:
    json.dump(project, f, indent=2, sort_keys=True)
print("wrote default.project.json with", len(world), "workspace instances")
