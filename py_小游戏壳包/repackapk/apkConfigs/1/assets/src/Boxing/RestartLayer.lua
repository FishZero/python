local Sound = require("Boxing.Sound")
local ImageNumber = require("Boxing.ImageNumber")
local RestartLayer = class("RestartLayer")

function RestartLayer:ctor(parent, onPlayGame, cbHome)
    self.mainNode = cc.Node:create()
    self.mainNode:setContentSize(cc.size(display.realWidth, display.realHeight))
    self.mainNode:setLocalZOrder(10)
    self.mainNode:addTo(parent)

    --local mask = display.newSprite("Boxing/mask.png")
    --mask:addTo(self.mainNode)
    --local size = mask:getContentSize()
    --mask:setScaleX(display.realWidth/size.width)
    --mask:setScaleY(display.realHeight/size.height)
    --mask:move(display.realCx, display.realCy)

    --local logo = display.newSprite("Boxing/logo.png")
    --logo:addTo(self.mainNode)
    --logo:move(display.realCx, display.realCy+400)

    local scoreLayer = cc.Node:create()
    scoreLayer:addTo(self.mainNode)
    scoreLayer:move(display.realCx, display.realCy+380)

    local curScoreSprite = display.newSprite("Boxing/cur_score.png")
    curScoreSprite:addTo(scoreLayer)
    curScoreSprite:move(0, 30)

    self.scoreText = cc.LabelTTF:create("", "ArialRoundedMTBold", 60)
    self.scoreText:addTo(scoreLayer)
    self.scoreText:move(0, -40)

    local curScoreBg = display.newSprite("Boxing/score_bg.png")
    curScoreBg:addTo(scoreLayer)
    curScoreBg:move(0, -10)
    curScoreBg:setLocalZOrder(-1)

    local highScoreLayer = cc.Node:create()
    highScoreLayer:addTo(self.mainNode)
    highScoreLayer:move(display.realCx, display.realCy+100)

    local highScoreSprite = display.newSprite("Boxing/top_score.png")
    highScoreSprite:addTo(highScoreLayer)
    highScoreSprite:move(0, 30)

    self.highScoreText = cc.LabelTTF:create("", "ArialRoundedMTBold", 60)
    self.highScoreText:addTo(highScoreLayer)
    self.highScoreText:move(0, -40)

    local highScoreBg = display.newSprite("Boxing/score_bg.png")
    highScoreBg:addTo(highScoreLayer)
    highScoreBg:move(0, -10)
    highScoreBg:setLocalZOrder(-1)

    local startBtn = ccui.Button:create("Boxing/btn_replay.png")
    startBtn:addTo(self.mainNode)
    startBtn:move(display.realCx, display.realCy-220)
    startBtn:addClickEventListener(function(sender)
        Sound.playEffect("Boxing/start.mp3")
        onPlayGame()
    end)

    local homeBtn = ccui.Button:create("Boxing/btn_home.png")
    homeBtn:addTo(self.mainNode)
    homeBtn:move(display.realCx, display.realCy-450)
    homeBtn:addClickEventListener(function(sender)
        cbHome()
    end)


    local soundBtn = ccui.Button:create("Boxing/sound.png")
    soundBtn:addTo(self.mainNode)
    local btnSize = soundBtn:getContentSize()
    soundBtn:move(btnSize.width, btnSize.height)
    local noSoundSprite = display.newSprite("Boxing/no_sound.png")
    noSoundSprite:addTo(soundBtn)
    noSoundSprite:setVisible(Sound.isPause())
    noSoundSprite:move(btnSize.width/2, btnSize.height/2)
    soundBtn:addClickEventListener(function (sender)
        local soundPause = Sound.isPause()
        if soundPause then
            Sound.resume()
            noSoundSprite:setVisible(false)
        else
            Sound.pause()
            noSoundSprite:setVisible(true)
        end
    end)
    self.noSoundSprite = noSoundSprite
end

function RestartLayer:show()
    self.mainNode:setVisible(true)
    self.noSoundSprite:setVisible(Sound.isPause())
end

function RestartLayer:hide()
    self.mainNode:setVisible(false)
end

function RestartLayer:setScore(score, highScore)
    self.scoreText:setString(string.format("%d", score))
    self.highScoreText:setString(string.format("%d", highScore))
end

return RestartLayer