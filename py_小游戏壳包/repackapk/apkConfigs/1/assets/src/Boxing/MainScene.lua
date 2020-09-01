local MiniGameController = require("Boxing.MiniGameController")
local StartLayer = require("Boxing.StartLayer")
local RestartLayer = require("Boxing.RestartLayer")
local Sound = require("Boxing.Sound")
local MainScene = class("MainScene", function ()return cc.Layer:create() end)

local RIOT_STATE_MOVE = 0
local RIOT_STATE_OUT = 1
local RIOT_STATE_IN = 2
local RIOT_STATE_BOOM = 3
local RIOT_MOVE_START_SPEED = 2
local RIOT_OUT_START_SPEED = 20

local RIOT_ORI_POS_Y = 393
local RIOT_WIDTH = 223
local DESK_HEIGHT = 272
local RIOT_MAX_HEIGHT = 1000


function MainScene:ctor()
    local rotateNode = cc.Node:create()
    rotateNode:addTo(self)
    rotateNode:setContentSize(cc.size(display.height, display.width))
    rotateNode:setAnchorPoint(cc.p(0.5, 0.5))
    rotateNode:setRotation(-90)
    rotateNode:move(display.cx, display.cy)
    self.rotateNode = rotateNode
    display.realWidth = display.height
    display.realHeight = display.width
    display.realCx = display.cy
    display.realCy = display.cx

    self.gameFlow = MiniGameController:create(self.rotateNode, StartLayer, RestartLayer)
    self.gameFlow:registMsg(MiniGameController.MSG_ON_START, handler(self, self.onStartGame))
    self.gameFlow:registMsg(MiniGameController.MSG_ON_TOUCH_BEGIN, handler(self, self.onTouchBegin))
    self.gameFlow:registMsg(MiniGameController.MSG_GAME_PAUSE, handler(self, self.onGamePause))
    self.gameFlow:registMsg(MiniGameController.MSG_GAME_RESUME, handler(self, self.onGameResume))
    self.gameFlow:registMsg(MiniGameController.MSG_SCENE_INIT_FINISH, handler(self, self.onSceneInit))
    self.gameFlow:registMsg(MiniGameController.MSG_ON_GAME_OVER, handler(self, self.onGameOver))
    self.gameFlow:registMsg(MiniGameController.MSG_ON_HOME, handler(self, self.onHome))
    self.gameFlow:registMsg(MiniGameController.MSG_FRAME_UPDATE, handler(self, self.onFrameUpdate))
    self.gameFlow:start()
    self.gameFlow:delayCall(handler(self, self.setPhysicsWorld), 0.1)
end

function MainScene:onSceneInit()
    self.gameNode = cc.Node:create()
    self.gameNode:addTo(self.rotateNode)
end

function MainScene:onStartGame()
    self.gameNode:removeAllChildren()
    self:initRiot()
    self:initHambur()
    self:initDesk()
    self:initTime()
    self:initWhiteLight()
end

function MainScene:initWhiteLight()
    local whiteLight = cc.LayerColor:create(cc.c4b(255, 255, 255, 150), display.realWidth, display.realHeight)
    whiteLight:addTo(self.gameNode)
    whiteLight:setVisible(false)
    whiteLight:setLocalZOrder(5)
    self.whiteLight = whiteLight
end

function MainScene:onTouchBegin(loc)
    Sound.playEffect("Boxing/click.mp3")
    local click = cc.ParticleSystemQuad:create("Boxing/click.plist")
    click:setLocalZOrder(10)
    click:addTo(self.gameNode)
    click:move(loc.y, display.realHeight-loc.x)

    if self.gameFlow:isGaming() then
        if self.curRiotState == RIOT_STATE_MOVE then
            self:riotOut()
        end
    end
end

function MainScene:onGamePause()
    local scene = cc.Director:getInstance():getRunningScene()
    local world = scene:getPhysicsWorld()
    world:setAutoStep(false)
end

function MainScene:onGameResume()
    local scene = cc.Director:getInstance():getRunningScene()
    local world = scene:getPhysicsWorld()
    world:setAutoStep(true)
end

function MainScene:onGameOver()
end

function MainScene:onHome()
    self.gameNode:removeAllChildren()
end

function MainScene:onFrameUpdate()
    self:updateRiot()
end

function MainScene:gameOver()
    if self.whiteLight then
        self.whiteLight:stopAllActions()
        self.whiteLight:setVisible(false)
    end
    self.riotBody:setEnabled(false)
    local scene = cc.Director:getInstance():getRunningScene()
    local world = scene:getPhysicsWorld()
    world:removeAllBodies()
    self.gameFlow:gameOver()
end


function MainScene:initTime()
    self.timeLeft = 60
    local x, y = display.realCx, display.realHeight-80
    local timeBg = display.newSprite("Boxing/time_bg.png")
    timeBg:addTo(self.gameNode)
    timeBg:move(x, y)
    local timeLebel = cc.LabelTTF:create(tostring(self.timeLeft), "", 55)
    timeLebel:setColor(cc.c3b(255, 255, 255))
    timeLebel:move(x, y)
    timeLebel:addTo(self.gameNode)
    self.timeLebel = timeLebel
    self.gameFlow:delayCall(function ()
        self.timeLeft = self.timeLeft - 1
        self.timeLebel:setString(tostring(self.timeLeft))
        if self.timeLeft <= 0 then
            self:gameOver()
        end
    end, 1, -1)
end

