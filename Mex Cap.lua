local CAP = 50

for name, ud in pairs(UnitDefs) do
    if ud.extractsmetal then 
        ud.maxThisUnit =  CAP
    end
end