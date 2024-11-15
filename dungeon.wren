import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math
import "random" for Random
import "camera" for Camera
import "enums" for EnumTile


class DungeonRoom {
    construct new(corner_pos, size) {
        _corner_pos = corner_pos
        _center_pos = corner_pos + (size / 2)
        _connections = []
        _size = size
        _was_reached_by_walker = false
    }

    pos { _center_pos }
    corner_pos { _corner_pos }
    size { _size }
    connections { _connections }
    connections=(v) { _connections = v}

    
    was_reached_by_walker { _was_reached_by_walker }
    was_reached_by_walker=(v) { _was_reached_by_walker = v}
}

class Walker {
    
    construct new(position, direction, random) {
        _position = position
        _direction = direction
        _random = random

        __directions = [
            Vec2.new(1, 0),
            Vec2.new(0, 1),
            Vec2.new(-1, 0),
            Vec2.new(0, -1)
        ]

        _step_history = []
        _step_history.add(position)
    }

    direction { _direction }
    direction=(d) { _direction = d }
    position { _position }
    position=(p) { _position = p }
    step_history { _step_history }

    make_step() {
        _position = _position + __directions[_direction]
        _step_history.add(_position)
        return _position
    }

    change_direction() {
        _direction = Math.mod(_direction + _random.float(-1.0, 1.0).round, __directions.count)
    }
}

class Grid {
    construct new(width, height, fill_value) {
        //_grid = []
        _width = width
        _height = height

        _grid = List.filled(_width * _height, fill_value)
    }

    /// The number of columns in the grid.
    width { _width }

    /// The number of rows in the grid.
    height { _height }

    coords_are_valid(x, y) {
        if (x >= width || y >= height || x < 0 || y < 0) {
            return false
        } else {
            return true
        }
    }

    /// Returns the value stored at the given grid cell.    
    [x, y] {
        if (x >= width || y >= height || x < 0 || y < 0) {
            System.print("Provided coordinates are not valid, ERROR!!!")
            return null
        } else {
            return _grid[x + y * _width]
        }
    }

    /// Assigns a given value to a given grid cell.    
    [x, y]=(v) {
        if (x >= width || y >= height || x < 0 || y < 0) {
            System.print("Provided coordinates are not valid, ERROR!!!")
            return
        } else { 
            _grid[x + y * _width] = v
        }
    }
}


class DungeonFractalElement {
    // Entrance and Exit poins should be provided in grid's dimension; for example:
    // (0, 0) - left bottom corner of whole grid
    // (0.5, 0.5) - center of left bottom tile
    construct new(convertion_scale, dungeon_size_x, dungeon_size_y, random) {

        _convertion_scale = convertion_scale

        _tile_size = Vec2.new(Data.getNumber("Tile width", Data.game), Data.getNumber("Tile height", Data.game))

        _npc_spawn_tiles = []
        _player_spawn_tile = Vec2.new(0, 0)
        _grid = generate_dungeon_grid(dungeon_size_x, dungeon_size_y, random)

        _size = Vec2.new(_grid.width * _tile_size.x, _grid.height * _tile_size.y)
    }

