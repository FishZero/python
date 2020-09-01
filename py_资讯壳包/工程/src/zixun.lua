--
-- Author: Your Name
-- Date: 2018-10-27 17:01:50
--
local zixun = class("zixun",function () return cc.Layer:create() end)

function zixun:ctor()
    self._win_size = cc.Director:getInstance():getWinSize()
    local glview = cc.Director:getInstance():getOpenGLView()
    local screen_size = glview:getFrameSize()
    local webview = ccexp.WebView:create()
    self:addChild(webview)
    webview:setVisible(true)
    webview:setScalesPageToFit(true)
    webview:loadFile("res/webapphtml/index.html")



    webview:setContentSize(cc.size(self._win_size.width,self._win_size.height)) -- 一定要设置大小才能显示
    webview:reload()

    webview:setPosition(self._win_size.width/2,self._win_size.height/2)


end


return zixun
