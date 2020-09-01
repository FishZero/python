require("Boxing.Score")
local Define = require("Boxing.Define")
local Sound = require("Boxing.Sound")

local scheduler = cc.Director:getInstance():getScheduler()
local MiniGameController = class("MiniGameController")
local StartLayer
local RestartLayer


MiniGameController.MSG_SCENE_INIT_FINISH = "onSceneInitFinish"
MiniGameController.MSG_GAME_PAUSE = "onGamePause"
MiniGameController.MSG_GAME_RESUME = "onGameResume"
MiniGameController.MSG_ON_START = "onStartPlay"
MiniGameController.MSG_ON_TOUCH_BEGIN = "onTouchBegin"
MiniGameController.MSG_ON_TOUCH_MOVED = "onTouchMoved"
MiniGameController.MSG_ON_TOUCH_ENDED = "onTouchEnded"
MiniGameController.MSG_ON_TOUCH_CANCELLED = "onTouchCancelled"
MiniGameController.MSG_ON_GAME_OVER = "onGameOver"
MiniGameController.MSG_ON_HOME = "onHome"
MiniGameController.MSG_FRAME_UPDATE = "frameUpdate"

local MINIGAMECONTROLLER_Z_UI_ORDER = 10
local MNIGAMECONTROLLER_Z_ORDER = 5

function MiniGameController:frameUpdate()
    self:sendMsg(MiniGameController.MSG_FRAME_UPDATE)
end

function MiniGameController:onTouchBegin(touch, event)
    --Sound.playEffect("Boxing/click_screen.mp3")
    self:sendMsg(MiniGameController.MSG_ON_TOUCH_BEGIN, touch:getLocation())
    return true
end

function MiniGameController:onTouchMoved(touch, event)
    self:sendMsg(MiniGameController.MSG_ON_TOUCH_MOVED, touch:getLocation())
end

function MiniGameController:onTouchEnded(touch, event)
    self:sendMsg(MiniGameController.MSG_ON_TOUCH_ENDED, touch:getLocation())
end

function MiniGameController:onTouchCancelled(touch, event)
    self:sendMsg(MiniGameController.MSG_ON_TOUCH_CANCELLED, touch:getLocation())
end

function MiniGameController:ctor(mainNode, startLayer, restartLayer)
    StartLayer = startLayer
    RestartLayer = restartLayer
    self.registerFuncTable = {}
    self.mainNode = mainNode
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self, MiniGameController.onTouchBegin), cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(handler(self, MiniGameController.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(handler(self, MiniGameController.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
    listener:registerScriptHandler(handler(self, MiniGameController.onTouchCancelled), cc.Handler.EVENT_TOUCH_CANCELLED)
    local eventDispatcher = self.mainNode:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.mainNode)
end

function MiniGameController:start()
    self:initScene()
end

function MiniGameController:initScene()
    self.uiNode = cc.Node:create()
    self.uiNode:addTo(self.mainNode)
    self.uiNode:setLocalZOrder(MINIGAMECONTROLLER_Z_UI_ORDER)
    self:initBackground()
    self:initPauseBtn()
    self:initStartLayer()
    self:initRestartLayer()
    self.gameNode = cc.Node:create()
    self.gameNode:addTo(self.mainNode)
    self.gameNode:setLocalZOrder(MNIGAMECONTROLLER_Z_ORDER)
    self:sendMsg(MiniGameController.MSG_SCENE_INIT_FINISH)
    Sound.playBgMusic()
end

function MiniGameController:startPlay()
    self.GamingFlag = true
    self:resumeFrameUpdate()
    self.pauseFlag = false
    self.pauseBtn:setVisible(true)
    self.startLayer:hide()
    self.restartLayer:hide()
    self.resumeBtnLayer:setVisible(false)
    self.gameNode:removeAllChildren()
    self.gameNode:stopAllActions()
    self:initScore()
    Sound.playBgMusic(true)
    self:sendMsg(MiniGameController.MSG_ON_START)
end

function MiniGameController:initScore()
    local scoreLabel = cc.LabelTTF:create("", "", 80)
    scoreLabel:setColor(cc.c3b(255, 255, 255))
    local x, y = display.realWidth - 80, display.realHeight-80
    scoreLabel:move(x, y)
    scoreLabel:addTo(self.gameNode)
    self.scoreLabel = scoreLabel
    initScore()
    setCurScoreLabel(scoreLabel)

    local scoreTip = cc.LabelTTF:create("+1", "", 60)
    scoreTip:setLocalZOrder(1)
    scoreTip:setOpacity(0)
    scoreTip:addTo(self.gameNode)
    self.scoreTip = scoreTip
end


function MiniGameController:pauseGameRunning()
    self:pauseFrameUpdate()
    self.gameNode:pause()
    self:sendMsg(MiniGameController.MSG_GAME_PAUSE)
end

function MiniGameController:resumGameRunning()
    self:resumeFrameUpdate()
    self.gameNode:resume()
    self:sendMsg(MiniGameController.MSG_GAME_RESUME)
end


function MiniGameController:pauseFrameUpdate()
    if self.frameScheduler then
        scheduler:unscheduleScriptEntry(self.frameScheduler)
    end
    self.frameScheduler = nil
end

function MiniGameController:resumeFrameUpdate()
    if not self.frameScheduler then
        self.frameScheduler = scheduler:scheduleScriptFunc(handler(self, MiniGameController.frameUpdate), 0, false)
    end
end


function MiniGameController:initStartLayer()
    self.startLayer = StartLayer.new(self.uiNode, handler(self, MiniGameController.startPlay))
end

function MiniGameController:initRestartLayer()
    self.restartLayer = RestartLayer.new(self.uiNode, handler(self, MiniGameController.startPlay), handler(self, MiniGameController.onHome))
    self.restartLayer:hide()
end

function MiniGameController:initBackground()
    local bg = display.newSprite("Boxing/bg.png")
    bg:addTo(self.mainNode)
    bg:move(display.realCx, display.realCy)
    bg:setLocalZOrder(Define.Z_ORDER_BG)
end

function MiniGameController:onHome()
    self.pauseBtn:setVisible(true)
    self.resumeBtnLayer:setVisible(false)
    self:resumGameRunning()
    self:gameOver()
    self.gameNode:removeAllChildren()
    self.restartLayer:hide(false)
    self.startLayer:show(true)
    Sound.playBgMusic()
    self:sendMsg(MiniGameController.MSG_ON_HOME)
end

function MiniGameController:initPauseBtn()
    local pauseBtn = ccui.Button:create("Boxing/pause.png")
    pauseBtn:addTo(self.uiNode)
    local btnSize = pauseBtn:getContentSize()
    pauseBtn:setPosition(cc.p(80, display.realHeight-80))
    pauseBtn:setLocalZOrder(Define.Z_ORDER_CONTROL_UI)
    pauseBtn:setVisible(false)
    pauseBtn:addClickEventListener(function(sender)
        self.pauseFlag = true
        self.pauseBtn:setVisible(false)
        self.resumeBtnLayer:setVisible(true)
        self:pauseGameRunning()
        Sound.playEffect("Boxing/pause.mp3")
    end)
    self.pauseBtn = pauseBtn

    local resumBtnLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0), display.realWidth, display.realHeight)
    resumBtnLayer:addTo(self.uiNode)
    resumBtnLayer:setLocalZOrder(Define.Z_ORDER_CONTROL_UI)
    resumBtnLayer:setVisible(false)

    --local resumeBg = display.newSprite("Boxing/mask.png")
    --resumeBg:addTo(resumBtnLayer)
    --local size = resumeBg:getContentSize()
    --resumeBg:setScaleX(display.realWidth/size.width)
    --resumeBg:setScaleY(display.realHeight/size.height)
    --resumeBg:move(display.realCx, display.realCy)

    --local pausingLayer = display.newSprite("Boxing/mask.png")
    --pausingLayer:addTo(resumBtnLayer)
    --pausingLayer:setScaleX(display.realWidth/size.width)
    --pausingLayer:setScaleY(390/size.height)
    --pausingLayer:move(display.realCx, display.realCy+350)

    --local pausingLabel = cc.LabelTTF:create("暂停中", "", 80)
    --pausingLabel:setColor(cc.c3b(191, 204, 214))
    --pausingLabel:setOpacity(102)
    --pausingLabel:move(display.realCx, display.realCy+350)
    --pausingLabel:addTo(resumBtnLayer)

    local resumeBtn = ccui.Button:create("Boxing/btn_continue.png")
    resumeBtn:addTo(resumBtnLayer)
    resumeBtn:move(display.realCx, display.realCy+300)
    resumeBtn:addClickEventListener(function(sender)
        self.pauseFlag = false
        self.pauseBtn:setVisible(true)
        self.resumeBtnLayer:setVisible(false)
        self:resumGameRunning()
        Sound.playEffect("Boxing/start.mp3")
    end)
    self.resumeBtnLayer = resumBtnLayer

    local homeBtn = ccui.Button:create("Boxing/btn_home.png")
    homeBtn:addTo(resumBtnLayer)
    homeBtn:move(display.realCx, display.realCy)
    homeBtn:addClickEventListener(function (sender)
        self:onHome()
    end)

    local replayBtn = ccui.Button:create("Boxing/btn_replay.png")
    replayBtn:addTo(resumBtnLayer)
    replayBtn:move(display.realCx, display.realCy-300)
    replayBtn:addClickEventListener(function (sender)
        self.pauseBtn:setVisible(true)
        self.resumeBtnLayer:setVisible(false)
        self:resumGameRunning()
        self:gameOver()
        self.gameNode:removeAllChildren()
        self:startPlay()
        self:sendMsg(MiniGameController.MSG_ON_REPLAY)
    end)
end

function MiniGameController:sendMsg(name, ...)
    if not self.registerFuncTable[name] then
        return
    end
    for _, v in ipairs(self.registerFuncTable[name]) do
        v(...)
    end

end

-- 对外接口，注册回调，name包括
-- onSceneInitFinish 完成场景初始化
-- onGamePause 游戏暂停
-- onGameResume 游戏继续
-- onStartPlay 开始游戏
-- onTouchBegin 点击开始
function MiniGameController:registMsg(name, func)
    if not self.registerFuncTable[name] then
        self.registerFuncTable[name] = {}
    end
    table.insert(self.registerFuncTable[name], func)
end

-- 对外接口，游戏结束
function MiniGameController:gameOver()
    self.GamingFlag = false
    self.pauseFlag = false
    local curScore, maxScore = getScore()
    self.restartLayer:show()
    self.restartLayer:setScore(curScore, maxScore)
    self.pauseBtn:setVisible(false)
    self.resumeBtnLayer:setVisible(false)
    self.scoreLabel:setVisible(false)
    self:pauseFrameUpdate()
    Sound.playGameFailedMusic()
    self.gameNode:stopAllActions()
    self:sendMsg(MiniGameController.MSG_ON_GAME_OVER)
end

function MiniGameController:delayCall(func, delayTime, repeate)
    if not repeate then
        local delay = cc.DelayTime:create(delayTime)
        local sequence = cc.Sequence:create(delay, cc.CallFunc:create(func))
        self.gameNode:runAction(sequence)
    elseif repeate == -1 then
        local delay = cc.DelayTime:create(delayTime)
        local sequence = cc.Sequence:create(delay, cc.CallFunc:create(func))
        self.gameNode:runAction(cc.RepeatForever:create(sequence))
    else
        local delay = cc.DelayTime:create(delayTime)
        local sequence = cc.Sequence:create(delay, cc.CallFunc:create(func))
        self.gameNode:runAction(cc.Repeat:create(sequence, repeate))
    end
end

function MiniGameController:isGaming()
    return self.GamingFlag
end

function MiniGameController:isPausing()
    return self.pauseFlag
end

function MiniGameController:showScoreTip(x, y)
    self.scoreTip:move(x, y)
    self.scoreTip:setOpacity(255)
    self.scoreTip:stopAllActions()
    local act = cc.FadeTo:create(0.5, 0)
    self.scoreTip:runAction(act)
    local act2 = cc.MoveBy:create(0.5, cc.p(0, 50))
    self.scoreTip:runAction(act2)
end

return MiniGameController