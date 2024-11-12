import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math, Color
import "random" for Random
import "camera" for Camera

class PlayerStates {
    static attack       { 0 }
    static no_attack    { 1 }
}

class Player {
    construct new(pos, scale, speed, dungeon_level, collider, sprite_info) {
        _pos = pos
        _scale = scale
        _speed = speed
        _dungeon_level = dungeon_level
        _collider = collider
        _sprite_info = sprite_info

        _previous_pos = pos
        _state = PlayerStates.no_attack
    }

    pos { _pos }
    pos=(v) { _pos = v}
    prev_pos { _previous_pos }
    prev_pos=(v) { _previous_pos = v}
    scale { _scale }
    scale=(v) { _scale = v }
    speed { _speed }
    speed=(v) { _speed = v }
    dungeon_level { _dungeon_level }
    dungeon_level=(v) { _dungeon_level = v }
    collider { _collider }
    sprite_info { _sprite_info }
    state { _state }
    state=(v) { _state = v }
}

class Zombie {
    construct new(pos, scale) {
        _pos = pos
        _scale = scale
        _previous_pos = pos
        _hp = __max_hp
    }

    static set_defaults(collider, max_hp, speed, dmg, sprite_info) {
        __collider = collider
        __max_hp = max_hp
        __speed = speed
        __dmg = dmg
        __sprite_info = sprite_info
    }

// Accessing defaults
    static collider { __collider }
    static dmg { __dmg }
    static speed { __speed }

// Getters/setters
    pos { _pos }
    pos=(v) { _pos = v }
    prev_pos { _previous_pos }
    prev_pos=(v) { _previous_pos = v}
    scale { _scale }
    sprite_info { __sprite_info }

// Interaction
    receive_dmg(damage) {
        _hp = _hp - damage
    }
    is_alive {
        if (_hp > 0) {
            return true
        } else {
            return false
        }
    }
}