local composer = require('composer')
local AudioManager = require("src.lib.AudioManager")
local scene = composer.newScene()

local musicFile = "Escape_Looping.wav"
local sceneMusic


local function gotoGame()
    composer.gotoScene("src.scenes.game", { time=800, effect="crossFade" })
end

local function gotoHighScores()
    composer.gotoScene("src.scenes.highscores", { time=800, effect="crossFade" })
end

function scene:create(event)
    local sceneGroup = self.view

    local background = display.newImageRect(sceneGroup, "assets/images/background.png", 800, 1400)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    local title = display.newImageRect(sceneGroup, "assets/images/title.png", 500, 80)
    title.x = display.contentCenterX
    title.y = 200

    local playButton = display.newText(sceneGroup, "Play", display.contentCenterX, 700, native.systemFont, 44)
    playButton:setFillColor(0.82,0.86,1)

    local highScoresButton = display.newText(sceneGroup, "High Scores", display.contentCenterX, 810, native.systemFont, 44)
    highScoresButton:setFillColor(0.82,0.86,1)

    playButton:addEventListener("tap", gotoGame)
    highScoresButton:addEventListener("tap", gotoHighScores)

    sceneMusic = AudioManager.loadStream(musicFile)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase
    if phase == "will" then 
    elseif phase == "did" then
        audio.play(sceneMusic, { channel=1, loops=-1 })
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then 
    elseif phase == "did" then
        audio.stop(1)
        composer.removeScene( "src.scenes.menu" )
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene