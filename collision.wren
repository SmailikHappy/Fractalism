import "xs_math" for Vec2, Color
import "xs" for Render, Data

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

class ColliderDrawInfo {

    // Check types to 
    static check_type_overlap { -1 }
    static check_type_full { -2 }

    // Drawing result/priorities
    static draw_result_no_overlap { 0 }
    static draw_result_overlapping { 1 }
    static draw_result_static { 2 }
    static draw_result_moving { 3 }

    static get_check_type(draw_result) {
        if (draw_result == draw_result_static || draw_result == draw_result_moving) return check_type_full
        return check_type_overlap
    }


    static get_color_from_draw_result(draw_result) {
        if (draw_result == draw_result_no_overlap) {
            return Color.new(255, 255, 100)     // No overlap
        } else if (draw_result == draw_result_overlapping) {
            return Color.new(255, 100, 100)     // There is overlap 
        } else if (draw_result == draw_result_static) {
            return Color.new(0, 255, 0)         // Static collider
        } else if (draw_result == draw_result_moving) {
            return Color.new(100, 150, 255)     // Moving collider
        }
        return Color.new(255, 255, 255)
    }

    construct new(collider, pos, draw_result) {
        _collider = collider
        _pos = pos
        _draw_priority = draw_result
        _check_type = ColliderDrawInfo.get_check_type(draw_result)
    }

    collider { _collider }
    pos { _pos }
    check_type { _check_type }
    draw_priority { _draw_priority }
    color { ColliderDrawInfo.get_color_from_draw_result(_draw_priority) }
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

    static initialize() {
        __colliders_to_draw = []
    }

    static add_collider_to_draw(collider, collider_pos, draw_result) {
        if (Data.getBool("Draw colliders", Data.game)) {
            __colliders_to_draw.add(ColliderDrawInfo.new(collider, collider_pos, draw_result))
        }
    }

    static box_to_box_only_first_contact(collider1, collider1_pos, collider1_prev_pos, collider2, collider2_pos, collider2_prev_pos) {

        if (collider1_pos != collider1_prev_pos) {
            add_collider_to_draw(collider1, collider1_pos, ColliderDrawInfo.draw_result_moving)
        } else {
            add_collider_to_draw(collider1, collider1_pos, ColliderDrawInfo.draw_result_static)
        }

        if (collider2_pos != collider2_prev_pos) {
            add_collider_to_draw(collider2, collider2_pos, ColliderDrawInfo.draw_result_moving)
        } else {
            add_collider_to_draw(collider2, collider2_pos, ColliderDrawInfo.draw_result_static)
        }
        
        var result = CollisionResult.none

        if (box_to_box_are_overlapping(collider1, collider1_pos, collider2, collider2_pos) != CollisionResult.overlap) return result

        if ((collider1_prev_pos.x - collider2_prev_pos.x).abs > collider1.half_size.x + collider2.half_size.x) {

            // Collision hapenned on X coordinate side
            if (collider1_pos.x < collider2_pos.x) {                    
                result = CollisionResult.collider1_left
            } else {
                result = CollisionResult.collider1_right
            }
        }

        if ((collider1_prev_pos.y - collider2_prev_pos.y).abs > collider1.half_size.y + collider2.half_size.y) {

            // Collision hapenned on Y coordinate side
            if (collider1_pos.y < collider2_pos.y) {
                result = CollisionResult.collider1_bottom
            } else {
                result = CollisionResult.collider1_top
            }
        }

        return result
    }

    static box_to_box_are_overlapping(collider1, collider1_pos, collider2, collider2_pos) {
        if ((collider1_pos.x - collider2_pos.x).abs <= collider1.half_size.x + collider2.half_size.x &&
            (collider1_pos.y - collider2_pos.y).abs <= collider1.half_size.y + collider2.half_size.y) {

            add_collider_to_draw(collider1, collider1_pos, ColliderDrawInfo.draw_result_overlapping)
            add_collider_to_draw(collider2, collider2_pos, ColliderDrawInfo.draw_result_overlapping)

            return CollisionResult.overlap
        }

        add_collider_to_draw(collider1, collider1_pos, ColliderDrawInfo.draw_result_no_overlap)
        add_collider_to_draw(collider2, collider2_pos, ColliderDrawInfo.draw_result_no_overlap)

        return CollisionResult.none
    }

    static draw_colliders(camera) {

        var drawn_colliders = []

        var draw_ovelap_only = Data.getBool("Collision draw overlap only", Data.game)

        for (draw_info in __colliders_to_draw) {

            if (draw_ovelap_only && draw_info.check_type != ColliderDrawInfo.check_type_overlap) continue

            var collider_is_drawn = false

            for (drawn_collider in drawn_colliders) {
                if (draw_info.collider != drawn_collider.collider || draw_info.pos != drawn_collider.pos) continue
                        
                if (draw_info.draw_priority > drawn_collider.draw_priority) continue

                collider_is_drawn = true
            }
            
            if (collider_is_drawn) continue

            var collision_to_draw_from = camera.apply_translation(-draw_info.pos - draw_info.collider.half_size)
            var collision_to_draw_to   = camera.apply_translation(-draw_info.pos + draw_info.collider.half_size)

            Render.dbgColor(draw_info.color.toNum)

            // Border lines
            Render.dbgLine(collision_to_draw_from.x, collision_to_draw_from.y, collision_to_draw_from.x, collision_to_draw_to.y)
            Render.dbgLine(collision_to_draw_from.x, collision_to_draw_from.y, collision_to_draw_to.x, collision_to_draw_from.y)
            Render.dbgLine(collision_to_draw_to.x, collision_to_draw_to.y, collision_to_draw_from.x, collision_to_draw_to.y)
            Render.dbgLine(collision_to_draw_to.x, collision_to_draw_to.y, collision_to_draw_to.x, collision_to_draw_from.y)

            // Cross lines
            Render.dbgLine(collision_to_draw_to.x, collision_to_draw_to.y, collision_to_draw_from.x, collision_to_draw_from.y)
            Render.dbgLine(collision_to_draw_to.x, collision_to_draw_from.y, collision_to_draw_from.x, collision_to_draw_to.y)

            drawn_colliders.add(draw_info)
        }

        Render.dbgColor(Color.new(255, 255, 255).toNum)

        __colliders_to_draw.clear()
    }
}