    generate_dungeon_grid(dungeon_size_x, dungeon_size_y, random) {

        var grid = Grid.new(dungeon_size_x, dungeon_size_y, EnumTile.empty)

        var walker_turn_probability = Data.getNumber("Turn probability", Data.game)
        var room_spawn_probabilility = Data.getNumber("Room spawn probability", Data.game)
        var min_room_spawn_distance = Data.getNumber("Min room spawn distance", Data.game)
        var min_room_size = Data.getNumber("Min room size", Data.game).floor
        var max_room_size = Data.getNumber("Max room size", Data.game).floor + 1

        var space_partition_horizontally = Data.getNumber("Horizontal dungeon partition", Data.game)
        var space_partition_vertically = Data.getNumber("Vertical dungeon partition", Data.game)

        var spawn_padding = Data.getNumber("Spawn padding restriction rule", Data.game).round


        var space_partition_part_width  = (dungeon_size_x - 2*spawn_padding) / space_partition_vertically
        var space_partition_part_height = (dungeon_size_y - 2*spawn_padding) / space_partition_horizontally

        var rooms = []

        // separate the whole dungeon into parts and spawn a room in every part
        for (i in 0..space_partition_vertically - 1) {
            for (j in 0..space_partition_horizontally - 1) {
                var room_x = random.int(space_partition_part_width  * i, space_partition_part_width  * (i+1)).round + spawn_padding
                var room_y = random.int(space_partition_part_height * j, space_partition_part_height * (j+1)).round + spawn_padding

                
                var room_size = Vec2.new(random.int(min_room_size, max_room_size), random.int(min_room_size, max_room_size))
                var room_corner_pos = Vec2.new(
                    Math.min(room_x, dungeon_size_x - spawn_padding - room_size.x),
                    Math.min(room_y, dungeon_size_y - spawn_padding - room_size.y)
                )

                rooms.add(DungeonRoom.new(room_corner_pos, room_size))
            }
        }

        // mark grid tiles that are a room tiles
        for (room in rooms) {
            for (x in 0..room.size.x - 1) {
                for (y in 0..room.size.y - 1) {
                    grid[room.corner_pos.x + x, room.corner_pos.y + y] = EnumTile.floor2
                }
            }

            // Looking for NPC potential spawn positions
            var number_of_npcs_to_spawn = Data.getNumber("NPC spawnrate", Data.game) * room.size.x * room.size.y

            for (i in 1..number_of_npcs_to_spawn) {

                var npc_spawn_found = false
                while(!npc_spawn_found) {
                    var potential_spawn_tile = room.corner_pos + Vec2.new(random.int(0, room.size.x), random.int(0, room.size.y))

                    var npc_cant_spawn_here = false
                    for (spawn_tile in _npc_spawn_tiles) {

                        if (spawn_tile == potential_spawn_tile) {
                            npc_cant_spawn_here = true
                        }
                    }

                    if (!npc_cant_spawn_here) {
                        _npc_spawn_tiles.add(potential_spawn_tile)
                        npc_spawn_found = true
                    }
                }
            }
        }


        var walker_walked_tiles = []

        var walker_walked_in_rooms_ids = []
        var room_start_id = random.int(0, rooms.count)
        walker_walked_in_rooms_ids.add(room_start_id)

        rooms[room_start_id].was_reached_by_walker = true
        _player_spawn_tile = Vec2.new(
            random.int(rooms[room_start_id].corner_pos.x, rooms[room_start_id].corner_pos.x + rooms[room_start_id].size.x),
            random.int(rooms[room_start_id].corner_pos.y, rooms[room_start_id].corner_pos.y + rooms[room_start_id].size.y)
        )


        // a pre last room will connect the last room, so no more rooms to connect when the last room will be reached in the loop
        for(i in 0..rooms.count-2) {
            var room_id = walker_walked_in_rooms_ids[i]
            var room = rooms[room_id]
            var walker_spawn_pos = Vec2.new(room.pos.x.floor, room.pos.y.floor)

            var walker = Walker.new(walker_spawn_pos, random.int(0, 4), random)

            var walker_reached_new_room = false

            var walker_tile = walker_spawn_pos

            while (!walker_reached_new_room) {

                var walker_reached_dungeon_border = walker_tile.x <= spawn_padding || walker_tile.y <= spawn_padding || walker_tile.x == dungeon_size_x - spawn_padding - 1 || walker_tile.y == dungeon_size_y - spawn_padding - 1
                if (walker_reached_dungeon_border) {
                    //spawn another walker from the room
                    walker = Walker.new(walker_spawn_pos, random.int(0, 4), random)
                }

                if (random.float(0.0, 1.0) < walker_turn_probability) {
                    walker.change_direction()
                }

                
                walker_tile = walker.make_step()


                var walker_hit_room_tile = EnumTile.is_floor(grid[walker_tile.x, walker_tile.y])
                if (walker_hit_room_tile) {

                    var closest_room_id = room_id
                    var closest_distance_to_the_room = (rooms[room_id].pos - walker_tile).magnitude

                    for (j in 0..rooms.count - 1) {
                        
                        var distance_to_the_room = (rooms[j].pos - walker_tile).magnitude

                        if (distance_to_the_room < closest_distance_to_the_room) {
                            closest_room_id = j
                            closest_distance_to_the_room = distance_to_the_room
                        }
                    }

                    var another_walker_reached_this_room = rooms[closest_room_id].was_reached_by_walker
                    if (!another_walker_reached_this_room) {

                        walker_walked_in_rooms_ids.add(closest_room_id)
                        rooms[closest_room_id].was_reached_by_walker = true
                        walker_reached_new_room = true
                    }
                }
            }

            // get last walker's result
            walker_walked_tiles = walker_walked_tiles + walker.step_history
        }

        for (tile in walker_walked_tiles) {
            if (grid[tile.x, tile.y] == EnumTile.empty) {
                grid[tile.x, tile.y] = EnumTile.floor1
            }
        }



        var start_room = rooms[random.int(0, space_partition_horizontally)]
        var end_room = rooms[rooms.count - random.int(0, space_partition_horizontally) - 1]

        var dungeon_entrance_tile = Vec2.new(0, start_room.pos.y.floor)
        var dungeon_exit_tile = Vec2.new(dungeon_size_x, end_room.pos.y.floor)

        _dungeon_entrance_point = Vec2.new(dungeon_entrance_tile.x * _tile_size.x, (dungeon_entrance_tile.y + 0.5) * _tile_size.y)
        _dungeon_exit_point = Vec2.new(dungeon_exit_tile.x * _tile_size.x, (dungeon_exit_tile.y + 0.5) * _tile_size.y)

        for (x in 0..(start_room.corner_pos.x-1)) {

            if (EnumTile.is_floor(grid[x, dungeon_entrance_tile.y])) continue

            grid[x, dungeon_entrance_tile.y] = EnumTile.floor1
        }

        for (x in (end_room.corner_pos.x + end_room.size.x)..(dungeon_size_x-1)) {

            if (EnumTile.is_floor(grid[x, dungeon_exit_tile.y])) continue

            grid[x, dungeon_exit_tile.y] = EnumTile.floor1
        }

        

        // Generating walls around
        for (x in 0...dungeon_size_x) {
            for (y in 0...dungeon_size_y) {

                if (grid[x, y] != EnumTile.empty) continue

                if (grid.coords_are_valid(x-1, y)) {
                    if (EnumTile.is_floor(grid[x - 1, y])) {
                        grid[x, y] = EnumTile.wall
                    }
                }
                
                if (grid.coords_are_valid(x+1, y)) {
                    if (EnumTile.is_floor(grid[x + 1, y])) {
                        grid[x, y] = EnumTile.wall
                    }
                }
                
                
                if (grid.coords_are_valid(x, y-1)) {
                    if (EnumTile.is_floor(grid[x, y - 1])) {
                        grid[x, y] = EnumTile.wall
                    }
                }


                if (grid.coords_are_valid(x, y+1)) {
                    if (EnumTile.is_floor(grid[x, y + 1])) {
                        grid[x, y] = EnumTile.wall
                    }
                }
            }
        }

        // Deleting single walls
        for (x in 1...grid.width - 1) {
            for (y in 1...grid.height - 1) {

                if (grid[x, y] == EnumTile.wall) {
                    if (EnumTile.is_floor(grid[x - 1, y]) && 
                        EnumTile.is_floor(grid[x + 1, y]) &&
                        EnumTile.is_floor(grid[x, y - 1]) &&
                        EnumTile.is_floor(grid[x, y + 1])) {

                        grid[x, y] = EnumTile.floor1
                    }
                }
            }
        }

        return grid
    }



