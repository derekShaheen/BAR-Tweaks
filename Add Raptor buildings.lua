-- Raptor Buildings v1 [Skrip]
-- Toggle to allow commanders to build raptor buildings. Otherwise only T2 constructors
local includeCommanders = true

---------------------------
function table.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
    end
    setmetatable(copy, table.deepcopy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

local UnitDefs = UnitDefs or {}
-- Maps faction prefix to their builder units
local factionBuilders = {
  arm = { "armaca", "armack", "armacv", "armcom" },
  cor = { "coraca", "corack", "coracv", "corcom" },
  leg = { "legaca", "legack", "legacv", "legcom" },
}

-- Adds a building to the buildoptions of each builder in the faction
function addBuildingToFaction(buildingID, factionKey, category)
  local targetFactions = {}

  if factionKey and factionBuilders[factionKey] then
    targetFactions[factionKey] = factionBuilders[factionKey]
  else
    targetFactions = factionBuilders -- all factions
  end

  for _, builders in pairs(targetFactions) do
    for _, builder in ipairs(builders) do
      local isCommander = builder:match("com$")

      -- Add to base builder
      if (includeCommanders or not isCommander) and UnitDefs[builder] then
        UnitDefs[builder].buildoptions = UnitDefs[builder].buildoptions or {}
        table.insert(UnitDefs[builder].buildoptions, buildingID)
        Spring.Echo("Added " .. buildingID .. " to " .. builder)
      end

      -- Add to all commander levels
      if includeCommanders and isCommander then
        for lvl = 2, 10 do
          local levelBuilder = builder .. "lvl" .. lvl
          if UnitDefs[levelBuilder] then
            UnitDefs[levelBuilder].buildoptions = UnitDefs[levelBuilder].buildoptions or {}
            table.insert(UnitDefs[levelBuilder].buildoptions, buildingID)
            Spring.Echo("Added " .. buildingID .. " to " .. levelBuilder)
          end
        end
      end
    end
  end

  if category and UnitDefs[buildingID] then
    UnitDefs[buildingID].customparams = UnitDefs[buildingID].customparams or {}
    UnitDefs[buildingID].customparams.unitgroup = category
    Spring.Echo("Set unitgroup for " .. buildingID .. " to " .. category)
  end
end

-- Clones an existing building and creates a new one
function cloneUnit(sourceUnitID, newUnitID, humanName, tooltip)
  if UnitDefs[sourceUnitID] and not UnitDefs[newUnitID] then
    local base = table.deepcopy(UnitDefs[sourceUnitID])
    UnitDefs[newUnitID] = base

    local def = UnitDefs[newUnitID]
    def.unitname = newUnitID
    def.buildoptions = {}

    def.customparams = def.customparams or {}
    def.customparams.i18n_en_humanname = humanName
    def.customparams.i18n_en_tooltip = tooltip
    def.customparams.unitgroup = "builder"

    def.buildpic = def.buildpic or "factory.dds"

    Spring.Echo("Cloned: " .. newUnitID .. " from " .. sourceUnitID)
  end
end

-- Picks highest version units given prefixes
function selectBestUnits(prefixes)
  local bestUnits = {}

  for unitName, _ in pairs(UnitDefs) do
    for _, prefix in ipairs(prefixes) do
      if unitName:match("^" .. prefix) and not unitName:find("_t1") then
        local baseName, version = unitName:match("^(.-)_v(%d+)$")

        if baseName and version then
          version = tonumber(version)
          if not bestUnits[baseName] or version > bestUnits[baseName].version then
            bestUnits[baseName] = { name = unitName, version = version }
          end
        else
          if not bestUnits[unitName] then
            bestUnits[unitName] = { name = unitName, version = 0 }
          end
        end
      end
    end
  end

  return bestUnits
end

-- Adds selected units to a buildings buildoptions
function addUnitsToBuilding(bldID, unitTable)
  if UnitDefs[bldID] then
    for _, unitInfo in pairs(unitTable) do
      table.insert(UnitDefs[bldID].buildoptions, unitInfo.name)
      Spring.Echo("Added " .. unitInfo.name .. " to " .. bldID)
    end
  end
end

---------------------------------------------------------------
-- Raptor Gantries Setup
---------------------------------------------------------------

-- Create Raptor Land Gantry
cloneUnit("leggant", "sk_raptorhatchery", "Giant Raptor Hatchery", "Specialized factory for land-based Raptor units")
local bestLandUnits = selectBestUnits({ "raptor_land_", "raptor_allterrain_", "raptor_matriarch_", "raptor_queen_" })
addUnitsToBuilding("sk_raptorhatchery", bestLandUnits)
addBuildingToFaction("sk_raptorhatchery", nil, "builder")

-- Create Raptor Air Gantry
cloneUnit("legaap", "sk_raptorairhatchery", "Raptor Air Hatchery", "Specialized factory for air-based Raptor units")
local bestAirUnits = selectBestUnits({ "raptor_air_" })
addUnitsToBuilding("sk_raptorairhatchery", bestAirUnits)
addBuildingToFaction("sk_raptorairhatchery", nil, "builder")

-- Add buildings
addBuildingToFaction("raptor_turret_acid_t3_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_acid_t4_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_antiair_t3_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_antiair_t4_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_antinuke_t3_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_antinuke_t4_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_basic_t3_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_basic_t4_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_emp_t3_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_emp_t4_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_meteor_t3_v1", nil, "weapon")
addBuildingToFaction("raptor_turret_meteor_t4_v1", nil, "weapon")
