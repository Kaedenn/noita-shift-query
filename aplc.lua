--[[
-- Determine the current Alchemic Precursor / Lively Concoction recipes.
--
-- Note that this depends on the game's material tables matching the
-- material tables below. If either of those change, this file will no
-- longer give correct results.
--
-- Unfortunately, and unlike the fungal shift material tables, Noita
-- does not expose the material tables in any accessible way. Therefore,
-- the materials must be specified here.
--]]

--[[ Example use:
--  local APLC = dofile("mods/shift_query/aplc.lua")
--  function get_aplc_data()
--      local lc_combo, ap_combo, lc_prob, ap_prob = APLC.get_recipe()
--      local ap_str = ("AP: %s, %s, %s (%.02f%%)"):format(
--          ap_combo[1], ap_combo[2], ap_combo[3], ap_prob)
--      local lc_str = ("LC: %s, %s, %s (%.02f%%)"):format(
--          lc_combo[1], lc_combo[2], lc_combo[3], lc_prob)
--      GamePrint(ap_str)
--      GamePrint(lc_str)
--  end
--]]

--[[ Flask contents. Order is important!! ]]
local LIQUIDS = {
    "acid",
    "alcohol",
    "blood",
    "blood_fungi",
    "blood_worm",
    "cement",
    "lava",
    "magic_liquid_berserk",
    "magic_liquid_charm",
    "magic_liquid_faster_levitation",
    "magic_liquid_faster_levitation_and_movement",
    "magic_liquid_invisibility",
    "magic_liquid_mana_regeneration",
    "magic_liquid_movement_faster",
    "magic_liquid_protection_all",
    "magic_liquid_teleportation",
    "magic_liquid_unstable_polymorph",
    "magic_liquid_unstable_teleportation",
    "magic_liquid_worm_attractor",
    "material_confusion",
    "mud",
    "oil",
    "poison",
    "radioactive_liquid",
    "swamp",
    "urine"  ,
    "water",
    "water_ice",
    "water_swamp",
    "magic_liquid_random_polymorph"
}

--[[ Pouch contents. Order is important!! ]]
local ORGANICS = {
    "bone",
    "brass",
    "coal",
    "copper",
    "diamond",
    "fungi",
    "gold",
    "grass",
    "gunpowder",
    "gunpowder_explosive",
    "rotten_meat",
    "sand",
    "silver",
    "slime",
    "snow",
    "soil",
    "wax",
    "honey"
}

--[[ Advance the RNG iteration state ]]
function rand_advance(rvalue)
    local high = math.floor(rvalue / 127773.0)
    local low = rvalue % 127773
    rvalue = 16807 * low - 2836 * high
    if rvalue <= 0 then
        rvalue = rvalue + 2147483647
    end
    return rvalue
end

--[[ Shuffle a sequence in-place ]]
function shuffle(sequence, seed)
    local val = math.floor(seed / 2) + 0x30f6
    val = rand_advance(val)
    for idx = #sequence, 1, -1 do
        val = rand_advance(val)
        local fidx = val / 2^31
        local target = math.floor(fidx * idx) + 1
        sequence[idx], sequence[target] = sequence[target], sequence[idx]
    end
end

--[[ Get a copy of the LIQUIDS table ]]
function get_liquids()
    local liquids = {}
    for idx, mat in ipairs(LIQUIDS) do
        liquids[idx] = mat
    end
    return liquids
end

--[[ Get a copy of the ORGANICS table ]]
function get_organics()
    local organics = {}
    for idx, mat in ipairs(ORGANICS) do
        organics[idx] = mat
    end
    return organics
end

--[[ Pick the next material according to the RNG ]]
function aplc_random_pick(rstate, materials)
    for _ = 1, 1000 do
        rstate = rand_advance(rstate)
        local rval = rstate / 2^31
        local sel_idx = math.floor(#materials * rval) + 1
        local selection = materials[sel_idx]
        if selection then
            materials[sel_idx] = false
            return rstate, selection
        end
    end
    error("Failed to pick AP/LC; broken material table?")
end

--[[ Get either the AP or LC recipe and probability ]]
function aplc_random_set(rstate, seed)
    local liquids = get_liquids()
    local organics = get_organics()
    local m1, m2, m3, m4 = "?", "?", "?", "?"
    rstate, m1 = aplc_random_pick(rstate, liquids)
    rstate, m2 = aplc_random_pick(rstate, liquids)
    rstate, m3 = aplc_random_pick(rstate, liquids)
    rstate, m4 = aplc_random_pick(rstate, organics)
    local combo = {m1, m2, m3, m4}

    rstate = rand_advance(rstate)
    local prob = 10 + math.floor((rstate / 2^31) * 91)
    rstate = rand_advance(rstate)

    shuffle(combo, seed)
    return rstate, {combo[1], combo[2], combo[3]}, prob
end

--[[ Get the AP / LC materials and probabilities ]]
function aplc_get()
    -- Set the random number generator to a specific state
    local seed = tonumber(StatsGetValue("world_seed"))
    local rstate = math.floor(seed * 0.17127000 + 1323.59030000)
    for i = 1, 6 do rstate = rand_advance(rstate) end

    -- Determine first the LC information, then the AP information
    local lc_combo, lc_prob
    local ap_combo, ap_prob
    rstate, lc_combo, lc_prob = aplc_random_set(rstate, seed)
    rstate, ap_combo, ap_prob = aplc_random_set(rstate, seed)

    return lc_combo, ap_combo, lc_prob, ap_prob
end

return {
    LIQUIDS = LIQUIDS,
    ORGANICS = ORGANICS,
    get_liquids = get_liquids,
    get_organics = get_organics,
    random_pick = aplc_random_pick,
    random_set = aplc_random_set,
    get_recipe = aplc_get,
}

-- vim: set ts=4 sts=4 sw=4 tw=79:
