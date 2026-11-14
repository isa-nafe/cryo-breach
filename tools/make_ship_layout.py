"""Works out the ship layout and writes scripts/data/ship_layout_data.gd.

Run from the project folder:   python tools/make_ship_layout.py
Add --draw to also save a picture of the layout (needs matplotlib):
                               python tools/make_ship_layout.py --draw layout.png

The room positions come from the owner's ship diagram (image pixels turned
into metres). Every room is a convex polygon. For each corridor this tool
picks the wall of each room it leaves by (the wall that points most nearly
toward the room at the other end), routes the corridor as a short polyline (a
stub straight out of each door and a run between the stubs), and checks the
result: corridors must not cut through rooms or run into each other. The game
reads only the data file it writes, so you can also edit that file by hand.
"""
import math
import sys

METRES_PER_PIXEL = 0.15
ORIGIN_PIXEL = (80, 290)  # the middle of the cockpit in the diagram
WALL = 0.2
DOOR_WIDTH = 2.0
MIN_DOOR_EDGE = 3.0  # a wall shorter than this cannot have a door
MIN_DOOR_GAP = 4.0  # doors in one room are at least this far apart
CLEARANCE = 1.45  # half a corridor plus its wall, plus a little
STUB_MIN, STUB_MAX = 2.0, 4.0
LATERAL_WEIGHT = 3.0  # degrees of aim traded for one metre off the straight line


def hexagon(side):
    pts = []
    for i in range(6):
        a = math.radians(30 + 60 * i)
        pts.append((math.sin(a) * side, -math.cos(a) * side))
    return pts


def ellipse(a, b, n, start_deg=0.0):
    pts = []
    for i in range(n):
        t = math.radians(start_deg + 360.0 * i / n)
        pts.append((a * math.sin(t), -b * math.cos(t)))
    return pts


def engine_shape(width, height, arc_steps=8):
    """A D: a flat west wall (three door positions) and a rounded east end."""
    left, half_h = -width / 2.0, height / 2.0
    pts = []
    for i in range(arc_steps + 1):
        phi = math.pi * i / arc_steps
        pts.append((left + width * math.sin(phi), -half_h * math.cos(phi)))
    pts.append((left, half_h / 3.0))
    pts.append((left, -half_h / 3.0))
    return pts


SHAPES = {
    "standard": hexagon(6.0),
    "cryo": ellipse(8.5, 17.0, 20),
    "engine": engine_shape(14.4, 20.0),
    "cockpit": ellipse(6.0, 11.0, 16),
}

# id, diagram pixel position, fixed room type, power section, shape
SLOTS = [
    ("bridge", (80, 290), "bridge", "Fore", "cockpit"),
    ("cryo_bay", (538, 290), "cryo_bay", "Fore", "cryo"),
    ("engine_a", (946, 122), "engine_a", "Aft", "engine"),
    ("engine_b", (946, 287), "engine_b", "Aft", "engine"),
    ("engine_c", (946, 465), "engine_c", "Aft", "engine"),
    ("pod_bay", (808, 380), "pod_bay", "Aft", "standard"),
    ("slot_1", (220, 148), "", "Fore", "standard"),
    ("slot_2", (184, 292), "", "Fore", "standard"),
    ("slot_3", (320, 292), "", "Fore", "standard"),
    ("slot_4", (220, 430), "", "Fore", "standard"),
    ("slot_5", (410, 200), "", "Fore", "standard"),
    ("slot_6", (410, 380), "", "Fore", "standard"),
    ("slot_7", (382, 80), "", "Mid", "standard"),
    ("slot_8", (538, 75), "", "Mid", "standard"),
    ("slot_9", (382, 495), "", "Mid", "standard"),
    ("slot_10", (538, 495), "", "Mid", "standard"),
    ("slot_11", (684, 240), "", "Aft", "standard"),
    ("slot_12", (684, 340), "", "Aft", "standard"),
    ("slot_13", (698, 95), "", "Aft", "standard"),
    ("slot_14", (698, 480), "", "Aft", "standard"),
    ("slot_15", (808, 198), "", "Aft", "standard"),
]

