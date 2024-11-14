import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math, Color
import "random" for Random
import "camera" for Camera
import "modded_sprite" for ModdedSprite
import "enums" for PlayerState, ZombieState


class Player {
    construct new(pos, scale, speed, dungeon_level, collider, sprite_info) {
        _pos = pos
        _scale = scale
        _speed = speed
        _dungeon_level = dungeon_level
        _collider = collider
        _sprite_info = sprite_info

        _previous_pos = pos
        _state = PlayerState.no_attack

        _hp = 100
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
    hp { _hp }

    receive_dmg(v) { _hp = _hp - v }
    heal(v) { _hp = _hp + v }
}

class Zombie {
    construct new(pos, scale) {
        _pos = pos
        _scale = scale
        _previous_pos = pos
        _hp = __max_hp
        _state = ZombieState.hanging_around
        _cooldown = 0.0
        _sprite_info = ModdedSprite.new(
            __default_sprite_info.sprite,
            __default_sprite_info.mul,
            __default_sprite_info.add,
            __default_sprite_info.flags
        )
    }

    static set_defaults(collider, max_hp, speed, dmg, sprite_info) {
        __collider = collider
        __max_hp = max_hp
        __speed = speed
        __dmg = dmg
        __default_sprite_info = sprite_info
    }

// Accessing defaults
    collider { __collider }
    dmg { __dmg }
    speed { __speed }

// Getters/setters
    pos { _pos }
    pos=(v) { _pos = v }
    prev_pos { _previous_pos }
    prev_pos=(v) { _previous_pos = v}
    scale { _scale }
    sprite_info { _sprite_info }
    state { _state }
    state=(v) { _state = v }
    cooldown { _cooldown }
    cooldown=(v) { _cooldown = v }

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