System.print("Wren just got compiled to bytecode")

import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math, Color
import "random" for Random
import "camera" for Camera
import "player" for Player
import "dungeon" for DungeonFractalElement, Grid
import "modded_sprite" for ModdedSprite
import "enums" for EnumTile
import "collision" for BoxCollider, CollisionResult, CollisionHandler

class Game {

    static initialize() {
        System.print("yes")
        System.print("ahhahaha")

        __random = Random.new()
        CollisionHandler.initialize()

        __sprite_list = List.filled(EnumTile.COUNT, EnumTile.empty)

        var tile_set_image = Render.loadImage("[game]/assets/monochrome-transparent_packed.png")
        var tile_set_rows = 22
        var tile_set_columns = 49

        __sprite_list[EnumTile.floor1] =    ModdedSprite.new(Render.createGridSprite(tile_set_image, tile_set_columns, tile_set_rows, 2, 0), Color.new(255, 255, 0).toNum, 0x00, Render.spriteNone)
        __sprite_list[EnumTile.floor2] =    ModdedSprite.new(Render.createGridSprite(tile_set_image, tile_set_columns, tile_set_rows, 2, 0), Color.new(63, 255, 63).toNum, 0x00, Render.spriteNone)
        __sprite_list[EnumTile.wall] =      ModdedSprite.new(Render.createGridSprite(tile_set_image, tile_set_columns, tile_set_rows, 1, 17), Color.new(255, 127, 0).toNum, 0x00, Render.spriteNone)
        __sprite_list[EnumTile.empty] =     ModdedSprite.new(Render.createGridSprite(tile_set_image, tile_set_columns, tile_set_rows, 8, 5), Color.new(100, 100, 100, 255).toNum, 0x00, Render.spriteNone)

        var dungeon_width = Data.getNumber("Dungeon width", Data.game)
        var dungeon_height = Data.getNumber("Dungeon height", Data.game)

        __camera = Camera.new(Vec2.new(0,0), 1.0)

        __dungeon = DungeonFractalElement.new(Vec2.new(0, -1.5), Vec2.new(-4, -2.5), 2, dungeon_width, dungeon_height, __random)

        __player = Player.new(__dungeon.get_world_from_tiled_pos(0, 0, 0), 1.0, Data.getNumber("Player speed", Data.game), 0.0, BoxCollider.new(Vec2.new(4, 8)))

        __screen_resolution = Vec2.new(Data.getNumber("Width", Data.system), Data.getNumber("Height", Data.system))
    }    

    static update(dt) {

        __player.prev_pos = Vec2.new(__player.pos.x, __player.pos.y)

        handle_input(dt)
        handle_collisions(dt)

        __camera.pos = __player.pos
        __camera.scale = __player.scale * Data.getNumber("Relative camera scale", Data.game)
        __player.speed = Data.getNumber("Player speed", Data.game)
    }

    static render() {

        render_dungeon(0)

        if (Data.getBool("Draw colliders", Data.game)) {
            CollisionHandler.draw_colliders(__camera)
        }
    }


    static handle_input(dt) {        

        // WASD
        if (Input.getKey(Input.keyW)) {
            __player.pos.y = __player.pos.y - __player.speed * dt
        }
        if (Input.getKey(Input.keyS)) {
            __player.pos.y = __player.pos.y + __player.speed * dt
        }
        if (Input.getKey(Input.keyA)) {
            __player.pos.x = __player.pos.x + __player.speed * dt
        }
        if (Input.getKey(Input.keyD)) {
            __player.pos.x = __player.pos.x - __player.speed * dt
        }

        // QE
        if (Input.getKey(Input.keyQ)) {
            __player.scale = __player.scale * (1 + __player.speed * dt / 100)
        }
        if (Input.getKey(Input.keyE)) {
            __player.scale = __player.scale * (1 - __player.speed * dt / 100)
        }
    }