LINKS = [
    ("bridge", "slot_1"),
    ("bridge", "slot_2"),
    ("bridge", "slot_4"),
    ("slot_2", "slot_3"),
    ("slot_1", "slot_5"),
    ("slot_3", "slot_5"),
    ("slot_3", "slot_6"),
    ("slot_5", "slot_7"),
    ("slot_7", "slot_8"),
    ("slot_8", "slot_13"),
    ("slot_13", "engine_a"),
    ("slot_5", "cryo_bay"),
    ("slot_13", "slot_11"),
    ("slot_11", "cryo_bay"),
    ("slot_11", "slot_15"),
    ("slot_15", "engine_a"),
    ("cryo_bay", "slot_12"),
    ("slot_12", "pod_bay"),
    ("pod_bay", "engine_c"),
    ("slot_12", "slot_14"),
    ("slot_14", "engine_c"),
    ("slot_14", "slot_10"),
    ("slot_10", "slot_9"),
    ("slot_9", "slot_6"),
    ("slot_6", "cryo_bay"),
    ("slot_6", "slot_4"),
    # Engine B also joins the two rooms nearest to it.
    ("slot_15", "engine_b"),
    ("pod_bay", "engine_b"),
]

# Hand-tuned routes where the automatic one is not good enough:
# (a, b): {"stub_a": metres, "stub_b": metres, "wall_a": index, "wall_b": index,
#          "extra": [(x_px, y_px), ...]}
OVERRIDES = {
    ("bridge", "slot_2"): {"stub_a": 1.0, "stub_b": 1.0},
}


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def mul(a, k):
    return (a[0] * k, a[1] * k)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def length(a):
    return math.hypot(a[0], a[1])


def unit(a):
    n = length(a)
    return (a[0] / n, a[1] / n)


def to_world(px):
    return (
        (px[0] - ORIGIN_PIXEL[0]) * METRES_PER_PIXEL,
        (px[1] - ORIGIN_PIXEL[1]) * METRES_PER_PIXEL,
    )


def centroid(pts):
    area = cx = cz = 0.0
    for (x0, z0), (x1, z1) in zip(pts, pts[1:] + pts[:1]):
        cross = x0 * z1 - x1 * z0
        area += cross
        cx += (x0 + x1) * cross
        cz += (z0 + z1) * cross
    return (cx / (3 * area), cz / (3 * area))


class Room:
    def __init__(self, row):
        self.id, px, self.fixed, self.section, self.shape = row
        self.pos = to_world(px)
        self.local = SHAPES[self.shape]
        c = centroid(self.local)
        self.local = [sub(p, c) for p in self.local]  # centre the room on its slot
        self.edges = []
        for k in range(len(self.local)):
            a, b = self.local[k], self.local[(k + 1) % len(self.local)]
            e = sub(b, a)
            n = unit((e[1], -e[0]))
            mid = mul(add(a, b), 0.5)
            if dot(n, mid) < 0:  # make it point away from the middle
                n = (-n[0], -n[1])
            self.edges.append({"mid": mid, "normal": n, "length": length(e)})

    def world(self, p):
        return add(self.pos, p)

    def corners_world(self):
        return [self.world(p) for p in self.local]

    def inside_distance(self, point):
        """Largest distance beyond any wall; negative means inside."""
        p = sub(point, self.pos)
        return max(dot(sub(p, e["mid"]), e["normal"]) for e in self.edges)


rooms = {row[0]: Room(row) for row in SLOTS}


def angle_between(a, b):
    return math.degrees(math.acos(max(-1.0, min(1.0, dot(a, b)))))


def assign_edges():
    """Give every corridor an edge of each room, the one facing most nearly
    toward the room at the other end, keeping doors apart."""
    result = {}
    for rid, room in rooms.items():
        wanted = []
        for index, (a, b) in enumerate(LINKS):
            if rid in (a, b):
                other = b if rid == a else a
                wanted.append((index, unit(sub(rooms[other].pos, room.pos))))
        pairs = []
        for index, toward in wanted:
            for k, e in enumerate(room.edges):
                if e["length"] >= MIN_DOOR_EDGE:
                    # Prefer walls that point at the other room, and among equals
                    # the one nearest the straight line between the two rooms.
                    lateral = abs(dot(sub(e["mid"], (0.0, 0.0)), (toward[1], -toward[0])))
                    cost = angle_between(e["normal"], toward) + LATERAL_WEIGHT * lateral
                    pairs.append((cost, index, k))
        pairs.sort()
        used_links, chosen = set(), []
        # Walls fixed by hand in OVERRIDES ("wall_a" / "wall_b") come first.
        for index, _toward in wanted:
            a_id, b_id = LINKS[index]
            key = "wall_a" if rid == a_id else "wall_b"
            if key in OVERRIDES.get((a_id, b_id), {}):
                k = OVERRIDES[(a_id, b_id)][key]
                used_links.add(index)
                chosen.append(k)
                result[(index, rid)] = k
        for dev, index, k in pairs:
            if index in used_links:
                continue
            mid = room.edges[k]["mid"]
            if any(length(sub(mid, room.edges[j]["mid"])) < MIN_DOOR_GAP for j in chosen):
                continue
            used_links.add(index)
            chosen.append(k)
            result[(index, rid)] = k
    return result


