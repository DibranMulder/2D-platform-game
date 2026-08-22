class_name PrototypeLineagePreview
extends Control

var lineage: Dictionary = {}


func set_lineage(value: Dictionary) -> void:
    lineage = value.duplicate(true)
    queue_redraw()


func _draw() -> void:
    var lineage_id := str(lineage.get("id", "human"))
    var palette := _palette_for(lineage_id)
    var center := Vector2(size.x * 0.5, size.y * 0.62)

    draw_rect(Rect2(Vector2.ZERO, size), palette["sky"], true)
    _draw_homeland(lineage_id, palette)
    draw_circle(center + Vector2(0.0, -92.0), 29.0, palette["skin"])

    match lineage_id:
        "tidekin":
            _draw_tidekin(center, palette)
        "grove_centaur":
            _draw_centaur(center, palette)
        "aeralith":
            _draw_aeralith(center, palette)
        "crag_troll":
            _draw_troll(center, palette)
        "deep_goblin":
            _draw_goblin(center, palette)
        "sunscour":
            _draw_sunscour(center, palette)
        "rimeborn":
            _draw_rimeborn(center, palette)
        _:
            _draw_human(center, palette)

    draw_string(
        ThemeDB.fallback_font,
        Vector2(18.0, 30.0),
        str(lineage.get("homeland", "Choose a Homeland")),
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        18,
        Color(0.95, 0.97, 1.0, 0.9),
    )


func _draw_homeland(lineage_id: String, palette: Dictionary) -> void:
    var ground_y := size.y * 0.79
    draw_rect(Rect2(0.0, ground_y, size.x, size.y - ground_y), palette["ground"], true)
    match lineage_id:
        "tidekin":
            for wave_y: float in [ground_y, ground_y + 22.0, ground_y + 44.0]:
                draw_line(Vector2(0.0, wave_y), Vector2(size.x, wave_y), Color("7bdff2"), 4.0)
        "grove_centaur":
            for tree_x: float in [45.0, size.x - 50.0]:
                draw_rect(Rect2(tree_x - 7.0, ground_y - 100.0, 14.0, 100.0), Color("533b2e"), true)
                draw_circle(Vector2(tree_x, ground_y - 110.0), 36.0, Color("315d3a"))
        "aeralith":
            draw_circle(Vector2(65.0, ground_y - 60.0), 34.0, Color(1, 1, 1, 0.34))
            draw_circle(Vector2(100.0, ground_y - 55.0), 44.0, Color(1, 1, 1, 0.34))
        "crag_troll":
            draw_polygon(
                PackedVector2Array([Vector2.ZERO, Vector2(95.0, ground_y - 125.0), Vector2(190.0, ground_y)]),
                PackedColorArray([Color("3c4852")]),
            )
        "deep_goblin":
            for crystal_x: float in [45.0, size.x - 62.0]:
                draw_polygon(
                    PackedVector2Array([
                        Vector2(crystal_x, ground_y),
                        Vector2(crystal_x + 18.0, ground_y - 64.0),
                        Vector2(crystal_x + 36.0, ground_y),
                    ]),
                    PackedColorArray([Color("8d69c9")]),
                )
        "sunscour":
            draw_circle(Vector2(size.x - 55.0, 62.0), 32.0, Color("ffca62"))
            draw_line(Vector2.ZERO + Vector2(0.0, ground_y - 8.0), Vector2(size.x, ground_y - 38.0), Color("d89440"), 24.0)
        "rimeborn":
            draw_polygon(
                PackedVector2Array([Vector2(0.0, ground_y), Vector2(95.0, ground_y - 84.0), Vector2(195.0, ground_y)]),
                PackedColorArray([Color("c8e6f2")]),
            )


func _draw_human(center: Vector2, palette: Dictionary) -> void:
    draw_rect(Rect2(center + Vector2(-28.0, -62.0), Vector2(56.0, 92.0)), palette["cloth"], true)
    draw_line(center + Vector2(-18.0, 30.0), center + Vector2(-22.0, 78.0), palette["dark"], 13.0)
    draw_line(center + Vector2(18.0, 30.0), center + Vector2(22.0, 78.0), palette["dark"], 13.0)
    draw_line(center + Vector2(28.0, -45.0), center + Vector2(72.0, -80.0), Color("dcebf2"), 8.0)


func _draw_tidekin(center: Vector2, palette: Dictionary) -> void:
    draw_circle(center + Vector2(0.0, -88.0), 38.0, palette["skin"])
    draw_circle(center + Vector2(-16.0, -108.0), 11.0, Color("edf7d2"))
    draw_circle(center + Vector2(16.0, -108.0), 11.0, Color("edf7d2"))
    draw_circle(center + Vector2(-16.0, -108.0), 4.0, palette["dark"])
    draw_circle(center + Vector2(16.0, -108.0), 4.0, palette["dark"])
    draw_polygon(
        PackedVector2Array([
            center + Vector2(-34.0, -60.0),
            center + Vector2(34.0, -60.0),
            center + Vector2(24.0, 34.0),
            center + Vector2(-24.0, 34.0),
        ]),
        PackedColorArray([palette["cloth"]]),
    )
    draw_line(center + Vector2(-15.0, 32.0), center + Vector2(-35.0, 75.0), palette["skin"], 15.0)
    draw_line(center + Vector2(15.0, 32.0), center + Vector2(35.0, 75.0), palette["skin"], 15.0)


func _draw_centaur(center: Vector2, palette: Dictionary) -> void:
    draw_rect(Rect2(center + Vector2(-30.0, -66.0), Vector2(60.0, 90.0)), palette["cloth"], true)
    _draw_oval(center + Vector2(8.0, 42.0), Vector2(76.0, 34.0), palette["skin"])
    for leg_x: float in [-40.0, -15.0, 30.0, 55.0]:
        draw_line(center + Vector2(leg_x, 58.0), center + Vector2(leg_x - 3.0, 92.0), palette["skin"], 12.0)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for index in 32:
        var angle := TAU * float(index) / 32.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_polygon(points, PackedColorArray([color]))


func _draw_aeralith(center: Vector2, palette: Dictionary) -> void:
    draw_polygon(
        PackedVector2Array([
            center + Vector2(-22.0, -56.0),
            center + Vector2(-92.0, -98.0),
            center + Vector2(-54.0, -8.0),
        ]),
        PackedColorArray([Color("d8eff7")]),
    )
    draw_polygon(
        PackedVector2Array([
            center + Vector2(22.0, -56.0),
            center + Vector2(92.0, -98.0),
            center + Vector2(54.0, -8.0),
        ]),
        PackedColorArray([Color("d8eff7")]),
    )
    _draw_human(center, palette)


func _draw_troll(center: Vector2, palette: Dictionary) -> void:
    draw_circle(center + Vector2(0.0, -84.0), 40.0, palette["skin"])
    draw_rect(Rect2(center + Vector2(-52.0, -48.0), Vector2(104.0, 91.0)), palette["cloth"], true)
    draw_line(center + Vector2(-34.0, 40.0), center + Vector2(-40.0, 89.0), palette["skin"], 24.0)
    draw_line(center + Vector2(34.0, 40.0), center + Vector2(40.0, 89.0), palette["skin"], 24.0)


func _draw_goblin(center: Vector2, palette: Dictionary) -> void:
    center += Vector2(0.0, 30.0)
    draw_polygon(
        PackedVector2Array([
            center + Vector2(-28.0, -100.0),
            center + Vector2(-68.0, -118.0),
            center + Vector2(-31.0, -73.0),
        ]),
        PackedColorArray([palette["skin"]]),
    )
    draw_polygon(
        PackedVector2Array([
            center + Vector2(28.0, -100.0),
            center + Vector2(68.0, -118.0),
            center + Vector2(31.0, -73.0),
        ]),
        PackedColorArray([palette["skin"]]),
    )
    draw_circle(center + Vector2(0.0, -90.0), 31.0, palette["skin"])
    draw_rect(Rect2(center + Vector2(-25.0, -58.0), Vector2(50.0, 75.0)), palette["cloth"], true)
    draw_line(center + Vector2(-12.0, 15.0), center + Vector2(-18.0, 54.0), palette["dark"], 11.0)
    draw_line(center + Vector2(12.0, 15.0), center + Vector2(18.0, 54.0), palette["dark"], 11.0)


func _draw_sunscour(center: Vector2, palette: Dictionary) -> void:
    _draw_human(center, palette)
    draw_arc(center + Vector2(0.0, -92.0), 34.0, PI, TAU, 20, Color("a13c2f"), 15.0)
    draw_line(center + Vector2(-16.0, -87.0), center + Vector2(16.0, -87.0), Color("e5c188"), 8.0)
    draw_line(center + Vector2(36.0, -45.0), center + Vector2(70.0, 70.0), Color("d9c4a0"), 6.0)


func _draw_rimeborn(center: Vector2, palette: Dictionary) -> void:
    _draw_human(center, palette)
    draw_polygon(
        PackedVector2Array([
            center + Vector2(-28.0, -108.0),
            center + Vector2(-10.0, -154.0),
            center + Vector2(-2.0, -111.0),
        ]),
        PackedColorArray([Color("b9efff")]),
    )
    draw_polygon(
        PackedVector2Array([
            center + Vector2(28.0, -108.0),
            center + Vector2(10.0, -154.0),
            center + Vector2(2.0, -111.0),
        ]),
        PackedColorArray([Color("b9efff")]),
    )


func _palette_for(lineage_id: String) -> Dictionary:
    var palettes := {
        "tidekin": {"sky": Color("183d55"), "ground": Color("225f6b"), "skin": Color("76b66f"), "cloth": Color("246b82"), "dark": Color("172b35")},
        "human": {"sky": Color("5b7d9a"), "ground": Color("496b3f"), "skin": Color("d8ac83"), "cloth": Color("4569a8"), "dark": Color("263044")},
        "grove_centaur": {"sky": Color("294838"), "ground": Color("243c2c"), "skin": Color("9a6c43"), "cloth": Color("4d733c"), "dark": Color("2e241e")},
        "aeralith": {"sky": Color("6e9eba"), "ground": Color("b8d9e2"), "skin": Color("d4e7e9"), "cloth": Color("6f7fc2"), "dark": Color("39445e")},
        "crag_troll": {"sky": Color("343d47"), "ground": Color("383d3e"), "skin": Color("7c8b68"), "cloth": Color("5b3e35"), "dark": Color("292c2a")},
        "deep_goblin": {"sky": Color("211b2e"), "ground": Color("302743"), "skin": Color("879b4c"), "cloth": Color("6c4a78"), "dark": Color("282031")},
        "sunscour": {"sky": Color("9d5937"), "ground": Color("a96a38"), "skin": Color("8f5b3e"), "cloth": Color("842f2f"), "dark": Color("3d2926")},
        "rimeborn": {"sky": Color("31556f"), "ground": Color("9bc5d5"), "skin": Color("a5c8d2"), "cloth": Color("385f85"), "dark": Color("243c55")},
    }
    return palettes.get(lineage_id, palettes["human"])