function MainScene:initRiot()
    self.curRiotState = RIOT_STATE_MOVE
    self.curMoveSpeed = RIOT_MOVE_START_SPEED
    local man = display.newSprite("Boxing/man.png")
    man:addTo(self.gameNode)
    man:move(display.realCx, DESK_HEIGHT)
    man:setAnchorPoint(cc.p(0.5, 0.5))
    self.man = man
    self.moveLeft = true

    local riot = display.newSprite("Boxing/riot.png")
    riot:addTo(man)
    riot:move(375, RIOT_ORI_POS_Y)
    riot:setLocalZOrder(3)
    local body = cc.PhysicsBody:createBox(cc.size(111, 40))
    body:setCategoryBitmask(1)
    body:setContactTestBitmask(2)
    body:setCollisionBitmask(0)
    body:setGravityEnable(false)
    body:setDynamic(false)
    body:setEnabled(false)
    body:setPositionOffset(cc.p(-35, 0))
    body.riotFlag = true
    self.riotBody = body
    riot:setPhysicsBody(body)
    self.riot = riot

    local hand = display.newSprite("Boxing/hand.png")
    hand:addTo(riot)
    hand:setAnchorPoint(cc.p(0, 1))
    hand:move(40, 0)
    hand:setLocalZOrder(-1)
end

function MainScene:riotOut()
    self.curRiotState = RIOT_STATE_OUT
    self.riotBody:setEnabled(true)
end

function MainScene:riotIn()
    self.curRiotState = RIOT_STATE_IN
    self.riotBody:setEnabled(false)
end

function MainScene:riotMove()
    self.curRiotState = RIOT_STATE_MOVE
    self.riotBody:setVelocity(cc.p(0, 0))
end

function MainScene:updateRiot()
    if self.curRiotState == RIOT_STATE_MOVE then
        local ox = self.man:getPositionX()
        if self.moveLeft then
            local nx = ox-self.curMoveSpeed
            self.man:setPositionX(nx)
            if nx - RIOT_WIDTH / 2 < 0 then
                self.moveLeft = false
            end
        else
            local nx = ox+self.curMoveSpeed
            self.man:setPositionX(nx)
            if nx + RIOT_WIDTH /2 + 90 > display.realWidth then
                self.moveLeft = true
            end
        end
    elseif self.curRiotState == RIOT_STATE_OUT then
        local y = self.riot:getPositionY()
        local ny = y+RIOT_OUT_START_SPEED
        self.riot:setPositionY(ny)
        if ny >= RIOT_MAX_HEIGHT then
            self:riotIn()
        end
    elseif self.curRiotState == RIOT_STATE_IN then
        local y = self.riot:getPositionY()
        local ny = y-RIOT_OUT_START_SPEED
        self.riot:setPositionY(ny)
        if ny <= RIOT_ORI_POS_Y then
            self:riotMove()
        end
    end
end

function MainScene:initHambur()
    self.gameFlow:delayCall(function ()
        self:createOneHambur()
    end, 1, -1)
end

function MainScene:createOneHambur()
    local boomFlag
    local hamburType = math.random(1, 3)
    local path = string.format("Boxing/hambur%d.png", hamburType)
    if math.random() < 0.2 then
        boomFlag = true
        path = "Boxing/boom.png"
    end
    local hambur = display.newSprite(path)
    hambur:addTo(self.gameNode)
    hambur.hamburType = hamburType
    local body = cc.PhysicsBody:createBox(hambur:getContentSize())
    body:setCategoryBitmask(2)
    body:setContactTestBitmask(1)
    body:setCollisionBitmask(0)
    hambur:setPhysicsBody(body)
    body.boomFlag = boomFlag
    local vx = -(math.random() * 300 + 1000)
    if math.random() < 0.5 then
        hambur:move(-100, 250)
        body:setVelocity(cc.p(vx, 400))
    else
        hambur:move(display.realWidth+100, 250)
        body:setVelocity(cc.p(vx, -400))
    end
end

function MainScene:initDesk()
    local desk = display.newSprite("Boxing/desk.png")
    desk:addTo(self.gameNode)
    desk:setAnchorPoint(cc.p(0, 0))
end

function MainScene:boom(node)
    self.curRiotState = RIOT_STATE_BOOM
    Sound.playEffect("Boxing/boom.mp3")
    local boom = cc.ParticleSystemQuad:create("Boxing/boom.plist")
    boom:addTo(self.gameNode)
    boom:move(node:getPosition())
    node:setVisible(false)
    local actBlink = cc.Blink:create(0.5, 5)
    self.whiteLight:setVisible(true)
    self.whiteLight:runAction(actBlink)
    self.gameFlow:delayCall(function ()
        self:gameOver()
    end, 0.5, 1)
end

function MainScene:hit(node)
    Sound.playEffect("Boxing/hit.mp3")
    local x, y = node:getPosition()
    local emit = cc.ParticleSystemQuad:create(string.format("Boxing/explose%d.plist", node.hamburType))
    emit:addTo(self.gameNode)
    emit:move(x, y)
    node:setVisible(false)
    addScore(1)
    self.gameFlow:showScoreTip(x, y + 100)
    self.gameFlow:delayCall(function ()
        Sound.playEffect("Boxing/score.mp3")
    end, 0.1, 1)
    self:riotIn()
end

function MainScene:onContactBegin(contact)
    local bodyA = contact:getShapeA():getBody()
    local bodyB = contact:getShapeB():getBody()
    if bodyA.boomFlag then
        self:boom(bodyA:getNode())
    elseif bodyB.boomFlag then
        self:boom(bodyB:getNode())
    else
        if bodyA == self.riotBody then
            self:hit(bodyB:getNode())
        else
            self:hit(bodyA:getNode())
        end
    end
end


function MainScene:setPhysicsWorld()
    local scene = cc.Director:getInstance():getRunningScene()
    local world = scene:getPhysicsWorld()
    world:setGravity(cc.p(1000, 0))
    --world:setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)

    local contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(handler(self, self.onContactBegin), cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, self)
end

return MainScene
