cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local function main()
    local time_seed = os.time()
    math.randomseed(time_seed)

    local scene = cc.Scene:createWithPhysics()
    local layer = require("Boxing.MainScene").new()
    layer:addTo(scene)
    cc.Director:getInstance():replaceScene(scene)
    cc.Director:getInstance():setDisplayStats(false)
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
