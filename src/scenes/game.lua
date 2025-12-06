local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")
local AudioManager = require("src.lib.AudioManager")
local Ship = require("src.entities.ship")

physics.start()
physics.setGravity(0, 0)

-- Sprite sheet
local sheetOptions = {
    frames = {
        {x=0, y=0, width=102, height=85},   -- asteroid1
        {x=0, y=85, width=90, height=83},   -- asteroid2
        {x=0, y=168, width=100, height=97}, -- asteroid3
        {x=0, y=265, width=98, height=79},  -- ship
        {x=98, y=265, width=14, height=40}, -- laser
    }
}
local objectSheet = graphics.newImageSheet("assets/sheets/gameObjects.png", sheetOptions)

-- Game variables
local backGroup, mainGroup, uiGroup
local ship
local asteroidsTable = {}
local gameLoopTimer
local lives = 3
local score = 0
local sounds = {}
local music
local musicFile = "80s-Space-Game_Looping.wav"

-- UI
local livesText, scoreText

local function updateText()
    livesText.text = "Lives: "..lives
    scoreText.text = "Score: "..score
end

-- Asteroids
local function createAsteroid()
    local newAsteroid = display.newImageRect(mainGroup, objectSheet, 1, 102, 85)
    table.insert(asteroidsTable, newAsteroid)
    physics.addBody(newAsteroid, "dynamic", { radius=40, bounce=0.8 })
    newAsteroid.myName = "asteroid"

    local whereFrom = math.random(3)
    if whereFrom == 1 then
        newAsteroid.x = -60
        newAsteroid.y = math.random(500)
        newAsteroid:setLinearVelocity(math.random(40,120), math.random(20,60))
    elseif whereFrom == 2 then
        newAsteroid.x = math.random(display.contentWidth)
        newAsteroid.y = -60
        newAsteroid:setLinearVelocity(math.random(-40,40), math.random(40,120))
    else
        newAsteroid.x = display.contentWidth + 60
        newAsteroid.y = math.random(500)
        newAsteroid:setLinearVelocity(math.random(-120,-40), math.random(20,60))
    end
    newAsteroid:applyTorque(math.random(-6,6))
end

local function gameLoop()
    createAsteroid()
    for i=#asteroidsTable,1,-1 do
        local a = asteroidsTable[i]
        if a.x<-100 or a.x>display.contentWidth+100 or a.y<-100 or a.y>display.contentHeight+100 then
            display.remove(a)
            table.remove(asteroidsTable,i)
        end
    end
end

-- Laser firing
local function fireLaser(x,y)
    audio.play(sounds.fire)
    local newLaser = display.newImageRect(mainGroup, objectSheet, 5, 14, 40)
    physics.addBody(newLaser, "dynamic", { isSensor=true })
    newLaser.isBullet = true
    newLaser.myName = "laser"
    newLaser.x = x
    newLaser.y = y
    newLaser:toBack()
    transition.to(newLaser, { y=-40, time=500, onComplete=function() display.remove(newLaser) end })
end

-- Collisions
local function onCollision(event)
    if event.phase ~= "began" then return end
    local obj1, obj2 = event.object1, event.object2

    -- Laser hits asteroid
    if (obj1.myName=="laser" and obj2.myName=="asteroid") or
       (obj1.myName=="asteroid" and obj2.myName=="laser") then
        display.remove(obj1)
        display.remove(obj2)
        audio.play(sounds.explosion)
        for i=#asteroidsTable,1,-1 do
            if asteroidsTable[i]==obj1 or asteroidsTable[i]==obj2 then
                table.remove(asteroidsTable,i)
                break
            end
        end
        score = score + 100
        updateText()
    end

    -- Ship hits asteroid
    if (obj1.myName=="ship" and obj2.myName=="asteroid") or
       (obj1.myName=="asteroid" and obj2.myName=="ship") then
        if not ship.isDied then
            ship.isDied = true
            audio.play(sounds.explosion)
            lives = lives - 1
            updateText()
            if lives == 0 then
                ship:destroy()
                timer.performWithDelay(2000,function()
                    composer.gotoScene("src.scenes.menu",{time=800,effect="crossFade"})
                end)
            else
                ship.alpha = 0
                timer.performWithDelay(1000,function() ship:restore() end)
            end
        end
    end
end

-- Scene lifecycle
function scene:create(event)
    local sceneGroup = self.view
    physics.pause()

    -- Groups
    backGroup = display.newGroup()
    mainGroup = display.newGroup()
    uiGroup = display.newGroup()
    sceneGroup:insert(backGroup)
    sceneGroup:insert(mainGroup)
    sceneGroup:insert(uiGroup)

    -- Background
    local background = display.newImageRect(backGroup, "assets/images/background.png", 800, 1400)
    background.x, background.y = display.contentCenterX, display.contentCenterY

    -- Ship
    ship = Ship.new(display.contentCenterX, display.contentHeight-100, {
        name="ship",
        sheet=objectSheet,
        onFire = fireLaser
    })
    mainGroup:insert(ship)
    ship:addEventListener("tap", function() ship:fire() end)
    ship:addEventListener("touch", function(e) return ship:drag(e) end)

    -- UI
    livesText = display.newText(uiGroup,"Lives: "..lives,220,80,native.systemFont,36)
    scoreText = display.newText(uiGroup,"Score: "..score,400,80,native.systemFont,36)

    -- Sounds
    sounds.explosion = AudioManager.loadSound("explosion.wav")
    sounds.fire = AudioManager.loadSound("fire.wav")
    music = AudioManager.loadStream(musicFile)
end

function scene:show(event)
    local phase = event.phase
    if phase == "did" then
        physics.start()
        Runtime:addEventListener("collision",onCollision)
        gameLoopTimer = timer.performWithDelay(500,gameLoop,0)
        audio.play(music,{channel=1,loops=-1})
    end
end

function scene:hide(event)
    local phase = event.phase
    if phase == "will" then
        timer.cancel(gameLoopTimer)
    elseif phase == "did" then
        Runtime:removeEventListener("collision",onCollision)
        physics.pause()
        audio.stop(1)
        composer.removeScene("game")
    end
end

function scene:destroy(event)
    AudioManager.disposeSounds()
    AudioManager.disposeStream(musicFile)
end

scene:addEventListener("create",scene)
scene:addEventListener("show",scene)
scene:addEventListener("hide",scene)
scene:addEventListener("destroy",scene)

return scene
