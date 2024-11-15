System.print("Wren just got compiled to bytecode")

import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math, Color
import "random" for Random
import "camera" for Camera
import "characters" for Player, Zombie
import "dungeon" for DungeonFractalElement, Grid
import "modded_sprite" for ModdedSprite
import "enums" for EnumTile, PlayerState, ZombieState
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

        __dungeon = DungeonFractalElement.new(1.2, dungeon_width, dungeon_height, __random)

        init_life(tile_set_image, tile_set_columns, tile_set_rows)

        __screen_resolution = Vec2.new(Data.getNumber("Width", Data.system), Data.getNumber("Height", Data.system))

        __font = Render.loadFont("[game]/assets/FutilePro.ttf", 28)
        __ui_background = Render.createGridSprite(tile_set_image, tile_set_columns, tile_set_rows, 8, 5)

        __max_dungeon_level_reached = 0

        calculate_dungeon_colliders(0)
    }    

    static update(dt) {

        update_variables(dt)
        handle_input(dt)
        update_characters(dt)
        handle_collisions_with_geometry(dt)
        update_present_dungeon_level()

        __camera.pos = Math.lerp(__camera.pos, __player.pos, dt * Data.getNumber("Camera attachment force", Data.game))
        __camera.scale = __player.scale * Data.getNumber("Relative camera scale", Data.game)
    }

    static render() {

        if (__player.dungeon_level != 0) {
            render_dungeon(__player.dungeon_level - 1)
        }
        render_dungeon(__player.dungeon_level)
        render_dungeon(__player.dungeon_level + 1)
        render_life()
        render_ui()


        if (Data.getBool("Draw colliders", Data.game)) {
            CollisionHandler.draw_colliders(__camera)
        }
    }

    static update_variables(dt) {
        __player.state = PlayerState.no_attack

        __player.prev_pos = Vec2.new(__player.pos.x, __player.pos.y)

        for(zombie in __zombies) {
            zombie.prev_pos = Vec2.new(zombie.pos.x, zombie.pos.y)

            if (zombie.state == ZombieState.on_cooldown) {
                zombie.cooldown = zombie.cooldown - dt

                if (zombie.cooldown <= 0.0) {
                    zombie.state = ZombieState.hanging_around
                }
            }
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

        // Mouse1
        if (Input.getMouseButtonOnce(Input.mouseButtonLeft)) {
            __player.state = PlayerState.attack
        }
    }

    static handle_collisions_with_geometry(dt) {
        var collision_margin = Data.getNumber("Collision margin", Data.game)


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

        for (dungeon_lvl in (__player.dungeon_level-1)..(__player.dungeon_level+1)) {

            if (dungeon_lvl < 0) continue

            var player_tile = __dungeon.get_tiled_from_world_pos(__player.pos, dungeon_lvl)

            player_tile = Vec2.new(player_tile.x.floor, player_tile.y.floor)

            var wall_collider = BoxCollider.new(__dungeon.tile_size.x * __dungeon.convertion_scale.pow(dungeon_lvl), __dungeon.tile_size.y * __dungeon.convertion_scale.pow(dungeon_lvl))

            for (offset in offsets_to_check) {
                var x = player_tile.x + offset.x
                var y = player_tile.y + offset.y

                if(!__dungeon.grid.coords_are_valid(x, y)) continue

                if (__dungeon.grid[x, y] == EnumTile.wall) {

                    var tile_pos = __dungeon.get_world_from_tiled_pos(x + 0.5, y + 0.5, dungeon_lvl)
                    
                    var collision_result = CollisionHandler.box_to_box_only_first_contact(__player.collider, __player.pos, __player.prev_pos, wall_collider, tile_pos, tile_pos)

                    if (collision_result == CollisionResult.collider2_bottom) {
                        __player.pos.y = tile_pos.y + wall_collider.half_size.y + __player.collider.half_size.y + collision_margin
                    }
                    if (collision_result == CollisionResult.collider2_top) {
                        __player.pos.y = tile_pos.y - wall_collider.half_size.y - __player.collider.half_size.y - collision_margin
                    }
                    if (collision_result == CollisionResult.collider2_right) {
                        __player.pos.x = tile_pos.x - wall_collider.half_size.x - __player.collider.half_size.x - collision_margin
                    }
                    if (collision_result == CollisionResult.collider2_left) {
                        __player.pos.x = tile_pos.x + wall_collider.half_size.y + __player.collider.half_size.x + collision_margin
                    }
                }
            }

            for (zombie in __zombies) {

                if (!zombie.is_alive) continue

                var zombie_tile = __dungeon.get_tiled_from_world_pos(zombie.pos, dungeon_lvl)

                zombie_tile = Vec2.new(zombie_tile.x.floor, zombie_tile.y.floor)


                for (offset in offsets_to_check) {
                    var x = zombie_tile.x + offset.x
                    var y = zombie_tile.y + offset.y

                    if(!__dungeon.grid.coords_are_valid(x, y)) continue

                    var wall_collider = BoxCollider.new(__dungeon.tile_size.x * __dungeon.convertion_scale.pow(dungeon_lvl), __dungeon.tile_size.y * __dungeon.convertion_scale.pow(dungeon_lvl))

                    if (__dungeon.grid[x, y] == EnumTile.wall) {

                        var tile_pos = __dungeon.get_world_from_tiled_pos(x + 0.5, y + 0.5, dungeon_lvl)
                        
                        var collision_result = CollisionHandler.box_to_box_only_first_contact(zombie.collider, zombie.pos, zombie.prev_pos, wall_collider, tile_pos, tile_pos)

                        if (collision_result == CollisionResult.collider2_bottom) {
                            zombie.pos.y = tile_pos.y + wall_collider.half_size.y + zombie.collider.half_size.y + collision_margin
                        }
                        if (collision_result == CollisionResult.collider2_top) {
                            zombie.pos.y = tile_pos.y - wall_collider.half_size.y - zombie.collider.half_size.y - collision_margin
                        }
                        if (collision_result == CollisionResult.collider2_right) {
                            zombie.pos.x = tile_pos.x - wall_collider.half_size.y - zombie.collider.half_size.x - collision_margin
                        }
                        if (collision_result == CollisionResult.collider2_left) {
                            zombie.pos.x = tile_pos.x + wall_collider.half_size.y + zombie.collider.half_size.x + collision_margin
                        }
                    }
                }
            }
        }
        
    }

    static update_characters(dt) {

        var zombie_view_distance = Data.getNumber("Zombie view distance", Data.game)
        
        for (zombie in __zombies) {
            if (!zombie.is_alive) continue

            // Zombie attack
            if (CollisionHandler.box_to_box_are_overlapping(__player.collider, __player.pos, zombie.collider, zombie.pos) == CollisionResult.overlap &&
                zombie.state == ZombieState.hanging_around) {
                
                __player.receive_dmg(zombie.dmg)
                zombie.state = ZombieState.on_cooldown
                zombie.cooldown = Data.getNumber("Zombie cooldown attack", Data.game)
            }

            // Approach to the player
            var zombie_to_player_vector = __player.pos - zombie.pos
            if (zombie.state == ZombieState.hanging_around && zombie_to_player_vector.magnitude <= zombie_view_distance) {
                zombie.pos = zombie.pos + zombie_to_player_vector.normal * zombie.speed * dt
            }

            // Damage receive from the player
            if (__player.state == PlayerState.attack && (zombie.pos - __player.pos).magnitude <= 30 * __player.scale) {
                zombie.receive_dmg(__player.dmg)
            }

            // is being killed?
            if (!zombie.is_alive) {
                zombie.sprite_info.mul = Color.new(255, 0, 0).toNum

                __player.speed = __player.speed * Data.getNumber("Reward speed multiplayer", Data.game)
                __player.dmg = __player.dmg * Data.getNumber("Reward damage multiplayer", Data.game)
                __player.scale = __player.scale * Data.getNumber("Reward scale multiplayer", Data.game)
            }
        }
        
        if (__player.hp <= 0) {
            Game.initialize()
        }
    }

    static update_present_dungeon_level() {

        if (__player.dungeon_level == 0) {
            if (CollisionHandler.box_to_box_are_overlapping(__player.collider, __player.pos, __next_dungeon_collider, __next_dungeon_collider_pos) == CollisionResult.overlap) {
                __player.dungeon_level = 1
                calculate_dungeon_colliders(1)
            }
        } else {
            if (CollisionHandler.box_to_box_are_overlapping(__player.collider, __player.pos, __next_dungeon_collider, __next_dungeon_collider_pos) == CollisionResult.overlap) {
                __player.dungeon_level = __player.dungeon_level + 1
                calculate_dungeon_colliders(__player.dungeon_level)
            }

            if (CollisionHandler.box_to_box_are_overlapping(__player.collider, __player.pos, __past_dungeon_collider, __past_dungeon_collider_pos) == CollisionResult.overlap) {
                __player.dungeon_level = __player.dungeon_level - 1
                calculate_dungeon_colliders(__player.dungeon_level)
            }
        }

        if (__player.dungeon_level > __max_dungeon_level_reached) {
            spawn_npcs_on_level(__player.dungeon_level + 1)
            __max_dungeon_level_reached = __player.dungeon_level
        }
    }

    static init_life(sprite_sheet, sprite_sheet_columns, sprite_sheet_rows) {

        __player = Player.new(
            __dungeon.get_world_from_tiled_pos(__dungeon.player_spawn_tile.x + 0.5, __dungeon.player_spawn_tile.y + 0.5, 0),
            1.0,
            Data.getNumber("Player begin speed", Data.game),
            Data.getNumber("Player begin damage", Data.game),
            0,
            BoxCollider.new(Vec2.new(12, 12)),
            ModdedSprite.new(Render.createGridSprite(sprite_sheet, sprite_sheet_columns, sprite_sheet_rows, 26, 0), Color.new(255, 255, 255, 255).toNum, 0x00, Render.spriteCenter)
        )


        Zombie.set_defaults(
            BoxCollider.new(Vec2.new(12, 12)),
            20,
            Data.getNumber("Zombie begin speed", Data.game),
            1.0,
            ModdedSprite.new(Render.createGridSprite(sprite_sheet, sprite_sheet_columns, sprite_sheet_rows, 25, 2), Color.new(255, 255, 255, 255).toNum, 0x00, Render.spriteCenter)
        )

        __zombies = []

        spawn_npcs_on_level(0)
        spawn_npcs_on_level(1)

        var npc_ids_to_remove = []

        for (i in 0..__zombies.count-1) {
            if ((__zombies[i].pos - __player.pos).magnitude <= Data.getNumber("Player spawn protection", Data.game)) {
                npc_ids_to_remove.insert(0, i)
            }
        }

        for (index in npc_ids_to_remove) {
            __zombies.removeAt(index)
        }
    }

    static spawn_npcs_on_level(dungeon_lvl) {
        var npc_scale = __dungeon.convertion_scale.pow(dungeon_lvl)

        for (spawn_tile in __dungeon.npc_spawn_tiles) {

            var new_zombie = Zombie.new(
                __dungeon.get_world_from_tiled_pos(spawn_tile.x + 0.5, spawn_tile.y + 0.5, dungeon_lvl),
                npc_scale
            )

            __zombies.add(new_zombie)
        }
    }

    static calculate_dungeon_colliders(reached_dungeon_level) {
        __next_dungeon_collider = BoxCollider.new(
            __dungeon.size * __dungeon.convertion_scale.pow(reached_dungeon_level + 1)
        )
        __next_dungeon_collider_pos = __dungeon.get_world_from_tiled_pos(__dungeon.grid.width / 2, __dungeon.grid.height / 2, reached_dungeon_level + 1)

        if (reached_dungeon_level == 0) return

        __past_dungeon_collider = BoxCollider.new(
            __dungeon.size * __dungeon.convertion_scale.pow(reached_dungeon_level - 1)
        )
        __past_dungeon_collider_pos = __dungeon.get_world_from_tiled_pos(__dungeon.grid.width / 2, __dungeon.grid.height / 2, reached_dungeon_level - 1)
    }

    static render_dungeon(i) {
        if (i < 0) {
            System.print("Can't render negative scale dungeons")
            return
        }

        var dungeon_scale = __dungeon.convertion_scale.pow(i)

        var dungeon_pos = -__dungeon.get_world_from_tiled_pos(0, 0, i)

        var render_empty = Data.getBool("Render empty", Data.game)
        var tile_render_scale = __camera.apply_scale(dungeon_scale)

        for (x in 0..__dungeon.grid.width - 1) {
            var render_pos_x = __camera.apply_translation(Vec2.new(dungeon_pos.x + x * __dungeon.tile_size.x * dungeon_scale, 0)).x

            if (render_pos_x > -__screen_resolution.x/2 - tile_render_scale*__dungeon.tile_size.x &&
                render_pos_x < __screen_resolution.x/2) {
                
                for (y in 0..__dungeon.grid.height - 1) {

                    var render_pos_y = __camera.apply_translation(Vec2.new(0, dungeon_pos.y + y * __dungeon.tile_size.y * dungeon_scale)).y

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

    static render_life() {

        var player_sprite_info =__player.sprite_info
        var player_render_pos = __camera.apply_translation(-__player.pos)
        var player_render_scale = __camera.apply_scale(1.0)

        // Render player
        Render.sprite(
            player_sprite_info.sprite,
            player_render_pos.x,
            player_render_pos.y,
            1,
            player_render_scale,
            0.0,
            player_sprite_info.mul,
            player_sprite_info.add,
            Render.spriteCenter
        )

        for (zombie in __zombies) {
            var zombie_sprite_info = zombie.sprite_info
            var zombie_render_pos = __camera.apply_translation(-zombie.pos)
            var zombie_render_scale = __camera.apply_scale(zombie.scale)

            if (zombie_render_pos.x > -__screen_resolution.x/2 - zombie_render_scale*__dungeon.tile_size.x &&
                zombie_render_pos.x < __screen_resolution.x/2 &&
                zombie_render_pos.y > -__screen_resolution.y/2 - zombie_render_scale*__dungeon.tile_size.y &&
                zombie_render_pos.y < __screen_resolution.y/2) {
                
                // Render zombies if they are in camera's frustum
                Render.sprite(
                    zombie_sprite_info.sprite,
                    zombie_render_pos.x,
                    zombie_render_pos.y,
                    1,
                    zombie_render_scale,
                    0.0,
                    zombie_sprite_info.mul,
                    zombie_sprite_info.add,
                    Render.spriteCenter
                )
            }            
        }
    }

    static render_ui() {

        var background_height = (Data.getNumber("UI Height", Data.game) * 100 - Data.getNumber("Height", Data.system)) 
        var text_offset = Data.getNumber("UI Text offset", Data.game) * 100

        Render.sprite(__ui_background, 0, background_height, 3, 20, 0, Color.new(75, 75, 75, 220).toNum, 0, Render.spriteCenter)

        var message = "Health: %(__player.hp)"
        Render.text(__font, message, 0, background_height + text_offset, 4.0, 0xFFFFFFFF, 0x0, Render.spriteCenter)
    }
}