-- Raptor Build v1.1 [Skrip]
-- Constructors can be built from the t1 factories
-- Toggle to allow commanders to build raptor buildings.
local includeCommanders = false

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
function selectBestUnits(prefixes, threshold, direction)
  local bestUnits = {}

  for unitName, _ in pairs(UnitDefs) do
    for _, prefix in ipairs(prefixes) do
      if unitName:match("^" .. prefix) then
        local metalCost = UnitDefs[unitName].metalcost
        local passesFilter = true

        if threshold and direction then
          if direction == ">" then
            passesFilter = metalCost > threshold
          elseif direction == "<" then
            passesFilter = metalCost < threshold
          end
        end

        if passesFilter then
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
  end

  return bestUnits
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
function addUnitsToBuilding(bldID, unitInput, category)
  if UnitDefs[bldID] then
    UnitDefs[bldID].buildoptions = UnitDefs[bldID].buildoptions or {}

    if type(unitInput) == "table" then
      for _, unitInfo in pairs(unitInput) do
        -- Check if table is {name=...} (from selectUnits), or simple list
        local unitName = unitInfo.name or unitInfo
        table.insert(UnitDefs[bldID].buildoptions, unitName)
        Spring.Echo("Added " .. unitName .. " to " .. bldID)

          -- Category assignment (optional)
        if category and UnitDefs[unitName] then
          UnitDefs[unitName].customparams = UnitDefs[unitName].customparams or {}
          UnitDefs[unitName].customparams.unitgroup = category
          Spring.Echo("Set unitgroup for " .. unitName .. " to " .. category)
        end
      end
    elseif type(unitInput) == "string" then
      -- Single unit string
      table.insert(UnitDefs[bldID].buildoptions, unitInput)
      Spring.Echo("Added " .. unitInput .. " to " .. bldID)
    end
  end
end

---------------------------------------------------------------
-- Correct unitdefs
---------------------------------------------------------------
if UnitDefs["raptor_turret_basic_t4_v1"] and UnitDefs["raptor_turret_burrow_t2_v1"] then
  local def = UnitDefs["raptor_turret_burrow_t2_v1"]

  def.buildpic = "raptors/raptor_turrets.DDS" 
  def.metalcost = (UnitDefs["raptor_turret_basic_t4_v1"].metalcost * 2 or 1600)
  def.energycost = (UnitDefs["raptor_turret_basic_t4_v1"].energycost * 2 or 1600)
end


---------------------------------------------------------------
-- Raptor Gantries Setup
---------------------------------------------------------------
--, "raptor_allterrain_", "raptor_matriarch_", "raptor_queen_"
-- Create Raptor Land Gantry t1
cloneUnit("legvp", "sk_raptorhatchery_t1", "Raptor Hatchery", "Specialized factory for land-based Raptor units")
local bestLandUnits = selectBestUnits({ "raptor_land_" }, 999, "<")
addUnitsToBuilding("sk_raptorhatchery_t1", bestLandUnits)
-- addBuildingToFaction("sk_raptorhatchery", nil, "builder")

-- Create Raptor Land Gantry t2
cloneUnit("leggant", "sk_raptorhatchery_t2", "Giant Raptor Hatchery", "Specialized factory for land-based Raptor units")
local bestLandUnits = selectBestUnits({ "raptor_land_", "raptor_allterrain_", "raptor_matriarch_", "raptor_queen_" }, 1000, ">")
addUnitsToBuilding("sk_raptorhatchery_t2", bestLandUnits)

-- Create Raptor Air Gantry
cloneUnit("legaap", "sk_raptorairhatchery", "Raptor Air Hatchery", "Specialized factory for air-based Raptor units")
local bestAirUnits = selectBestUnits({ "raptor_air_" })
addUnitsToBuilding("sk_raptorairhatchery", bestAirUnits)
-- addBuildingToFaction("sk_raptorairhatchery", nil, "builder")

-- -- Add buildings
-- addBuildingToFaction("raptor_turret_acid_t3_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_acid_t4_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_antiair_t3_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_antiair_t4_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_antinuke_t3_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_antinuke_t4_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_basic_t3_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_basic_t4_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_emp_t3_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_emp_t4_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_meteor_t3_v1", nil, "weapon")
-- addBuildingToFaction("raptor_turret_meteor_t4_v1", nil, "weapon")

-- Create raptor builder
cloneUnit("armacv", "sk_raptorbuilder", "Raptor Construction Vehicle", "Builds Raptor Hatcheries")

if UnitDefs["sk_raptorbuilder"] then
  local def = UnitDefs["sk_raptorbuilder"]
  
  -- Change model and visuals

  --def.objectname = "Raptors/raptor1d.s3o"
  -- def.script = "Raptors/raptor1d.cob"
  def.buildpic = "raptors/raptor1d.DDS"

  -- -- Cost adjustments
  -- def.energycost = 500
  -- def.metalcost = 250
  -- def.buildtime = 8000
  
  -- -- Resource generation (optional)
  -- def.energymake = 10
  -- def.metalmake = 1
  
  -- Clean up factory stuff
  def.customparams.techlevel = 2
  def.customparams.unitgroup = "builder"
  
  -- Wipe any old build options, set to only Hatcheries
  def.buildoptions = { }
  def.buildoptions = {
    "sk_raptorhatchery_t1"
    , "sk_raptorhatchery_t2"
    --, "sk_raptorairhatchery"
  }
end

addUnitsToBuilding("sk_raptorbuilder", selectBestUnits({ "raptor_turret_" }), "weapon")

addUnitsToBuilding("armvp", "sk_raptorbuilder")
addUnitsToBuilding("armlab", "sk_raptorbuilder")

-- Create raptor builder
cloneUnit("armaca", "sk_raptorairbuilder", "Raptor Air Construction Vehicle", "Builds Raptor Air Hatcheries")

if UnitDefs["sk_raptorairbuilder"] then
  local def = UnitDefs["sk_raptorairbuilder"]
  
  -- Change model and visuals
  --def.objectname = "Raptors/raptorairscout1.s3o"
  -- def.script = "Raptors/raptorairscout.cob"
  def.buildpic = "raptors/raptorairscout.DDS" 

  -- -- Cost adjustments
  -- def.energycost = 500
  -- def.metalcost = 250
  -- def.buildtime = 8000
  
  -- -- Resource generation (optional)
  -- def.energymake = 10
  -- def.metalmake = 1
  
  -- Clean up factory stuff
  def.customparams.techlevel = 2
  def.customparams.unitgroup = "builder"
  
  -- Wipe any old build options, set to only Hatcheries
  def.buildoptions = { }
  def.buildoptions = {
    --"sk_raptorhatchery"
    "sk_raptorairhatchery"
  }
end

addUnitsToBuilding("sk_raptorairbuilder", selectBestUnits({ "raptor_turret_" }), "weapon")

-- Add the Raptor Builder to Vehicle Factory
addUnitsToBuilding("armap", "sk_raptorairbuilder")