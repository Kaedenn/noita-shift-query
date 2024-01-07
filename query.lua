--[[
-- Shift Query mod core logic
--]]

dofile("mods/shift_query/common.lua")
dofile("mods/shift_query/materials.lua")

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

-- Determine the numbered shift, where 0 is the first shift
function sq_get_abs(iter)
    SetRandomSeed(89346, 42345+iter)
    local rnd = random_create(9123, 58925+iter)
    local mat_from = pick_random_from_table_weighted(rnd, MATERIALS_FROM)
    local mat_to = pick_random_from_table_weighted(rnd, MATERIALS_TO)

    mat_from.flask = false
    mat_to.flask = false
    if random_nexti(rnd, 1, 100) <= 75 then -- 75% to use a flask
        if random_nexti(rnd, 1, 100) <= 50 then -- 50% which side gets it
            mat_from.flask = true
        else
            mat_to.flask = true
        end
    end

    return {from=mat_from, to=mat_to}
end

-- vim: set ts=2 sts=2 sw=2:
