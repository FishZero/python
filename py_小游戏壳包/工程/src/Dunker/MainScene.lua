local MiniGameController = require("Dunker.MiniGameController")
local StartLayer = require("Dunker.StartLayer")
local RestartLayer = require("Dunker.RestartLayer")
local Sound = require("Dunker.Sound")
local MainScene = class("MainScene", function ()return cc.Layer:create() end)

local BALL_OFFSET_Y = 500
local BALL_HIGH_MAX = BALL_OFFSET_Y*2
local GRAVITY_Y = 520
local ALL_TIME = 60

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
    self.gameFlow:registMsg(MiniGameController.MSG_ON_TOUCH_ENDED, handler(self, self.onTouchEnded))
    self.gameFlow:registMsg(MiniGameController.MSG_ON_TOUCH_CANCELLED, handler(self, self.onTouchCancelled))
    self.gameFlow:start()
    self.gameFlow:delayCall(handler(self, self.setPhysicsWorld), 0.1)


end

function MainScene:onSceneInit()
    self.gameNode = cc.Node:create()
    self.gameNode:addTo(self.rotateNode)
end

function MainScene:onStartGame()
    self.gameNode:removeAllChildren()
    self.startStep = false
    self.lastTime = ALL_TIME
    self:initTime()
    self:initBall()
    self:initNet()
    self:startScroll()
end

function MainScene:onTouchBegin(loc)
    if self.gameFlow:isGaming() then
        if not self.startStep then
            cc.Director:getInstance():getRunningScene():getPhysicsWorld():setAutoStep(true)
        end
        self.touchBeginPos = cc.p(loc.y, display.width-loc.x)
        --print("点击开始", loc.y, display.width-loc.x)
    end
end


function MainScene:onTouchEnded(loc)
    if self.gameFlow:isGaming() and self.touchBeginPos then
        --print("点击结束", loc.y, loc.x)
        self:shoot(self.touchBeginPos, cc.p(loc.y, display.width-loc.x))
    end
end

function MainScene:onTouchCancelled(loc)
    self.touchBeginPos = nil
    --if self.gameFlow:isGaming() and self.touchBeginPos then
    --end
end


function MainScene:onGamePause()
    local scene = cc.Director:getInstance():getRunningScene()
    local world = scene:getPhysicsWorld()
    world:setAutoStep(false)
    for _, ball in pairs(self.ballList) do
        ball:pause()
    end
    for _, net in pairs(self.netList) do
        net:pause()
    end
    for _, realNet in pairs(self.realNextList) do
        realNet:pause()
    end
end

function MainScene:onGameResume()
    local scene = cc.Director:getInstance():getRunningScene()
    local world = scene:getPhysicsWorld()
    world:setAutoStep(true)
    for _, ball in pairs(self.ballList) do
        ball:resume()
    end
    for _, net in pairs(self.netList) do
        net:resume()
    end
    for _, realNet in pairs(self.realNextList) do
        realNet:resume()
    end
end

function MainScene:onGameOver()
end

function MainScene:onHome()
    self.gameNode:removeAllChildren()
end

function MainScene:onFrameUpdate()
    if self.gameFlow:isGaming() then
    end
end

function MainScene:gameOver()
    self.gameFlow:gameOver()
end


function MainScene:onContactBegin(contact)
    local bodyA = contact:getShapeA():getBody()
    local bodyB = contact:getShapeB():getBody()
    if bodyA.netFlag or bodyB.netFlag then
        Sound.playEffect("Dunker/crash.mp3")
        return true
    end
    addScore(1)
    self.gameFlow:showScoreTip(display.realCx, display.realHeight*0.8)
    --if not self.startStep then
    --    self:startScroll()
    --end
    Sound.playEffect("Dunker/score.mp3")
end

function MainScene:initTime()
    self.lastTime = ALL_TIME
    local timeLabel = cc.LabelTTF:create("倒计时："..tostring(self.lastTime), "", 40)
    timeLabel:setColor(cc.c3b(255, 255, 255))
    local x, y = display.realCx, display.realHeight-40
    timeLabel:move(x, y)
    timeLabel:addTo(self.gameNode)
    self.gameFlow:delayCall(function ()
        self.lastTime = self.lastTime - 1
        timeLabel:setString("倒计时："..tostring(self.lastTime))
        if self.lastTime <= 0 then
            self:gameOver()
        end
    end, 1, 60)
end

function MainScene:initBall()
    self.ballList = {}
    local shadow = display.newSprite("Dunker/shadow.png")
    shadow:addTo(self.gameNode)
    shadow:move(display.realCx, display.realCy-BALL_OFFSET_Y-67)
    self.shadow = shadow
    self:createOneBall()
end

function MainScene:createOneBall()
    local ball = display.newSprite("Dunker/man.png")
    ball:addTo(self.gameNode)
    ball:setLocalZOrder(30)
    ball:move(display.realCx, display.realCy-BALL_OFFSET_Y)
    table.insert(self.ballList, ball)
    self.ball = ball
    ball:setScale(0.01)
    self.shadow:setScale(0.01)
    local act = cc.ScaleTo:create(0.1, 1)
    ball:runAction(act)
    self.shadow:runAction(act:clone())


    --local vers = {
    --    cc.p(-58, -39),
    --    cc.p(-55, 19),
    --    cc.p(-23, 50),
    --    cc.p(20, 52),
    --    cc.p(58, 10),
    --    cc.p(54, 49),
    --    cc.p(36, 66),
    --    cc.p(-32, 66),
    --}

    local body1 = cc.PhysicsBody:createBox(cc.size(110, 120))
    body1:setCategoryBitmask(1)
    body1:setContactTestBitmask(0)
    body1:setGravityEnable(false)
    body1:setCollisionBitmask(0)
    ball:setPhysicsBody(body1)
    ball.ballBody = body1

end

function MainScene:shoot(startPos, endPos)
    if endPos.y <= startPos.y then  -- 不是向上划不处理
        return
    end
    local yspeed = BALL_HIGH_MAX
    local yxratio = (endPos.y - startPos.y) / (endPos.x - startPos.x)
    local px = yspeed / yxratio

    self.ball.ballBody:setGravityEnable(true)
    self.ball.ballBody:setVelocity(cc.p(-yspeed, px))

    local shootTime = yspeed / GRAVITY_Y
    local ball = self.ball
    local ballBody = self.ball.ballBody
    local act1 = cc.ScaleTo:create(shootTime, 0.5)
    local act = cc.Sequence:create(act1, cc.CallFunc:create(function ()
        ballBody:setCollisionBitmask(3)
        ballBody:setContactTestBitmask(6)
        ball:setLocalZOrder(10)
    end))
    self.ball:runAction(act)
    Sound.playEffect("Dunker/shoot.mp3")
    self:createOneBall()
end

function MainScene:initNet()
    self.netList = {}
    self.realNextList = {}
    for i=1, 3 do
        local x, y = display.realCx, display.realCy+BALL_OFFSET_Y-150-(205*(i-1))
        local rod = display.newSprite("Dunker/rod.png")
        rod:addTo(self.gameNode)
        rod:move(x, y)
        rod:setLocalZOrder(3-i)

        local rodSize = rod:getContentSize()
        local net = display.newSprite("Dunker/net.png")
        net:addTo(rod)
        net:move(rodSize.width/2, rodSize.height/2)
        table.insert(self.netList, net)

        local realNet = display.newSprite("Dunker/realnet.png")
        realNet:addTo(self.gameNode)
        realNet:setLocalZOrder(20)
        realNet:move(x, y-67)
        table.insert(self.realNextList, realNet)

        local node1 = cc.Node:create()
        node1:addTo(net)
        node1:move(62, 102)
        local body1 = cc.PhysicsBody:createCircle(10)
        body1:setDynamic(false)
        body1:setCategoryBitmask(2)
        body1:setCollisionBitmask(1)
        body1:setContactTestBitmask(1)
        body1.netFlag = true
        node1:setPhysicsBody(body1)

        local node2 = cc.Node:create()
        node2:addTo(net)
        node2:move(190, 102)
        local body2 = cc.PhysicsBody:createCircle(10)
        body2:setDynamic(false)
        body2:setCategoryBitmask(2)
        body2:setCollisionBitmask(1)
        body2:setContactTestBitmask(1)
        body2.netFlag = true
        node2:setPhysicsBody(body2)

        local scoreNode = cc.Node:create()
        scoreNode:addTo(net)
        scoreNode:move(128, 80)
        local scoreBody = cc.PhysicsBody:createBox(cc.size(95, 10))
        scoreBody:setDynamic(false)
        scoreBody:setCategoryBitmask(4)
        scoreBody:setContactTestBitmask(1)
        scoreBody:setCollisionBitmask(0)
        scoreNode:setPhysicsBody(scoreBody)
    end
end

function MainScene:startScroll()
    self.startStep = true
    local moveTime = 3
    for i=1, 3 do
        if i == 1 or i == 3 then
            local act1 = cc.MoveBy:create(moveTime/2, cc.p(-248, 0))
            local net = self.netList[i]
            net:runAction(act1)
            local realNet = self.realNextList[i]
            realNet:runAction(act1:clone())
            self.gameFlow:delayCall(function ()
                local act2 = cc.MoveBy:create(moveTime, cc.p(496, 0))
                local act3 = cc.MoveBy:create(moveTime, cc.p(-496, 0))
                local seq = cc.Sequence:create(act2, act3)
                net:runAction(cc.RepeatForever:create(seq))
                realNet:runAction(cc.RepeatForever:create(seq:clone()))
            end, moveTime/2, 1)
        else
            local act1 = cc.MoveBy:create(moveTime/2, cc.p(248, 0))
            local net = self.netList[i]
            net:runAction(act1)
            local realNet = self.realNextList[i]
            realNet:runAction(act1:clone())
            self.gameFlow:delayCall(function ()
                local act2 = cc.MoveBy:create(moveTime, cc.p(-496, 0))
                local act3 = cc.MoveBy:create(moveTime, cc.p(496, 0))
                local seq = cc.Sequence:create(act2, act3)
                net:runAction(cc.RepeatForever:create(seq))
                realNet:runAction(cc.RepeatForever:create(seq:clone()))
            end, moveTime/2, 1)
        end

    end
end


function MainScene:setPhysicsWorld()
    local scene = cc.Director:getInstance():getRunningScene()
    local world = scene:getPhysicsWorld()
    world:setGravity(cc.p(520, 0))
    --world:setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)

    local contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(handler(self, self.onContactBegin), cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, self)
end



return MainScene
