local composer = require("composer")
local scene = composer.newScene( )
local AudioManager = require('lib.AudioManager')
local Ship = require("ship")

local physics = require('physics')
physics.start()
physics.setGravity( 0, 0 )

local sheetOptions = {
    frames = {
        { -- 1) asteroid 1
            x = 0,
            y = 0,
            width = 102,
            height = 85
        },
        {-- 2) asteroid 2
            x = 0,
            y = 85,
            width = 90,
            height = 83
        },
        {-- 3) asteroid 3
            x = 0,
            y = 168,
            width = 100,
            height = 97
        },
        {-- 4) ship
            x = 0,
            y = 265,
            width = 98,
            height = 79
        },
        {-- 5) laser
            x = 98,
            y = 265,
            width = 14,
            height = 40
        },
    },
}

local objectSheet = graphics.newImageSheet( "assets/sheets/gameObjects.png", sheetOptions )

local lives = 3
local score = 0
local died = false

local asteroidsTable = {}

local ship
local gameLoopTimer
local livesText
local scoreText

local musicFile = "80s-Space-Game_Looping.wav" 
local soundFiles = {
    explosion="explosion.wav",
    fire="fire.wav"
}
local sounds = {}
local music

local backGroup
local mainGroup
local uiGroup


local function updateText()
    livesText.text = "Lives: " .. lives
    scoreText.text = "Score: " .. score
end

local function createAsteroid()
    local newAsteroid = display.newImageRect(mainGroup, objectSheet, 1, 102, 85)
    table.insert(asteroidsTable, newAsteroid)
    physics.addBody(newAsteroid, "dynamic", { radius=40, bounce=0.8 })
    newAsteroid.myName = "asteroid"

    local whereFrom = math.random(3)

    if(whereFrom == 1) then 
        newAsteroid.x = -60
        newAsteroid.y = math.random(500)
        newAsteroid:setLinearVelocity(math.random(40,120), math.random(20,60))
    elseif(whereFrom == 2) then
        newAsteroid.x = math.random(display.contentWidth)
        newAsteroid.y = -60
        newAsteroid:setLinearVelocity(math.random(-40,40), math.random(40,120))
    elseif(whereFrom == 3) then
        newAsteroid.x = display.contentWidth + 60
        newAsteroid.y = math.random(500)
        newAsteroid:setLinearVelocity(math.random(-120,-40), math.random(20,60))
    end
    newAsteroid:applyTorque(math.random(-6, 6))
end

local function fireLaser()
    audio.play(sounds.fire)
    local newLaser = display.newImageRect(mainGroup, objectSheet, 5,14,40)
    physics.addBody(newLaser, "dynamic", { isSensor=true })
    newLaser.isBullet = true
    newLaser.myName = "laser"
    
    newLaser.x = ship.x
    newLaser.y = ship.y
    newLaser:toBack()
    
    transition.to(newLaser, { y=-40, time=500, 
        onComplete = function() display.remove(newLaser) end 
    })
end

local function dragShip(event)
    local ship = event.target
    local phase = event.phase
    if("began" == phase) then 
        display.currentStage:setFocus(ship)
        ship.touchOffsetX = event.x - ship.x
        ship.touchOffsetY = event.y - ship.y
    elseif("moved" == phase) then
        ship.x = event.x - ship.touchOffsetX
        ship.y = event.y - ship.touchOffsetY
    elseif("ended" == phase) then
        display.currentStage:setFocus(nil)
    end
    return true
end

local function gameLoop()
    createAsteroid()

    for i = #asteroidsTable, 1, -1 do 
        local thisAsteroid = asteroidsTable[i]
        if(thisAsteroid.x < -100 or
            thisAsteroid.x > display.contentWidth + 100 or
            thisAsteroid.y < -100 or
            thisAsteroid.y > display.contentHeight + 100) then
                display.remove(thisAsteroid)
                table.remove(asteroidsTable, i)
        end
    end
end

local function restoreShip()
    ship.isBodyActive = false
    ship.x = display.contentCenterX
    ship.y = display.contentHeight - 100

    -- Fade in the ship
    transition.to(ship, { alpha=1, time=4000, onComplete = function() 
        ship.isBodyActive = ship
        died = false
    end})
end

local function endGame()
    composer.setVariable( "finalScore", score )
    composer.gotoScene("menu", { time=800, effect="crossFade" })
end

local function onCollision(event)
    if(event.phase == "began") then 
        local obj1 = event.object1
        local obj2 = event.object2

        if (obj1.myName == "laser" and obj2.myName == "asteroid") or 
            (obj1.myName == "asteroid" and obj2.myName == "laser") then
                display.remove(obj1)
                display.remove(obj2)

                audio.play(sounds.explosion)

                for i=#asteroidsTable, 1, -1 do 
                    if (asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2) then 
                        table.remove(asteroidsTable, i)
                        break
                    end
                end

            score = score+100
            scoreText.text = "Score: " .. score                
        elseif (obj1.myName == "ship" and obj2.myName == "asteroid") or 
                    (obj1.myName == "asteroid" and obj2.myName == "ship") then
                        if died == false then 
                            died = true

                            audio.play(sounds.explosion)

                            lives = lives - 1
                            livesText.text = "Lives: " .. lives

                            if(lives == 0) then 
                                display.remove(ship)
                                timer.performWithDelay(2000, endGame)
                            else
                                ship.alpha = 0
                                timer.performWithDelay( 1000, restoreShip)
                            end
                        end
        end
    end 
end

function scene:create(event)
    local sceneGroup = self.view
    physics.pause()

    backGroup = display.newGroup()
    sceneGroup:insert(backGroup)

    mainGroup = display.newGroup()
    sceneGroup:insert(mainGroup)

    uiGroup = display.newGroup()
    sceneGroup:insert(uiGroup)

    local background = display.newImageRect(backGroup, "assets/images/background.png", 800, 1400)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    ship = Ship.new(
        display.contentCenterX,
        display.contentHeight - 100,
        {
            name="ship",
            sheet=objectSheet,
        }
    )
    physics.addBody(ship, { radius=30, isSensor=true })
    
    livesText = display.newText(uiGroup, "Lives: " .. lives, 220, 80, native.systemFont, 36)
    scoreText = display.newText( uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36)

    ship:addEventListener("tap", fireLaser)
    ship:addEventListener("touch", dragShip)


    sounds.explosion = AudioManager.loadSound(soundFiles.explosion)
    sounds.fire = AudioManager.loadSound(soundFiles.fire)
    music = AudioManager.loadStream(musicFile)

end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if(phase == "will") then 
        
    elseif(phase == "did") then
        physics.start()
        Runtime:addEventListener("collision", onCollision)
        gameLoopTimer = timer.performWithDelay( 500, gameLoop, 0 )
        audio.play(music, { channel=1, loops=-1 })
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase

    if(phase == "will") then 
        timer.cancel(gameLoopTimer)
    elseif(phase == "did") then
        Runtime:removeEventListener("collision", onCollision)
        physics.pause()
        audio.stop(1)
        composer.removeScene("game")
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
    AudioManager.disposeSounds()
    AudioManager.disposeStream(musicFile)
end


scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)


return scene