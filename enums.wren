class EnumTile {
    static empty    { 0 }
    static floor1   { 1 }
    static floor2   { 2 }
    static wall     { 3 }
    static COUNT    { 4 }

    static is_floor(v)    {
        if (v == floor1 || v == floor2) {
            return true
        }
        return false
    }
}