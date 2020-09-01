local ImageNumber = class("ImageNumber")

function ImageNumber:ctor(parent, x, y, num)
    local mainNode = cc.Node:create()
    mainNode:addTo(parent)
    mainNode:move(x, y)
    mainNode:setAnchorPoint(cc.p(0.5, 0.5))
    self.mainNode = mainNode
    self:setNumber(num)
end

function ImageNumber:getSingleNumberList(num)
    local singleNumberList = {}
    while num >= 10 do
        local oneNum = num % 10
        table.insert(singleNumberList, oneNum)
        num = math.floor(num / 10)
    end
    table.insert(singleNumberList, 1, num)
    return singleNumberList
end

function ImageNumber:setNumber(num)
    self.mainNode:removeAllChildren()
    local singleNumberList = self:getSingleNumberList(num)
    local w = 0
    local h = 0
    local lastX = 0
    for i, singleNum in ipairs(singleNumberList) do
        local path = string.format("Dunker/%d.png", singleNum)
        local sprite = display.newSprite(path)
        sprite:addTo(self.mainNode)
        sprite:setAnchorPoint(0, 0)
        local spriteSize = sprite:getContentSize()
        sprite:move(lastX+10, 0)
        lastX = lastX+10+spriteSize.width
        w = w + spriteSize.width
        h = spriteSize.height
    end
    self.mainNode:setContentSize(cc.size(w, h))
end

return ImageNumber