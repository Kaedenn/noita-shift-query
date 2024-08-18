--[[ Fungal Shift Query material rules ]]

dofile("data/scripts/magic/fungal_shift.lua")
I18N = dofile_once("mods/shift_query/files/i18n.lua")

MatLib = {
    materials = {
        by_name = {},
        by_id = {},
    }
}

--[[ INSTANCE FUNCTIONS ]]

--[[ Determine everything about materials before they begin changing ]]
function MatLib:init()
    I18N:init()
    self.materials.by_name = {}
    self.materials.by_id = {}

    local mattables = {
        CellFactory_GetAllLiquids(),
        CellFactory_GetAllSands(),
        CellFactory_GetAllGases(),
        CellFactory_GetAllFires(),
        CellFactory_GetAllSolids(),
    }
    for _, tbl in ipairs(mattables) do
        for _, mat in ipairs(tbl) do
            local matid = CellFactory_GetType(mat)
            local entry = {
                id = matid,
                name = mat,
                uiname = CellFactory_GetUIName(matid),
                local_name = nil, -- populated below
                tags = CellFactory_GetTags(matid),
            }
            entry.local_name = I18N:get(entry.uiname, entry.name)
            self.materials.by_name[mat] = entry
            self.materials.by_id[matid] = entry
        end
    end
end

--[[ Obtain material ID, name, uiname, and localized name ]]
function MatLib:get(name)
    return self.materials.by_name[name]
end

--[[ STATIC FUNCTIONS ]]

--[[ Obtain the materials_from (shift sources) table ]]
function MatLib.get_materials_from()
    -- luacheck: globals materials_from
    return materials_from
end

--[[ Obtain the materials_to (shift destinations) table ]]
function MatLib.get_materials_to()
    -- luacheck: globals materials_to
    return materials_to
end

--[[ Obtain the list of "greedy" materials.
-- These materials will be used when shifting to gold (less 1/1000 chance)
--]]
function MatLib.get_greedy_materials()
    -- luacheck: globals greedy_materials
    return greedy_materials
end

--[[ True if the given shift source is considered "rare" ]]
function MatLib.is_rare_source(material, cutoff)
    if type(cutoff) ~= "number" then cutoff = 0.2 end
    -- luacheck: globals materials_from
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
    -- luacheck: globals materials_to
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
