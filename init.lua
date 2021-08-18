randomizer = {}

local id = minetest.get_content_id

local function allowed_node(node, def)
    local allowed =  node ~= "" and node ~= "air" and node ~= "ignore" and node ~= "unknown" 
    and def and def.description and def.description ~= ""
    and not string.match(node, "stair") and not string.match(node, "slab")
    and not string.match(node, "fence") and not string.match(node, "bed")
    and not string.match(node, "door") and def.light_source == 0
    and def.groups.not_in_creative_inventory ~= 1
    and node ~= "mcl_core:bedrock" and node ~= "default:water_source"
    and node ~= "default:water_flowing" and node ~= "default:river_water_source"
    and node ~= "default:river_water_flowing" and node ~= "default:lava_source"
    and node ~= "default:lava_flowing" and node ~= "mcl_core:water_source"
    and node ~= "mcl_core:water_flowing" and node ~= "mcl_core:lava_source"
    and node ~= "mcl_core:lava_flowing" and node ~= "mcl_mobspawners:spawner"
    return allowed
end

minetest.register_on_mods_loaded(function()
    for node, def in pairs(minetest.registered_nodes) do
        if allowed_node(node, def) then
            table.insert(randomizer, node)
        end
    end
    for _, node in pairs(randomizer) do
        -- this is faster then check for all nodes in the randomizer list
        -- in a loop in the minetest.register_on_generated function
        minetest.override_item(node, {
            randomizer = randomizer[math.random(#randomizer)]
        })
    end
end)

local data = {}

minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{ MinEdge = emin, MaxEdge = emax }
	vm:get_data(data)
    local data = vm:get_data()
    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do
                local vi = area:index(x, y, z)
                local node_name = minetest.get_name_from_content_id(data[vi])
                local node_def = minetest.registered_nodes[node_name]
                if node_def.randomizer then
                    data[vi] = minetest.get_content_id(node_def.randomizer)
                end
            end
        end
    end
    vm:set_data(data)
    vm:write_to_map(true)
end)