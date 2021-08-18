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
    local groups = def.groups
    local allowed = def.drawtype == "normal" and groups.not_in_creative_inventory ~= 1 and groups.falling_node ~= 1
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
end)

local rando_lookup
local function get_lookup()
    if rando_lookup then
        return rando_lookup
    end
    rando_lookup = {}
    for k in pairs(minetest.registered_nodes) do
        local i = minetest.get_content_id(k)
        rando_lookup[i] = i
    end
    local seed = minetest.get_perlin(0, 1, 0, 1):get_3d({ x = 0, y = 0, z = 0 })
    seed = math.floor((seed - math.floor(seed)) * 2 ^ 32 - 2 ^ 31)
    local pcg = PcgRandom(seed)
    for _, node in pairs(randomizer.can_be_replaced) do
        rando_lookup[minetest.get_content_id(node)] = minetest.get_content_id(
            randomizer.can_replace[pcg:next(1, #randomizer.can_replace)])
    end
    return rando_lookup
end

minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{ MinEdge = emin, MaxEdge = emax }
	local data = vm:get_data()
    local rando_lookup = get_lookup()
    for i in area:iterp(minp, maxp) do
        data[i] = rando_lookup[data[i]]
    end
    vm:set_data(data)
    vm:write_to_map(true)
end)
