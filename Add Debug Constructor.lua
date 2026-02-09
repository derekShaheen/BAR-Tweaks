-- Dev Constructor v1 [Skrip]
local includeCommanders = true

-- Helper for copying an existing unit
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
  arm = { "armaca", "armack", "armacv", "armcom" }, -- "armcom"
  cor = { "coraca", "corack", "coracv", "corcom" }, -- "corcom"
  leg = { "legaca", "legack", "legacv", "legcom" }, -- "legcom"
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

function selectUnits(prefixes)
    local unitList = {}

    for unitName, _ in pairs(UnitDefs) do
        for _, prefix in ipairs(prefixes) do
        if unitName:match("^" .. prefix) then
            if not unitList[unitName] then
                unitList[unitName] = { name = unitName }
            end
        end
        end
    end

    return unitList
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

cloneUnit("armaca", "skrip_constructor", "Developer Constructor", "Specialized developer unit")
if UnitDefs["skrip_constructor"] then
    local def = UnitDefs["skrip_constructor"]
    local maxedSetting = 99999
    def.energymake = maxedSetting
    def.metalmake = maxedSetting
    def.energystorage = maxedSetting
    def.metalstorage = maxedSetting
    def.maxwaterdepth = 60
    def.speed = 999
    def.workertime = maxedSetting
    def.energycost = 1
    def.metalcost = 1
    def.buildtime = 1
    def.health = maxedSetting
    def.sightdistance = maxedSetting
    def.customparams.techlevel = 3
    def.turnrate = 300
    def.buildoptions = {}
  end
local AllUnits = selectUnits({ "" })
addUnitsToBuilding("skrip_constructor", AllUnits)
addBuildingToFaction("skrip_constructor", nil, "builder")