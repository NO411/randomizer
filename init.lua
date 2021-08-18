randomizer = {
    -- distinguish between nodes that can be replaced and nodes that CAN replace something
    -- some node drawtypes cause low fps (e.g. plantlikes)
    can_be_replaced = {},
    can_replace = {},
}

local id = minetest.get_content_id

local function can_be_replaced(node, def)
    local allowed = node ~= "mcl_core:bedrock" and node ~= "air" and node ~= "mcl_mobspawners:spawner"
    and def.drawtype ~= "liquid" and def.drawtype ~= "flowingliquid"
    return allowed
end

local function can_replace(node, def)
    local allowed = def.drawtype == "normal" and def.groups.not_in_creative_inventory ~= 1
    return allowed
end

minetest.register_on_mods_loaded(function()
    for node, def in pairs(minetest.registered_nodes) do
        if can_be_replaced(node, def) then
            table.insert(randomizer.can_be_replaced, node)
        end
        if can_replace(node, def) then
            table.insert(randomizer.can_replace, node)
        end
    end
    for _, node in pairs(randomizer.can_be_replaced) do
        -- this is faster then check for all nodes in the randomizer list
        -- in a loop in the minetest.register_on_generated function
        minetest.override_item(node, {
            randomizer = randomizer.can_replace[math.random(#randomizer.can_replace)]
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
