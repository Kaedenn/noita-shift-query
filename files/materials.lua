-- Fungal Query materials

--[[ NOTE:
-- While it would be easy just to have
dofile("data/scripts/magic/fungal_shift.lua")
-- and expose those values here; that script (as of Feb 14 2024) crashes Noita
-- if executed during mod initialization. This is because the script attempts
-- to validate the material tables via the CellFactory (CellFactory_GetType)
-- the instant the script is executed. The CellFactory is not initialized by
-- this point and thus the game crashes.
--
-- To work around this, this file provides two solutions:
--  1. Load data/scripts/magic/fungal_shift.lua only when requested, and
--  2. Provide hard-coded material tables if the native ones are unavailable.
--]]

-- The tables below are taken directly from Noita's own fungal_shift.lua
-- script, with some formatting for good measure. Note that changes to
-- Noita's fungal_shift.lua will not be reflected here! Therefore, this
-- mod does *not* support alterations to fungal shift logic or materials.
MATERIALS_FROM_COPY = {
    { probability = 1.0,
      materials = { "water", "water_static", "water_salt", "water_ice" },
      name_material = "water" },
    { probability = 1.0,
      materials = { "lava" } },
    { probability = 1.0,
      materials = { "radioactive_liquid", "poison", "material_darkness" },
      name_material = "radioactive_liquid" },
    { probability = 1.0,
      materials = { "oil", "swamp", "peat" },
      name_material = "oil" },
    { probability = 1.0,
      materials = { "blood" } },
    { probability = 1.0,
      materials = { "blood_fungi", "fungi", "fungisoil" },
      name_material = "fungi" },
    { probability = 1.0,
      materials = { "blood_cold", "blood_worm" } },
    { probability = 1.0,
      materials = { "acid" } },
    { probability = 0.4,
      materials = { "acid_gas", "acid_gas_static", "poison_gas", "fungal_gas",
                    "radioactive_gas", "radioactive_gas_static" },
      name_material = "acid_gas" },
    { probability = 0.4,
      materials = { "magic_liquid_polymorph",
                    "magic_liquid_unstable_polymorph" },
      name_material = "magic_liquid_polymorph" },
    { probability = 0.4,
      materials = { "magic_liquid_berserk", "magic_liquid_charm",
                    "magic_liquid_invisibility" } },
    { probability = 0.6,
      materials = { "diamond" } },
    { probability = 0.6,
      materials = { "silver", "brass", "copper" } },
    { probability = 0.2,
      materials = { "steam", "smoke" } },
    { probability = 0.4,
      materials = { "sand" } },
    { probability = 0.4,
      materials = { "snow_sticky" } },
    { probability = 0.05,
      materials = { "rock_static" } },
    { probability = 0.0003,
      materials = { "gold", "gold_box2d" },
      name_material = "gold" },
}

MATERIALS_TO_COPY = {
    { probability = 1.00, material = "water" },
    { probability = 1.00, material = "lava" },
    { probability = 1.00, material = "radioactive_liquid" },
    { probability = 1.00, material = "oil" },
    { probability = 1.00, material = "blood" },
    { probability = 1.00, material = "blood_fungi" },
    { probability = 1.00, material = "acid" },
    { probability = 1.00, material = "water_swamp" },
    { probability = 1.00, material = "alcohol" },
    { probability = 1.00, material = "sima" },
    { probability = 1.00, material = "blood_worm" },
    { probability = 1.00, material = "poison" },
    { probability = 1.00, material = "vomit" },
    { probability = 1.00, material = "pea_soup" },
    { probability = 1.00, material = "fungi" },
    { probability = 0.80, material = "sand" },
    { probability = 0.80, material = "diamond" },
    { probability = 0.80, material = "silver" },
    { probability = 0.80, material = "steam" },
    { probability = 0.50, material = "rock_static" },
    { probability = 0.50, material = "gunpowder" },
    { probability = 0.50, material = "material_darkness" },
    { probability = 0.50, material = "material_confusion" },
    { probability = 0.20, material = "rock_static_radioactive" },
    { probability = 0.02, material = "magic_liquid_polymorph" },
    { probability = 0.02, material = "magic_liquid_random_polymorph" },
    { probability = 0.15, material = "magic_liquid_teleportation" },
    { probability = 0.01, material = "urine" },
    { probability = 0.01, material = "poo" },
    { probability = 0.01, material = "void_liquid" },
    { probability = 0.01, material = "cheese_static" },
}

function get_material_tables()
    dofile("data/scripts/magic/fungal_shift.lua")
    if materials_from and materials_to then
        return materials_from, materials_to
    end
    GamePrint("shift_query - unable to get material tables; using local versions")
    return MATERIALS_FROM_COPY, MATERIALS_TO_COPY
end

return {
    --[[ Obtain the materials_from table.
    -- This first attempts to determine the table directly from Noita, and then
    -- falls back to the table defined above.
    --]]
    get_materials_from = function()
        local materials_from, materials_to = get_material_tables()
        return materials_from
    end,

    --[[ Obtain the materials_to table.
    -- This first attempts to determine the table directly from Noita, and then
    -- falls back to the table defined above.
    --]]
    get_materials_to = function()
        local materials_from, materials_to = get_material_tables()
        return materials_to
    end,

    --[[ True if the given shift source is considered "rare" ]]
    is_rare_source = function(material, cutoff)
        if type(cutoff) ~= "number" then
            cutoff = 0.2
        end
        local materials_from, materials_to = get_material_tables()
        for _, entry in ipairs(materials_from) do
            if entry.probability <= cutoff then
                for _, shift_mat in ipairs(entry.materials) do
                    if shift_mat == material then
                        return true
                    end
                end
            end
        end
        return false
    end,

    --[[ True if the given shift destination is considered "rare" ]]
    is_rare_target = function(material, cutoff)
        if type(cutoff) ~= "number" then
            cutoff = 0.2
        end
        local materials_from, materials_to = get_material_tables()
        for _, entry in ipairs(materials_to) do
            if entry.probability <= cutoff then
                if entry.material == material then
                    return true
                end
            end
        end
        return false
    end,

    --[[ Material tables ]]
    materials_from_direct = MATERIALS_FROM_DIRECT or {},
    materials_to_direct = MATERIALS_TO_DIRECT or {},
    materials_from_copy = MATERIALS_FROM_COPY,
    materials_to_copy = MATERIALS_TO_COPY,
}

-- vim: set ts=4 sts=4 sw=4:
