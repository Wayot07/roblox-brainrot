#!/usr/bin/env python3
"""Generate default.project.json for Brainrot Bonanza (roblox-brainrot-01).

Builds the 3D world: baseplate, conveyor lane, 8 coloured base plots with
sign boards, spawn, totem, trees, lamps, boundary walls and the WaveWall
(the tsunami wall the server sweeps across the map).
"""
import json

def part(name, pos, size, color, material="SmoothPlastic", shape=None, anchored=True, collide=True, extra=None):
    p = {"$className": "Part", "$properties": {
        "Anchored": anchored, "CanCollide": collide,
        "Color": [round(c / 255, 5) for c in color],
        "Locked": True, "Material": material,
        "Position": list(pos), "Size": list(size),
    }}
    if shape:
        p["$properties"]["Shape"] = shape
    if extra:
        p["$properties"].update(extra)
    return {name: p}

def c3(r, g, b):
    return [round(r / 255, 5), round(g / 255, 5), round(b / 255, 5)]

BASES = [
    (1, "Red",    (-70, -60), (255, 80, 80)),
    (2, "Orange", (-25, -60), (255, 170, 0)),
    (3, "Blue",   (20, -60),  (80, 200, 255)),
    (4, "Purple", (65, -60),  (170, 90, 255)),
    (5, "Green",  (-70, 60),  (90, 255, 140)),
    (6, "Pink",   (-25, 60),  (255, 120, 200)),
    (7, "Yellow", (20, 60),   (255, 255, 90)),
    (8, "White",  (65, 60),   (255, 255, 255)),
]

ws = {}
# Ground.
ws.update(part("Baseplate", (0, -10, 0), (512, 20, 512), (110, 190, 90), "Grass"))
# Central plaza slab under the conveyor area.
ws.update(part("Plaza", (0, -0.2, 0), (170, 0.6, 40), (70, 70, 90), "Slate"))
# Conveyor lane (brainrots walk here) + neon edges.
ws.update(part("Conveyor", (0, 0.25, 0), (150, 0.5, 10), (40, 40, 55), "Slate"))
ws.update(part("ConveyorEdgeN", (0, 0.6, -5.2), (150, 0.3, 0.6), (255, 215, 0), "Neon"))
ws.update(part("ConveyorEdgeS", (0, 0.6, 5.2), (150, 0.3, 0.6), (255, 215, 0), "Neon"))
# Conveyor direction arrows (chevrons) — small neon wedges.
for i, x in enumerate(range(-60, 61, 20)):
    ws.update(part(f"Arrow{i}", (x, 0.6, 0), (4, 0.3, 4), (255, 215, 0), "Neon"))

# Bases: platform, back wall, sign board.
for bid, name, (bx, bz), color in BASES:
    ws.update(part(f"Base{bid}", (bx, 0, bz), (26, 1, 18), color))
    back_z = bz - 9.5 if bz < 0 else bz + 9.5
    ws.update(part(f"Base{bid}Wall", (bx, 3, back_z), (26, 6, 1), color))
    # Sign board on a pole at the front edge of the base.
    sign_z = bz + 10.5 if bz < 0 else bz - 10.5
    ws.update(part(f"Sign{bid}Pole", (bx - 10, 2, sign_z), (0.6, 4, 0.6), (60, 60, 60)))
    ws.update(part(f"Sign{bid}", (bx - 10, 5, sign_z), (7, 3, 0.5), (25, 25, 40)))

# Spawn location (south centre).
ws["SpawnLocation"] = {"$className": "SpawnLocation", "$properties": {
    "Anchored": True, "CanCollide": True, "Color": c3(90, 255, 140),
    "Neutral": True, "Position": [0, 1, 85], "Size": [10, 1, 10],
    "Duration": 0, "AllowTeamChangeOnTouch": False, "Enabled": True,
}}

# Brainrot Totem: stepped pyramid + gold ball (north of the conveyor).
ws.update(part("TotemBase", (0, 1, -35), (16, 2, 16), (120, 120, 140), "Slate"))
ws.update(part("TotemMid", (0, 3, -35), (11, 2, 11), (150, 150, 160), "Slate"))
ws.update(part("TotemTop", (0, 5, -35), (6, 2, 6), (180, 180, 190), "Slate"))
ws.update(part("TotemBall", (0, 8, -35), (5, 5, 5), (255, 215, 0), "Neon", shape="Ball"))
# Four corner pillars + beacons.
for i, (px, pz) in enumerate([(-88, -88), (88, -88), (-88, 88), (88, 88)]):
    ws.update(part(f"Pillar{i}", (px, 7, pz), (4, 14, 4), (40, 45, 70)))
    ws.update(part(f"Beacon{i}", (px, 15.5, pz), (5, 5, 5), (90, 200, 255), "Neon", shape="Ball"))

# Trees around the edges (trunk + leaves).
trees = [(-95, -40), (-95, 40), (95, -40), (95, 40), (-45, -85), (45, -85),
         (-45, 85), (45, 85), (-95, 0), (95, 0)]
for i, (tx, tz) in enumerate(trees):
    ws.update(part(f"Tree{i}Trunk", (tx, 2.5, tz), (1.5, 5, 1.5), (120, 80, 40), "Wood"))
    ws.update(part(f"Tree{i}Leaves", (tx, 7, tz), (6, 6, 6), (60, 180, 80), "Grass", shape="Ball"))

# Lamps along the conveyor.
for i, lx in enumerate([-60, -30, 0, 30, 60]):
    for lz in (-8, 8):
        ws.update(part(f"Lamp{i}_{'N' if lz < 0 else 'S'}Pole", (lx, 2.5, lz), (0.5, 5, 0.5), (50, 50, 60)))
        ws.update(part(f"Lamp{i}_{'N' if lz < 0 else 'S'}Bulb", (lx, 5.5, lz), (1.6, 1.6, 1.6), (255, 240, 160), "Neon", shape="Ball"))

# Boundary walls.
ws.update(part("WallNorth", (0, 5, -100), (204, 10, 2), (40, 45, 70)))
ws.update(part("WallSouth", (0, 5, 100), (204, 10, 2), (40, 45, 70)))
ws.update(part("WallWest", (-100, 5, 0), (2, 10, 204), (40, 45, 70)))
ws.update(part("WallEast", (100, 5, 0), (2, 10, 204), (40, 45, 70)))

# The tsunami wall (parked off-map; the server sweeps it across).
ws.update(part("WaveWall", (-120, 15, 0), (2, 30, 210), (60, 140, 255), "Glass",
               anchored=True, collide=False,
               extra={"Transparency": 0.35}))

project = {
    "name": "brainrot-bonanza",
    "tree": {
        "$className": "DataModel",
        "Lighting": {"$properties": {
            "Ambient": [0.4, 0.4, 0.45], "Brightness": 2, "ClockTime": 14,
            "GlobalShadows": True, "Outlines": False, "Technology": "Voxel",
        }},
        "Players": {"$properties": {"CharacterAutoLoads": True, "RespawnTime": 3}},
        "ReplicatedStorage": {"Shared": {"$path": "src/shared"}},
        "ServerScriptService": {"Server": {"$path": "src/server"}},
        "SoundService": {"$properties": {"RespectFilteringEnabled": True}},
        "StarterPlayer": {"StarterPlayerScripts": {"Client": {"$path": "src/client"}}},
        "Workspace": {"$properties": {"FilteringEnabled": True}, **ws},
    },
}

with open("default.project.json", "w") as f:
    json.dump(project, f, indent=2)
print("wrote default.project.json with", len(ws), "workspace instances")
