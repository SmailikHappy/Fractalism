import "xs_math" for Vec2

class BoxCollider {
    construct new(size) {
        _size = size

        _half_size = _size/2
    }

    construct new(size_x, size_y) {
        _size = Vec2.new(size_x, size_y)

        _half_size = _size/2
    }

    size { _size }
    half_size { _half_size }
}

class CollisionResult {
    static none { 0 }

    static collider1_right { 1 }
    static collider1_left { 2 }
    static collider1_top { 3 }
    static collider1_bottom { 4 }

    static collider2_left { 1 }
    static collider2_right { 2 }
    static collider2_bottom { 3 }
    static collider2_top { 4 }

    static overlap { 5 }

    static to_string(collision_result) {
        var string = ""

        if (collision_result == none) {
            string = "no collision"
        }
        if (collision_result == collider1_right) {
            string = "right to collider1; left to collider2"
        }
        if (collision_result == collider1_left) {
            string = "left to collider1; right to collider2"
        }
        if (collision_result == collider1_top) {
            string = "top to collider1; bottom to collider2"
        }
        if (collision_result == collider1_bottom) {
            string = "bottom to collider1; top to collider2"
        }
        if (collision_result == overlap) {
            string = "colliders overlap"
        }

        return string
    }
}

class CollisionHandler {
    static box_to_box_only_first_contact(collider1, collider1_pos, collider1_prev_pos, collider2, collider2_pos, collider2_prev_pos) {

        if (box_to_box_are_overlapping(collider1, collider1_pos, collider2, collider2_pos) == CollisionResult.overlap) {

            if ((collider1_pos.x - collider2_pos.x).abs <= collider1.half_size.x + collider2.half_size.x) {

                if ((collider1_prev_pos.x - collider2_prev_pos.x).abs > collider1.half_size.x + collider2.half_size.x) {

                    // Collision hapenned on X coordinate side
                    if (collider1_pos.x < collider2_pos.x) {                    
                        return CollisionResult.collider1_left
                    } else {
                        return CollisionResult.collider1_right
                    }
                }
            }

            if ((collider1_pos.y - collider2_pos.y).abs <= collider1.half_size.y + collider2.half_size.y) {

                if ((collider1_prev_pos.y - collider2_prev_pos.y).abs > collider1.half_size.y + collider2.half_size.y) {

                    // Collision hapenned on Y coordinate side
                    if (collider1_pos.y < collider2_pos.y) {
                        return CollisionResult.collider1_bottom
                    } else {
                        return CollisionResult.collider1_top
                    }
                }
            }
        }
        
        return CollisionResult.none
    }

    static box_to_box_are_overlapping(collider1, collider1_pos, collider2, collider2_pos) {
        if ((collider1_pos.x - collider2_pos.x).abs <= collider1.half_size.x + collider2.half_size.x &&
            (collider1_pos.y - collider2_pos.y).abs <= collider1.half_size.y + collider2.half_size.y) {
            return CollisionResult.overlap
        }

        return CollisionResult.none
    }
}