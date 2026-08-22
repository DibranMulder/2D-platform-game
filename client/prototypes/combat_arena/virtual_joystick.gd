class_name PrototypeVirtualJoystick
extends Control

signal vector_changed(value: Vector2)

const OUTER_RADIUS := 72.0
const KNOB_RADIUS := 30.0

var value := Vector2.ZERO
var _touch_index := -1
var _mouse_dragging := false


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and _touch_index == -1:
            _touch_index = touch.index
            _set_knob(touch.position)
            accept_event()
        elif not touch.pressed and touch.index == _touch_index:
            _touch_index = -1
            _release_knob()
            accept_event()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _touch_index:
            _set_knob(drag.position)
            accept_event()
    elif event is InputEventMouseButton:
        var mouse_button := event as InputEventMouseButton
        if mouse_button.button_index == MOUSE_BUTTON_LEFT:
            _mouse_dragging = mouse_button.pressed
            if _mouse_dragging:
                _set_knob(mouse_button.position)
            else:
                _release_knob()
            accept_event()
    elif event is InputEventMouseMotion and _mouse_dragging:
        _set_knob((event as InputEventMouseMotion).position)
        accept_event()


func _set_knob(local_pointer: Vector2) -> void:
    var center := size * 0.5
    value = (local_pointer - center) / OUTER_RADIUS
    value = value.limit_length(1.0)
    if value.length() < 0.12:
        value = Vector2.ZERO
    vector_changed.emit(value)
    queue_redraw()


func _release_knob() -> void:
    value = Vector2.ZERO
    vector_changed.emit(value)
    queue_redraw()


func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, OUTER_RADIUS, Color(0.05, 0.08, 0.13, 0.62))
    draw_arc(center, OUTER_RADIUS, 0.0, TAU, 48, Color(0.62, 0.76, 0.88, 0.72), 3.0)
    draw_circle(center + value * OUTER_RADIUS, KNOB_RADIUS, Color(0.58, 0.82, 0.95, 0.92))
    draw_circle(center + value * OUTER_RADIUS, 10.0, Color(0.88, 0.96, 1.0, 0.95))