def route(index, edges):
    a_id, b_id = LINKS[index]
    a, b = rooms[a_id], rooms[b_id]
    ea, eb = a.edges[edges[(index, a_id)]], b.edges[edges[(index, b_id)]]
    foot_a, foot_b = a.world(ea["mid"]), b.world(eb["mid"])
    gap = length(sub(foot_b, foot_a))
    override = OVERRIDES.get((a_id, b_id), {})
    default = max(STUB_MIN, min(STUB_MAX, 0.3 * gap))
    stub_a = override.get("stub_a", default)
    stub_b = override.get("stub_b", default)
    out_a = add(foot_a, mul(ea["normal"], stub_a))
    out_b = add(foot_b, mul(eb["normal"], stub_b))
    via = [out_a]
    for px in override.get("extra", []):
        via.append(to_world(px))
    via.append(out_b)
    return edges[(index, a_id)], edges[(index, b_id)], foot_a, foot_b, via


def sample(points, step=0.5):
    out = []
    for p, q in zip(points, points[1:]):
        n = max(1, int(length(sub(q, p)) / step))
        for k in range(n):
            out.append(add(p, mul(sub(q, p), k / n)))
    out.append(points[-1])
    return out


def dist_point_segment(p, a, b):
    ab = sub(b, a)
    t = max(0.0, min(1.0, dot(sub(p, a), ab) / max(dot(ab, ab), 1e-9)))
    return length(sub(p, add(a, mul(ab, t))))


def dist_point_polyline(p, pts):
    return min(dist_point_segment(p, a, b) for a, b in zip(pts, pts[1:]))


def check(paths, edges):
    problems = []
    for index in range(len(LINKS)):
        if (index, LINKS[index][0]) not in edges or (index, LINKS[index][1]) not in edges:
            problems.append("no free wall for corridor %s" % (LINKS[index],))
    for index, path in enumerate(paths):
        a_id, b_id = LINKS[index]
        for p in sample(path):
            bad = None
            for rid, room in rooms.items():
                if rid in (a_id, b_id):
                    end = path[0] if rid == a_id else path[-1]
                    if length(sub(p, end)) < 6.0:
                        continue
                if room.inside_distance(p) < CLEARANCE:
                    bad = rid
                    break
            if bad:
                problems.append("corridor %s-%s runs through room %s near (%.0f, %.0f)" % (a_id, b_id, bad, p[0], p[1]))
                break
        # A corridor should not double back on itself.
        for s0, s1, s2 in zip(path, path[1:], path[2:]):
            if dot(unit(sub(s1, s0)), unit(sub(s2, s1))) < -0.2:
                problems.append("corridor %s-%s turns back on itself" % (a_id, b_id))
                break
        pieces = [length(sub(q, p)) for p, q in zip(path, path[1:])]
        if max(pieces) < 3.0:
            problems.append("corridor %s-%s is too short for a door (longest piece %.1f m)" % (a_id, b_id, max(pieces)))
    for i in range(len(paths)):
        for j in range(i + 1, len(paths)):
            shared = set(LINKS[i]) & set(LINKS[j])
            pi = sample(paths[i])
            if shared:
                room = rooms[next(iter(shared))]
                pi = [p for p in pi if length(sub(p, room.pos)) > 0 and room.inside_distance(p) > 4.0]
            worst = min([dist_point_polyline(p, paths[j]) for p in pi] or [99])
            if worst < 2 * CLEARANCE:
                problems.append("corridors %s and %s come within %.1f m" % (LINKS[i], LINKS[j], worst))
    ids = list(rooms)
    for i in range(len(ids)):
        for j in range(i + 1, len(ids)):
            gap = min(rooms[ids[j]].inside_distance(c) for c in rooms[ids[i]].corners_world())
            gap2 = min(rooms[ids[i]].inside_distance(c) for c in rooms[ids[j]].corners_world())
            if max(gap, gap2) < 0.8 and length(sub(rooms[ids[i]].pos, rooms[ids[j]].pos)) < 25:
                problems.append("rooms %s and %s overlap or nearly touch (%.1f m)" % (ids[i], ids[j], max(gap, gap2)))
    return problems