    static handle_collisions(dt) {
        var collision_margin = Data.getNumber("Collision margin", Data.game)

        var player_tile = __dungeon.get_tiled_from_world_pos(__player.pos, 0)
        player_tile = Vec2.new(player_tile.x.floor, player_tile.y.floor)

        var wall_collider = BoxCollider.new(16, 16)

        var offsets_to_check = [
            Vec2.new(0, 1),
            Vec2.new(0, -1),
            Vec2.new(1, 0),
            Vec2.new(-1, 0),
            Vec2.new(1, 1),
            Vec2.new(1, -1),
            Vec2.new(-1, 1),
            Vec2.new(-1, -1),
        ]

        for (offset in offsets_to_check) {
            var x = player_tile.x + offset.x
            var y = player_tile.y + offset.y

            if (__dungeon.grid[x, y] == EnumTile.wall) {

                var tile_pos = __dungeon.get_world_from_tiled_pos(x + 0.5, y + 0.5, 0)
                
                var collision_result = CollisionHandler.box_to_box_only_first_contact(__player.collider, __player.pos, __player.prev_pos, wall_collider, tile_pos, tile_pos)

                if (collision_result == CollisionResult.collider2_bottom) {
                    __player.pos.y = tile_pos.y + __dungeon.tile_size.y/2 + __player.collider.half_size.y + collision_margin
                }
                if (collision_result == CollisionResult.collider2_top) {
                    __player.pos.y = tile_pos.y - __dungeon.tile_size.y/2 - __player.collider.half_size.y - collision_margin
                }
                if (collision_result == CollisionResult.collider2_right) {
                    __player.pos.x = tile_pos.x - __dungeon.tile_size.x/2 - __player.collider.half_size.x - collision_margin
                }
                if (collision_result == CollisionResult.collider2_left) {
                    __player.pos.x = tile_pos.x + __dungeon.tile_size.x/2 + __player.collider.half_size.x + collision_margin
                }
            }
        }

        
    }

    static render_dungeon(i) {
        if (i < 0) {
            System.print("Can't render negative scale dungeons")
            return
        }

        var dungeon_scale = __dungeon.convertion_scale.pow(i)

        var dungeon_pos = Vec2.new(0, 0)
        while (i != 0) {

            var temp_dungeon_scale = __dungeon.convertion_scale.pow(i)
            var temp_prev_dungeon_scale = __dungeon.convertion_scale.pow(i - 1)

            dungeon_pos = dungeon_pos - (__dungeon.dungeon_exit_point * temp_prev_dungeon_scale) + (__dungeon.dungeon_entrance_point * temp_dungeon_scale)

            i = i - 1
        }

        var render_empty = Data.getBool("Render empty", Data.game)
        var tile_render_scale = __camera.apply_scale(dungeon_scale)

        for (x in 0..__dungeon.grid.width - 1) {
            var render_pos_x = __camera.apply_translation(dungeon_pos + Vec2.new(x * __dungeon.tile_size.x * dungeon_scale, 0)).x

            if (render_pos_x > -__screen_resolution.x/2 - tile_render_scale*__dungeon.tile_size.x &&
                render_pos_x < __screen_resolution.x/2) {
                
                for (y in 0..__dungeon.grid.height - 1) {

                    var render_pos_y = __camera.apply_translation(dungeon_pos + Vec2.new(0, y * __dungeon.tile_size.y * dungeon_scale)).y

                    if (render_pos_y > -__screen_resolution.y/2 - tile_render_scale*__dungeon.tile_size.y &&
                        render_pos_y < __screen_resolution.y/2) {

                        if (__dungeon.grid[x, y] != EnumTile.empty || render_empty) {
                            var sprite_info = __sprite_list[__dungeon.grid[x, y]]
                            Render.sprite(sprite_info.sprite, render_pos_x, render_pos_y, 0, tile_render_scale, 0.0, sprite_info.mul, sprite_info.add, Render.spriteNone)
                        }
                    }
                }
            }
        }
    }
}