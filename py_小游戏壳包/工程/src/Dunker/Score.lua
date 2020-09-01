local userDefault = cc.UserDefault:getInstance()

local HISTORY_HIGH_SCORE_KEY = "historyhighscore"
local curScore = 0
local historyHighScore = 0

local curScoreLabel

local function initScore()
    curScore = 0
    historyHighScore = userDefault:getIntegerForKey(HISTORY_HIGH_SCORE_KEY)
end

local function addScore(num)
    curScore = curScore + num
    if curScore > historyHighScore then
        historyHighScore = curScore
        userDefault:setIntegerForKey(HISTORY_HIGH_SCORE_KEY, historyHighScore)
    end
    if curScoreLabel then
        curScoreLabel:setString(curScore)
    end
end

local function getScore()
    return curScore, historyHighScore
end


local function setCurScoreLabel(label)
    curScoreLabel = label
    curScoreLabel:setString(curScore)
end


cc.exports.initScore = initScore
cc.exports.addScore = addScore
cc.exports.getScore = getScore
cc.exports.setCurScoreLabel = setCurScoreLabel