def fmt(v):
    return "Vector2(%s, %s)" % (round(v[0], 2), round(v[1], 2))


def wrapped(vectors, indent, per_line=4):
    rows = []
    for i in range(0, len(vectors), per_line):
        rows.append(indent + ", ".join(fmt(v) for v in vectors[i:i + per_line]) + ",")
    return rows


def write_data(meta):
    lines = [
        "class_name ShipLayoutData",
        "extends RefCounted",
        "## The ship's layout as data: the room shapes, where each room is, which rooms",
        "## have a corridor between them, and how each corridor runs. GENERATED by",
        "## tools/make_ship_layout.py from the owner's ship diagram; edit that tool",
        "## (or this file, by hand) and keep the two in step.",
        "##",
        "## Positions are in metres on the floor: x runs fore (-X) to aft (+X), z is",
        "## across the ship. A room is a convex polygon around the middle of its slot;",
        "## its walls are numbered from the first corner, going clockwise seen from above.",
        "",
        "## Room shapes: the corners of each polygon, clockwise seen from above.",
        "const SHAPES := {",
    ]
    for name, pts in SHAPES.items():
        c = centroid(pts)
        lines.append('	&"%s": [' % name)
        lines += wrapped([sub(p, c) for p in pts], "		")
        lines.append("	],")
    lines += [
        "}",
        "",
        "## The room slots. `fixed` is the room type that is always there, or &\"\" for",
        "## a slot that gets a shuffled room type each match. `section` is the power",
        "## section.",
        "const SLOTS: Array[Dictionary] = [",
    ]
    for row in SLOTS:
        r = rooms[row[0]]
        lines += [
            "	{",
            '		"id": &"%s",' % r.id,
            '		"pos": %s,' % fmt(r.pos),
            '		"fixed": &"%s",' % r.fixed,
            '		"section": "%s",' % r.section,
            '		"shape": &"%s",' % r.shape,
            "	},",
        ]
    lines += [
        "]",
        "",
        "## The corridors. `wall_a` and `wall_b` are the walls of room `a` and room `b`",
        "## that the corridor leaves by (the door is in the middle of the wall); `via`",
        "## are the bends between the two doors.",
        "const LINKS: Array[Dictionary] = [",
    ]
    for index, (a, b) in enumerate(LINKS):
        wall_a, wall_b, _fa, _fb, via = meta[index]
        lines += [
            "	{",
            '		"a": &"%s",' % a,
            '		"b": &"%s",' % b,
            '		"wall_a": %d,' % wall_a,
            '		"wall_b": %d,' % wall_b,
            '		"via": [',
        ]
        lines += wrapped(via, "			", 3)
        lines += ["		],", "	},"]
    lines += ["]", ""]
    with open("scripts/data/ship_layout_data.gd", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


def draw(paths, filename):
    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon

    fig, ax = plt.subplots(figsize=(16, 9))
    for rid, room in rooms.items():
        ax.add_patch(Polygon(room.corners_world(), closed=True, fc="#1d4f78", ec="#7fd0ff", lw=1.5))
        ax.text(room.pos[0], room.pos[1], rid.replace("slot_", "s"), color="white", ha="center", va="center", fontsize=9)
    for path in paths:
        xs, ys = zip(*path)
        ax.plot(xs, ys, color="#ffcc66", lw=5, alpha=0.8, solid_capstyle="round")
        ax.plot(xs[0], ys[0], "o", color="#ff6666", ms=4)
        ax.plot(xs[-1], ys[-1], "o", color="#ff6666", ms=4)
    ax.set_aspect("equal")
    ax.invert_yaxis()
    ax.set_facecolor("#07121f")
    fig.patch.set_facecolor("#07121f")
    fig.savefig(filename, dpi=70, facecolor=fig.get_facecolor())
    print("drew", filename)


if __name__ == "__main__":
    edges = assign_edges()
    meta = {}
    for i in range(len(LINKS)):
        if (i, LINKS[i][0]) in edges and (i, LINKS[i][1]) in edges:
            meta[i] = route(i, edges)
    paths = [[meta[i][2]] + meta[i][4] + [meta[i][3]] for i in range(len(LINKS)) if i in meta]
    problems = check(paths, edges)
    print(len(rooms), "rooms,", len(LINKS), "corridors")
    for p in problems:
        print("PROBLEM:", p)
    if not problems:
        print("layout checks passed")
    if len(meta) == len(LINKS):
        write_data(meta)
    if "--draw" in sys.argv:
        draw(paths, sys.argv[sys.argv.index("--draw") + 1])
