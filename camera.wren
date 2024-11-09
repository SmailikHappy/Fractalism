import "xs_math" for Vec2, Math, Color

class Camera {
    construct new(pos, scale) {
        _pos = pos
        _scale = scale
    }

    scale { _scale }
    scale=(v) { _scale = v }

    pos { _pos }
    pos=(v) { _pos = v }

    apply_translation(input_pos) {
        input_pos = input_pos + _pos
        input_pos = input_pos * _scale
        return input_pos
    }

    apply_scale(input_scale) {
        input_scale = input_scale * _scale
        return input_scale 
    }
}