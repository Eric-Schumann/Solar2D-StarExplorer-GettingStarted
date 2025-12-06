local Ship = {}

local function new(x, y, config) 
    local ship = display.newImageRect(config.sheet, 4, 98, 79)
    ship.x = x
    ship.y = y
    ship.myName = config.name or "ship"

    return ship
end

Ship.new = new

return Ship