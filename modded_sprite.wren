class ModdedSprite {
    construct new(sprite, mul, add, flags) {
        _sprite = sprite
        _mul = mul
        _add = add
        _flags = flags
    }

    add { _add }
    add=(a) { _add = a }

    mul { _mul }
    mul=(m) { _mul = m }

    flags { _flags }
    flags=(f) { _flags = f }

    sprite=(s) { _sprite = s }
    sprite { _sprite }

    toString { "[Sprite sprite:%(_sprite)] -> " + super.toString }
}