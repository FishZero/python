local userDefault = cc.UserDefault:getInstance()
local User = {}

local FIRST_GAME_KEY = "firstgame"


function User.isFirstGame()
    return userDefault:getBoolForKey(FIRST_GAME_KEY, true)
end

function User.saveFirstGame()
    userDefault:setBoolForKey(FIRST_GAME_KEY, false)
end

return User