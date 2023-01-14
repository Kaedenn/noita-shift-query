-- Fungal Query materials

MATERIALS_FROM = {
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

MATERIALS_TO = {
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

function add_source_material(materials, probability, name)
  local entry = {
    probability = probability,
    materials = materials
  }
  if name ~= nil then
    entry.name_material = name
  end
  table.insert(MATERIALS_FROM, entry)
end

function add_target_material(material, probability)
  table.insert(MATERIALS_TO, {material=material, probability=probability})
end
