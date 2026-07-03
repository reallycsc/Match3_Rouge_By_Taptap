local G = require "Game.Context"
local _ENV = G

local SCORE_KEY = "rune_survivor_high_score"
local PLAY_COUNT_KEY = "rune_survivor_play_count"

function IsCloudAvailable()
    return clientCloud ~= nil
end

function InitTapTapServices()
    if not IsCloudAvailable() then
        leaderboard_.status = "TapTap 云服务未就绪"
        print("TapTap cloud unavailable")
        return
    end

    leaderboard_.userId = clientCloud.userId
    leaderboard_.status = "TapTap 已登录"
    LoadCurrentUserNickname()
    RefreshLeaderboard()
    RefreshMyRank()
    LoadNumberConfigFromCloud()
end

function LoadCurrentUserNickname()
    if leaderboard_.userId == nil or GetUserNickname == nil then return end
    GetUserNickname({
        userIds = { leaderboard_.userId },
        onSuccess = function(nicknames)
            for _, info in ipairs(nicknames or {}) do
                if tostring(info.userId) == tostring(leaderboard_.userId) then
                    leaderboard_.nickname = info.nickname or "TapTap玩家"
                    return
                end
            end
            leaderboard_.nickname = "TapTap玩家"
        end,
        onError = function(errorCode)
            leaderboard_.nickname = "TapTap玩家"
            print("Get current user nickname failed: " .. tostring(errorCode))
        end,
    })
end

function SubmitScoreToLeaderboard()
    if not IsCloudAvailable() then return end
    local finalScore = score_ or 0
    clientCloud:Get(SCORE_KEY, {
        ok = function(values, iscores)
            local oldBest = iscores[SCORE_KEY] or 0
            leaderboard_.myBest = math.max(oldBest, finalScore)
            if finalScore > oldBest then
                clientCloud:BatchSet()
                    :SetInt(SCORE_KEY, finalScore)
                    :Add(PLAY_COUNT_KEY, 1)
                    :Save("符石生存者结算", {
                        ok = function()
                            leaderboard_.status = "新纪录已提交"
                            RefreshLeaderboard()
                            RefreshMyRank()
                        end,
                        error = function(code, reason)
                            leaderboard_.status = "分数提交失败"
                            print("Submit score failed: " .. tostring(reason))
                        end,
                    })
            else
                clientCloud:Add(PLAY_COUNT_KEY, 1, {
                    ok = function()
                        RefreshLeaderboard()
                        RefreshMyRank()
                    end,
                })
            end
        end,
        error = function(code, reason)
            leaderboard_.status = "最高分读取失败"
            print("Read high score failed: " .. tostring(reason))
        end,
    })
end

function RefreshMyRank()
    if not IsCloudAvailable() then return end
    clientCloud:GetUserRank(clientCloud.userId, SCORE_KEY, {
        ok = function(rank, scoreValue)
            leaderboard_.myRank = rank
            leaderboard_.myBest = scoreValue or leaderboard_.myBest or 0
        end,
        error = function(code, reason)
            print("Get user rank failed: " .. tostring(reason))
        end,
    })
end

function RefreshLeaderboard()
    if not IsCloudAvailable() or leaderboard_.loading then return end
    leaderboard_.loading = true
    leaderboard_.status = "排行榜加载中..."
    clientCloud:GetRankList(SCORE_KEY, 0, 10, {
        ok = function(rankList)
            local entries = {}
            local userIds = {}
            for index, item in ipairs(rankList or {}) do
                local userId = item.userId or item.player
                table.insert(entries, {
                    rank = index,
                    userId = userId,
                    nickname = "玩家" .. tostring(userId or ""),
                    score = item.iscore[SCORE_KEY] or 0,
                    playCount = item.iscore[PLAY_COUNT_KEY] or 0,
                    isMe = tostring(userId) == tostring(clientCloud.userId),
                })
                if userId ~= nil then
                    table.insert(userIds, userId)
                end
            end
            leaderboard_.entries = entries
            leaderboard_.loading = false
            leaderboard_.status = #entries > 0 and "排行榜已更新" or "暂无排行榜数据"

            if #userIds > 0 and GetUserNickname ~= nil then
                GetUserNickname({
                    userIds = userIds,
                    onSuccess = function(nicknames)
                        local nicknameMap = {}
                        for _, info in ipairs(nicknames or {}) do
                            nicknameMap[tostring(info.userId)] = info.nickname or "TapTap玩家"
                        end
                        for _, entry in ipairs(leaderboard_.entries) do
                            entry.nickname = nicknameMap[tostring(entry.userId)] or entry.nickname
                        end
                    end,
                    onError = function(errorCode)
                        print("Get rank nicknames failed: " .. tostring(errorCode))
                    end,
                })
            end
        end,
        error = function(code, reason)
            leaderboard_.loading = false
            leaderboard_.status = "排行榜加载失败"
            print("Get leaderboard failed: " .. tostring(reason))
        end,
        timeout = function()
            leaderboard_.loading = false
            leaderboard_.status = "排行榜加载超时"
        end,
    }, PLAY_COUNT_KEY)
end

function ToggleLeaderboard()
    leaderboard_.visible = not leaderboard_.visible
    if leaderboard_.visible then
        RefreshLeaderboard()
        RefreshMyRank()
    end
end
