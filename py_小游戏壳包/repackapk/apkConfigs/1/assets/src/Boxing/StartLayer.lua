local Sound = require("Boxing.Sound")

local StartLayer = class("StartLayer")

function StartLayer:ctor(parent, onPlayGame)
    self.mainNode = cc.Node:create()
    self.mainNode:setContentSize(cc.size(display.realWidth, display.realHeight))
    self.mainNode:setLocalZOrder(10)
    self.mainNode:addTo(parent)

    local logo = display.newSprite("Boxing/logo.png")
    logo:addTo(self.mainNode)
    logo:move(display.realCx, display.realCy+410)

    local hill = display.newSprite("Boxing/hill.png")
    hill:addTo(self.mainNode)
    hill:setAnchorPoint(cc.p(0, 0))

    local startBtn = ccui.Button:create("Boxing/btn_start.png")
    startBtn:addTo(self.mainNode)
    startBtn:move(display.realCx, display.realCy)
    startBtn:addClickEventListener(function(sender)
        Sound.playEffect("Boxing/start.mp3")
        onPlayGame()
    end)

    --local startText = cc.LabelTTF:create("开始", "", 100)
    --startText:setColor(cc.c3b(0, 0, 0))
    --startText:addTo(startBtn)
    --local startBgSize = startBtn:getContentSize()
    --startText:move(startBgSize.width/2, startBgSize.height/2)

    local soundBtn = ccui.Button:create("Boxing/sound.png")
    soundBtn:addTo(self.mainNode)
    local btnSize = soundBtn:getContentSize()
    soundBtn:move(btnSize.width+10, btnSize.height+60)
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

function StartLayer:show()
    self.mainNode:setVisible(true)
    self.noSoundSprite:setVisible(Sound.isPause())
end

function StartLayer:hide()
    self.mainNode:setVisible(false)
end

return StartLayer