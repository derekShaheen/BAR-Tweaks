--Scav Buildings [Skrip]

-- Toggle to include commanders in builder list
local includeCommanders = true

local UnitDefs = UnitDefs or {}

if UnitDefs["armcomboss"] then
  local def = UnitDefs["armcomboss"]
  def.metalcost = 1000000
  def.buildtime = 300000
end        

-- Define blocking yardmap for scavbeacon units
for unitName, def in pairs(UnitDefs) do
  if unitName:match("^scavbeacon_") then
    -- Set footprint
    if unitName == "scavbeacon_t4" then
      def.footprintx = 6
      def.footprintz = 6
    else
      def.footprintx = 5
      def.footprintz = 5
    end

    -- Build yardmap
    local line = string.rep("c", def.footprintx)
    local yardmap = {}
    for _ = 1, def.footprintz do
      table.insert(yardmap, line)
    end
    def.yardmap = table.concat(yardmap, " ")
  end
end

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

  -- Optional: Set category/unitgroup
  if category and UnitDefs[buildingID] then
    UnitDefs[buildingID].customparams = UnitDefs[buildingID].customparams or {}
    UnitDefs[buildingID].customparams.unitgroup = category
    Spring.Echo("Set unitgroup for " .. buildingID .. " to " .. category)
  end
end

-- Adds a unit to a specific list of unitnames (like gantries)
function addBuildingToSpecificUnits(buildingID, unitList)
  for _, unitName in ipairs(unitList) do
    if UnitDefs[unitName] then
      UnitDefs[unitName].buildoptions = UnitDefs[unitName].buildoptions or {}
      table.insert(UnitDefs[unitName].buildoptions, buildingID)
      Spring.Echo("Added " .. buildingID .. " to " .. unitName)
    end
  end
end

-- Add Scav structure to normal builders
addBuildingToFaction("scavbeacon_t2")
addBuildingToFaction("scavbeacon_t3")
addBuildingToFaction("scavbeacon_t4")

-- Add Commander Boss to the T3 vehicle gantries
addBuildingToSpecificUnits("armcomboss", { "corgant", "armshltx", "leggant" })
addBuildingToSpecificUnits("corcomboss", { "corgant", "armshltx", "leggant" })