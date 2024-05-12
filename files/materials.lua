--[[ Fungal Shift Query material rules ]]

dofile("data/scripts/magic/fungal_shift.lua")

MatLib = {materials = {}}

--[[ Obtain the materials_from (shift sources) table ]]
function MatLib.get_materials_from()
    return materials_from
end

--[[ Obtain the materials_to (shift destinations) table ]]
function MatLib.get_materials_to()
    return materials_to
end

--[[ Obtain the list of "greedy" materials.
-- These materials will be used when shifting to gold (less 1/1000 chance)
--]]
function MatLib.get_greedy_materials()
    return greedy_materials
end

--[[ True if the given shift source is considered "rare" ]]
function MatLib.is_rare_source(material, cutoff)
    if type(cutoff) ~= "number" then cutoff = 0.2 end
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
end

--[[ True if the given shift destination is considered "rare" ]]
function MatLib.is_rare_target(material, cutoff)
    if type(cutoff) ~= "number" then cutoff = 0.2 end
    for _, entry in ipairs(materials_to) do
        if entry.probability <= cutoff then
            if entry.material == material then
                return true
            end
        end
    end
    return false
end

return MatLib

-- vim: set ts=4 sts=4 sw=4:
