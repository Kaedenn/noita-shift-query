--[[
-- Shift Query core logic
--
-- Nomenclature used below:
--
-- shift-info: table
--  flask: boolean
--  materials: {string...}
--  name_material: string (optional)
--]]

-- luacheck: globals pick_random_from_table_weighted random_nexti random_create
-- luacheck: globals random_from_array
-- luacheck: globals CUTOFF_RARE

dofile("mods/shift_query/files/common.lua")
matinfo = dofile("mods/shift_query/files/materials.lua")

MAX_SHIFTS = 20     -- maximum number of shifts according to fungal_shift.lua
COOLDOWN = 60*60*5  -- post shift cooldown; five minutes

-- Get the current shift iteration
function get_curr_iter()
    return tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
end

-- Get the number of frames since the previous shift; -1 if none
function get_last_shift_frame()
    return tonumber(GlobalsGetValue("fungal_shift_last_frame", "-1"))
end

-- Get the pending cooldown in seconds; 0 if none or done
function get_cooldown_sec()
    local last_frame = get_last_shift_frame()
    if last_frame == -1 then return 0 end

    local frame = GameGetFrameNum()
    return (COOLDOWN - (frame - last_frame)) / 60
end

--[[ Determine the numbered shift, where 0 is the first shift
--
-- @param iter number
-- @returns table:{from=shift-info, to=shift-info}
--]]
function sq_get_abs(iter)
    local mats_from = matinfo.get_materials_from()
    local mats_to = matinfo.get_materials_to()
    local greedy_mats = matinfo.get_greedy_materials()

    local mat_from = {}
    local mat_to = {}

    local converted_any = false
    local convert_tries = 0
    while converted_any == false and convert_tries < 20 do
        local seed2 = 42345 + iter + 1000*convert_tries
        SetRandomSeed( 89346, seed2 )
        local rnd = random_create( 9123, seed2 )
        local from = pick_random_from_table_weighted( rnd, mats_from )
        local to = pick_random_from_table_weighted( rnd, mats_to )

        mat_from = {
            flask = false,
            probability = from.probability,
            materials = from.materials,
            name_material = from.name_material or nil
        }
        mat_to = {
            flask = false,
            probability = to.probability,
            material = to.material,
            greedy_mat = nil,
            grass_holy = "grass"
        }

        if random_nexti( rnd, 1, 100 ) <= 75 then -- 75% chance to use flask
            if random_nexti( rnd, 1, 100 ) <= 50 then -- 50% chance which side gets it
                mat_from.flask = true
            else
                mat_to.flask = true

                -- 0.1% chance for gold/grass_holy shifts to work
                if random_nexti( rnd, 1, 1000 ) ~= 1 then
                    mat_to.greedy_mat = random_from_array( greedy_mats )
                    mat_to.grass_holy = "grass"
                else
                    mat_to.greedy_mat = "gold"
                    mat_to.grass_holy = "grass_holy"
                end
            end
        end

        -- Does this attempt work? (NOTE: ignores flasks)
        for _, mat in ipairs(mat_from.materials) do
            local from_mat = CellFactory_GetType(mat)
            local to_mat = CellFactory_GetType(mat_to.material)
            if from_mat ~= to_mat then
                converted_any = true
            end
        end

        convert_tries = convert_tries + 1
    end

    if not converted_any then
        GamePrint(("shift_query - shift %d failed outright"):format(iter))
    end
    return {from=mat_from, to=mat_to}

    --[[SetRandomSeed(89346, 42345+iter)
    local rnd = random_create(9123, 58925+iter)

    local mat_from = pick_random_from_table_weighted(rnd, mats_from)
    local mat_to = pick_random_from_table_weighted(rnd, mats_to)

    mat_from.flask = false
    mat_to.flask = false
    if random_nexti(rnd, 1, 100) <= 75 then -- 75% to use a flask
        if random_nexti(rnd, 1, 100) <= 50 then -- 50% which side gets it
            mat_from.flask = true
        else
            mat_to.flask = true
        end
    end

    return {from=mat_from, to=mat_to}]]
end

--[[ Determine if the shift uses a "rare" material
--
-- @param shift_pair:table {from=shift-info, to=shift-info}
-- @returns rare_from:boolean, rare_to:boolean
--]]
function sq_is_rare_shift(shift_pair, cutoff)
    if type(cutoff) ~= "number" then cutoff = CUTOFF_RARE end
    local mats_from = shift_pair.from
    local mat_to = shift_pair.to
    local rare_from, rare_to = false, false

    for _, material in ipairs(mats_from) do
        if matinfo.is_rare_source(material, cutoff) then
            rare_from = true
        end
    end

    if matinfo.is_rare_target(mat_to.material, cutoff) then
        rare_to = true
    end

    return rare_from, rare_to
end

-- vim: set ts=4 sts=4 sw=4:
