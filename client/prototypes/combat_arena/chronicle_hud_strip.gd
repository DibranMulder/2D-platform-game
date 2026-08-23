# PROTOTYPE — Chronicle-styled HUD strip (portrait medallion + HP / Mana / EXP
# bars) drawn to match art-source/ui-concepts/enchanted-chronicle-v1/
# ui-system-board.png. Throwaway prototype UI.
class_name PrototypeChronicleHudStrip
extends Control

const NAME_FONT := preload("res://assets/fonts/alegreya/AlegreyaSC-Medium.ttf")
const VALUE_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Medium.ttf")

# Chronicle palette
const INK_NAVY := Color("101b2c")
const BOOK_BLUE := Color("183454")
const BRASS := Color("c79b48")
const BRASS_DARK := Color("8a6a2f")
const QUEST_GOLD := Color("f2c45f")
const WARM_IVORY := Color("fff5d6")

const HP_TOP := Color("e46a5a")
const HP_BOT := Color("a5322a")
const MANA_TOP := Color("4f9fe0")
const MANA_BOT := Color("23548a")
const EXP_TOP := Color("9cc06f")
const EXP_BOT := Color("5f7d43")

const PORTRAIT_R := 44.0
const BAR_X := 112.0
const BAR_W := 316.0

var _hero_name := "HERO"
var _level := 1
var _health := 100
var _max_health := 100
var _mana := 100.0
var _max_mana := 100.0
var _exp := 0
var _exp_goal := 1000


func configure(hero_name: String, level: int) -> void:
    _hero_name = hero_name.to_upper()
    _level = level
    queue_redraw()


func set_values(
    health: int,
    max_health: int,
    mana: float,
    max_mana: float,
    exp_value: int,
    exp_goal: int,
) -> void:
    _health = health
    _max_health = maxi(1, max_health)
    _mana = mana
    _max_mana = maxf(1.0, max_mana)
    _exp = exp_value
    _exp_goal = maxi(1, exp_goal)
    queue_redraw()


func _draw() -> void:
    # Ink strip backing with brass trim.
    var strip := Rect2(PORTRAIT_R + 8.0, 8.0, BAR_W + 96.0, 108.0)
    _rounded(strip, Color(0.055, 0.09, 0.14, 0.9), 10.0, BRASS_DARK, 2)
    draw_rect(Rect2(strip.position + Vector2(6, 2), Vector2(strip.size.x - 12, 2)), Color(1, 1, 1, 0.06), true)

    _draw_portrait(Vector2(PORTRAIT_R + 6.0, 60.0), PORTRAIT_R)

    # Name
    draw_string(NAME_FONT, Vector2(BAR_X, 30.0), _hero_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, INK_NAVY.darkened(0.2))
    draw_string(NAME_FONT, Vector2(BAR_X - 1.0, 29.0), _hero_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, QUEST_GOLD)

    var hp_ratio := clampf(float(_health) / float(_max_health), 0.0, 1.0)
    var mana_ratio := clampf(_mana / _max_mana, 0.0, 1.0)
    var exp_ratio := clampf(float(_exp) / float(_exp_goal), 0.0, 1.0)

    _draw_bar(Vector2(BAR_X, 40.0), Vector2(BAR_W, 22.0), hp_ratio, HP_TOP, HP_BOT,
        "%s / %s" % [_comma(_health), _comma(_max_health)], 13)
    _draw_bar(Vector2(BAR_X, 66.0), Vector2(BAR_W, 22.0), mana_ratio, MANA_TOP, MANA_BOT,
        "%s / %s" % [_comma(roundi(_mana)), _comma(roundi(_max_mana))], 13)
    _draw_bar(Vector2(BAR_X, 92.0), Vector2(BAR_W, 13.0), exp_ratio, EXP_TOP, EXP_BOT,
        "%d%%" % roundi(exp_ratio * 100.0), 10)


