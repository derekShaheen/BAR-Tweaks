-- T3 Util [Skrip]

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

-- Toggle to include commanders in builder list
local includeCommanders = true

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

-- Adds a building to a specific list of unit names (like gantries)
function addBuildingToSpecificUnits(buildingID, unitList)
  for _, unitName in ipairs(unitList) do
    if UnitDefs[unitName] then
      UnitDefs[unitName].buildoptions = UnitDefs[unitName].buildoptions or {}
      table.insert(UnitDefs[unitName].buildoptions, buildingID)
      Spring.Echo("Added " .. buildingID .. " to " .. unitName)
    end
  end
end

-- Clones an existing unit and creates a modified one
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

    def.buildpic = def.buildpic or "factory.dds"

    Spring.Echo("Cloned unit: " .. newUnitID .. " from " .. sourceUnitID)
  end
end

---------------------------------------------------------------
-- T3 Utility Units Setup
---------------------------------------------------------------

-- Clone armarad into T3 radar
cloneUnit("armarad", "sk_armaradt3", "T3 Advanced Radar", "Extended-range radar station with high energy demand")
if UnitDefs["sk_armaradt3"] then
  local def = UnitDefs["sk_armaradt3"]
  def.radardistance = (def.radardistance or 2200) * 2
  def.radaremitheight = (def.radaremitheight or 600) * 1.5
  def.energycost = (def.energycost or 800) * 4
  def.metalcost = (def.metalcost or 200) * 4
  def.buildtime = (def.buildtime or 4000) * 2.5
  def.health = (def.health or 1200) * 1.5
  def.sightdistance = (def.sightdistance or 750) * 1.5
  def.customparams.unitgroup = "utility"
  def.customparams.techlevel = 3
end

-- Clone armnanotct2 into T3 construction turret
cloneUnit("armnanotct2", "sk_armnanotct3", "Base Builder", "Assist & Repair in massive radius")
if UnitDefs["sk_armnanotct3"] then
  local def = UnitDefs["sk_armnanotct3"]
  if Spring.GetModOptions().commanderbuildersbuildpower < 800 then -- use the set build power if it's greater than 800, otherwise hardcode to double the t2 con turret
    def.workertime = (def.workertime or 600) * 2
  else
    def.workertime = Spring.GetModOptions().commanderbuildersbuildpower 
  end
  def.builddistance = (def.builddistance or 400) * 1.5
  def.energycost = (def.energycost or 9000) * 3
  def.metalcost = (def.metalcost or 1800) * 3
  def.buildtime = (def.buildtime or 12000) * 2
  def.health = (def.health or 2500) * 1.5
  def.sightdistance = (def.sightdistance or 500) + 100
  def.customparams.unitgroup = "utility"
  def.customparams.techlevel = 3
  def.objectname = "lootboxes/lootboxnanoarmT4.s3o"
  def.script = "lootboxes/lootboxnanoarm.cob"
  def.footprintx = 4
  def.footprintz = 4
end

-- Add to normal builders
addBuildingToFaction("sk_armaradt3", "utility")
addBuildingToFaction("sk_armnanotct3", "builder")

-- Add builder to gantry
addBuildingToSpecificUnits("armacv", { "armshltx" })
addBuildingToSpecificUnits("coracv", { "corgant" })
addBuildingToSpecificUnits("legacv", { "leggant" })

-- Add builder to air gantry
addBuildingToSpecificUnits("armaca", { "armapt3" })
addBuildingToSpecificUnits("coraca", { "corapt3" })
addBuildingToSpecificUnits("legaca", { "legapt3" })

