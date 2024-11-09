import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math, Color
import "random" for Random
import "camera" for Camera

class Player {
    construct new(pos, scale, speed, dungeon_level, collider) {
        _pos = pos
        _scale = scale
        _speed = speed
        _dungeon_level = dungeon_level
        _collider = collider
        _previous_pos = pos
    }

    pos { _pos }
    pos=(v) { _pos = v}
    prev_pos { _previous_pos }
    prev_pos=(v) { _previous_pos = v}
    scale { _scale }
    scale=(v) { _scale = v}
    speed { _speed }
    speed=(v) { _speed = v}
    dungeon_level { _dungeon_level }
    dungeon_level=(v) { _dungeon_level = v }
    collider { _collider }
}