    size { _size }
    convertion_scale { _convertion_scale }
    dungeon_entrance_point { _dungeon_entrance_point }
    dungeon_exit_point { _dungeon_exit_point }
    tile_size { _tile_size }

    grid { _grid }
    npc_spawn_tiles { _npc_spawn_tiles }
    player_spawn_tile { _player_spawn_tile }


    get_world_from_tiled_pos(grid_x, grid_y, dungeon_level) {

        var i = dungeon_level

        if (i < 0) {
            System.print("Can't get negative scale dungeons")
            return
        }

        var world_pos = Vec2.new(0, 0)
        var dungeon_scale = convertion_scale.pow(dungeon_level)

        world_pos.x = world_pos.x + (grid_x * _tile_size.x * dungeon_scale)
        world_pos.y = world_pos.y + (grid_y * _tile_size.y * dungeon_scale)

        while (i != 0) {

            i = i - 1
            var temp_dungeon_scale = convertion_scale.pow(i)

            world_pos.x = world_pos.x + (dungeon_exit_point - dungeon_entrance_point).x * temp_dungeon_scale
            world_pos.y = world_pos.y + (dungeon_exit_point - dungeon_entrance_point).y * temp_dungeon_scale

        }

        world_pos.y = world_pos.y - dungeon_entrance_point.y * convertion_scale.pow(dungeon_level)
        world_pos.y = world_pos.y + dungeon_entrance_point.y * convertion_scale.pow(0)

        return -world_pos
    }


    get_tiled_from_world_pos(world_pos, dungeon_level) {

        var i = dungeon_level

        if (i < 0) {
            System.print("Can't get negative scale dungeons")
            return
        }

        world_pos = -world_pos

        while (i != 0) {
            i = i - 1

            var temp_dungeon_scale = convertion_scale.pow(i)

            world_pos = world_pos - (dungeon_exit_point - dungeon_entrance_point) * temp_dungeon_scale
        }

        world_pos.y = world_pos.y + dungeon_entrance_point.y * convertion_scale.pow(dungeon_level)
        world_pos.y = world_pos.y - dungeon_entrance_point.y * convertion_scale.pow(0)

        var dungeon_scale = convertion_scale.pow(dungeon_level)
        var tile_pos = Vec2.new(world_pos.x / tile_size.x, world_pos.y / tile_size.y) / dungeon_scale

        return tile_pos
    }
}