-- src/entities/ship.lua
local physics = require("physics")

local Ship = {}

function Ship.new(x, y, config)
    -- Create display object as the ship itself
    local ship = display.newImageRect(config.group or display.currentStage, config.sheet, 4, 98, 79)
    ship.x = x
    ship.y = y
    ship.myName = config.name or "ship"

    -- Ship properties
    ship.speed = config.speed or 300
    ship.lives = config.lives or 3
    ship.isDied = false
    ship.onFire = config.onFire

    -- Physics
    physics.addBody(ship, { radius=30, isSensor=true })

    -- Movement methods
    function ship:moveLeft(dt)
        self.x = self.x - self.speed * dt
    end

    function ship:moveRight(dt)
        self.x = self.x + self.speed * dt
    end

    -- Fire method
    function ship:fire()
        if self.onFire then
            self.onFire(self.x, self.y)
        end
    end

    -- Drag method
    function ship:drag(event)
        local phase = event.phase
        if phase == "began" then
            display.currentStage:setFocus(self)
            self.touchOffsetX = event.x - self.x
            self.touchOffsetY = event.y - self.y
        elseif phase == "moved" then
            self.x = event.x - self.touchOffsetX
            self.y = event.y - self.touchOffsetY
        elseif phase == "ended" or phase == "cancelled" then
            display.currentStage:setFocus(nil)
        end
        return true
    end

    -- Restore after death
    function ship:restore()
        self.isBodyActive = false
        self.x = display.contentCenterX
        self.y = display.contentHeight - 100
        transition.to(self, { alpha=1, time=4000, onComplete=function()
            self.isBodyActive = true
            self.isDied = false
        end })
    end

    -- Destroy ship
    function ship:destroy()
        if self then
            self:removeSelf()
        end
    end

    return ship
end

return Ship