func _draw_bar(pos: Vector2, size: Vector2, ratio: float, top: Color, bot: Color, text: String, font_size: int) -> void:
    var radius := size.y * 0.5
    # Track
    _rounded(Rect2(pos, size), Color(0.03, 0.05, 0.08, 0.94), radius, BRASS, 2)
    # Fill
    if ratio > 0.001:
        var fill_w := maxf(size.y - 2.0, (size.x - 4.0) * ratio)
        var fill_rect := Rect2(pos + Vector2(2, 2), Vector2(fill_w, size.y - 4.0))
        _rounded(fill_rect, bot, radius - 1.0, Color(0, 0, 0, 0), 0)
        # Gloss over the top half for a gradient sheen.
        var gloss := Rect2(fill_rect.position, Vector2(fill_rect.size.x, fill_rect.size.y * 0.52))
        _rounded(gloss, top, radius - 1.0, Color(0, 0, 0, 0), 0)
        # Bright shine line near the top.
        draw_rect(Rect2(pos + Vector2(4, 3), Vector2(fill_w - 4.0, maxf(1.0, size.y * 0.18))), Color(1, 1, 1, 0.22), true)
    # Value text, centered.
    if text != "":
        var text_size := VALUE_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
        var origin := pos + Vector2((size.x - text_size.x) * 0.5, size.y * 0.5 + font_size * 0.36)
        draw_string(VALUE_FONT, origin + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.65))
        draw_string(VALUE_FONT, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, WARM_IVORY)


func _draw_portrait(center: Vector2, r: float) -> void:
    # Frame + inner forest field
    draw_circle(center, r + 3.0, BRASS_DARK)
    draw_circle(center, r + 1.0, BRASS)
    draw_circle(center, r - 2.0, Color("2c4430"))
    draw_circle(center, r - 3.0, Color("38542f"))

    # Simple hero bust (kept inside the medallion).
    var cloak := PackedVector2Array([
        center + Vector2(-r * 0.5, r * 0.02),
        center + Vector2(r * 0.5, r * 0.02),
        center + Vector2(r * 0.6, r * 0.7),
        center + Vector2(-r * 0.6, r * 0.7),
    ])
    draw_colored_polygon(cloak, BOOK_BLUE.lightened(0.12))
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-r * 0.16, r * 0.02),
        center + Vector2(r * 0.16, r * 0.02),
        center + Vector2(0.0, r * 0.34),
    ]), Color("d8b27a"))
    var head_c := center + Vector2(0.0, -r * 0.2)
    var head_r := r * 0.27
    draw_circle(head_c, head_r, Color("e7b98f"))
    draw_colored_polygon(PackedVector2Array([
        head_c + Vector2(-head_r * 1.05, -head_r * 0.2),
        head_c + Vector2(head_r * 1.05, -head_r * 0.2),
        head_c + Vector2(head_r * 0.8, -head_r * 1.1),
        head_c + Vector2(-head_r * 0.8, -head_r * 1.1),
    ]), Color("6b4a2f"))

    # Brass inner ring masks any bust spill and frames the portrait.
    draw_arc(center, r - 1.0, 0.0, TAU, 48, BRASS, 4.0)
    draw_arc(center, r + 2.0, 0.0, TAU, 48, BRASS_DARK, 2.0)
    draw_arc(center, r + 1.0, PI * 0.72, PI * 1.28, 24, Color(1, 1, 1, 0.28), 2.0)

    # Level badge (bottom-left of medallion).
    var badge := center + Vector2(-r * 0.62, r * 0.66)
    draw_circle(badge, 15.0, BRASS_DARK)
    draw_circle(badge, 13.0, INK_NAVY)
    draw_arc(badge, 13.0, 0.0, TAU, 24, BRASS, 2.0)
    var level_text := str(_level)
    var lt_size := NAME_FONT.get_string_size(level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
    draw_string(NAME_FONT, badge + Vector2(-lt_size.x * 0.5, 6.0), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, WARM_IVORY)


func _rounded(rect: Rect2, color: Color, radius: float, border: Color, border_width: int) -> void:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    var r := int(maxf(0.0, radius))
    box.corner_radius_top_left = r
    box.corner_radius_top_right = r
    box.corner_radius_bottom_left = r
    box.corner_radius_bottom_right = r
    if border_width > 0:
        box.border_color = border
        box.set_border_width_all(border_width)
    draw_style_box(box, rect)


func _comma(value: int) -> String:
    var digits := str(absi(value))
    var out := ""
    var count := 0
    for index in range(digits.length() - 1, -1, -1):
        out = digits[index] + out
        count += 1
        if count % 3 == 0 and index > 0:
            out = "," + out
    return ("-" + out) if value < 0 else out
