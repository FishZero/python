
cc.FileUtils:getInstance():setPopupNotify(false)

class_map = class_map or {}

require "config"
require "cocos.init"

CONFIG_DESIGN_WIDTH = 1334
CONFIG_DESIGN_HEIGHT = 750

local function main()

    local scene = cc.Scene:create()
    local layer = require("zixun").new()
    scene:addChild(layer)

    cc.Director:getInstance():replaceScene(scene)
    cc.Director:getInstance():setDisplayStats(false)
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
