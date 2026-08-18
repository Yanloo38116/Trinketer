--[[
    Trinketer - 饰品人
    Author: Yanloo
    Version: 1.0.1
    适配：以撒的结合：忏悔 (Repentance)
]]

local mod = RegisterMod("Trinketer - 饰品人", 1)
local game = Game()
local itemConfig = Isaac.GetItemConfig()

-- ============================================================
-- 常量与状态
-- ============================================================

-- 角色类型（运行时根据 players.xml 中的 name 获取）
local TRINKETER = Isaac.GetPlayerTypeByName("TRINKETER_NAME", false)
if TRINKETER == -1 or TRINKETER == nil then
	TRINKETER = Isaac.GetPlayerTypeByName("#TRINKETER_NAME", false)
end
if TRINKETER == -1 or TRINKETER == nil then
	TRINKETER = Isaac.GetPlayerTypeByName("Trinketer", false)
end

-- 本局咕噜药对应的 PillColor（缓存）
local gulpPillColor = nil

-- 金色饰品标记位
local GOLDEN_FLAG = TrinketType.TRINKET_GOLDEN_FLAG

-- ============================================================
-- 工具函数
-- ============================================================

--- 检查指定玩家是否为 Trinketer
local function IsTrinketer(player)
    return player ~= nil and player:GetPlayerType() == TRINKETER
end

--- 获取当前房间中任意一个 Trinketer 玩家（支持多人）
local function GetTrinketerPlayer()
    for i = 0, game:GetNumPlayers() - 1 do
        local p = game:GetPlayer(i)
        if IsTrinketer(p) then
            return p
        end
    end
    return nil
end

--- 获取本局游戏中咕噜药(Gulp!)对应的 PillColor
local function GetGulpPillColor()
    if gulpPillColor ~= nil then
        return gulpPillColor
    end
    local pool = game:GetItemPool()
    -- 普通药丸颜色范围 0~13
    for color = 0, 13 do
        if pool:GetPillEffect(color) == PillEffect.PILLEFFECT_GULP then
            gulpPillColor = color
            return color
        end
    end
    gulpPillColor = 0
    return 0
end

--- 判断指定基础饰品是否存在金色版本
local function HasGoldenVariant(trinketID)
    local cfg = itemConfig:GetTrinket(trinketID)
    if cfg == nil then return false end
    return cfg.GoldenModel ~= nil and cfg.GoldenModel ~= ""
end

--- 在指定位置生成若干个随机饰品（散开排列）
local function SpawnRandomTrinkets(position, count)
    local pool = game:GetItemPool()
    for i = 1, count do
        local trinketID = pool:GetTrinket()
        local angle = (i - 1) * (math.pi * 2 / count)
        local offset = Vector(math.cos(angle) * 30, math.sin(angle) * 30)
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_TRINKET,
            trinketID,
            position + offset,
            Vector.Zero,
            nil
        )
    end
end

-- ============================================================
-- 初始物品
-- ============================================================

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    -- 每局开始时重置药丸颜色缓存
    gulpPillColor = nil

    if isContinued then return end

    local player = GetTrinketerPlayer()
    if not player then return end

    -- 初始药丸：咕噜药
    local color = GetGulpPillColor()
    player:SetPill(0, color)

    -- 初始饰品：随机普通饰品
    local pool = game:GetItemPool()
    local trinketID = pool:GetTrinket()
    player:AddTrinket(trinketID, true)
end)

-- ============================================================
-- 机制 1：药丸转换（MC_PRE_ENTITY_SPAWN 方案）
-- 在药丸实体生成前修改其 SubType，避免 MC_POST_PICKUP_INIT 中
-- 修改 SubType 导致的药丸消失问题（仿照 PHD 等道具的替换思路）
-- ============================================================

mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, entityType, variant, subtype, position, velocity, spawner, seed)
    if entityType ~= EntityType.ENTITY_PICKUP then return end
    if variant ~= PickupVariant.PICKUP_PILL then return end

    -- 仅当有 Trinketer 玩家在场时生效
    if not GetTrinketerPlayer() then return end

    -- 不影响金色药丸等特殊药丸
    if subtype >= PillColor.PILL_GOLD then return end

    if math.random() < 0.5 then
        -- 返回修改后的生成参数，实体将以咕噜药颜色生成
        return {entityType, variant, GetGulpPillColor(), seed}
    end
end)

-- ============================================================
-- 机制 2：道具品质拦截
-- 0 级道具：100% 阻止，变为 2 个随机饰品
-- 1 级道具：25% 概率阻止，变为 3 个随机饰品
-- 覆盖所有途径
-- ============================================================

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then return end

    if not GetTrinketerPlayer() then return end

    local item = itemConfig:GetCollectible(pickup.SubType)
    if not item then return end

    local quality = item.Quality
    local trinketCount = 0

    if quality == 0 then
        trinketCount = 2
    elseif quality == 1 then
        if math.random() < 0.25 then
            trinketCount = 3
        else
            return
        end
    else
        return
    end

    local pos = pickup.Position
    pickup:Remove()
    SpawnRandomTrinkets(pos, trinketCount)
end)

-- ============================================================
-- 机制 3：长子名分 (Birthright)
-- 使用咕噜药时：
--   - 若当前饰品有金色版本 → 先变为金色再吞下
--   - 若当前饰品已是金色 → 在地面生成 1 个随机饰品
-- ============================================================

mod:AddCallback(ModCallbacks.MC_USE_PILL, function(_, pillEffect, player, useFlags)
    if not IsTrinketer(player) then return end
    if pillEffect ~= PillEffect.PILLEFFECT_GULP then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    local currentTrinket = player:GetTrinket(0)
    if currentTrinket == TrinketType.TRINKET_NULL then return end

    local isGolden = currentTrinket >= GOLDEN_FLAG
    local baseID = isGolden and (currentTrinket - GOLDEN_FLAG) or currentTrinket

    if isGolden then
        -- 已是金色饰品：生成 1 个随机饰品掉落在地面
        local pool = game:GetItemPool()
        local trinketID = pool:GetTrinket()
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_TRINKET,
            trinketID,
            player.Position + Vector.Random() * 20,
            Vector.Zero,
            nil
        )
    else
        -- 普通饰品：若有金色版本，先替换为金色再让咕噜药吞下
        if HasGoldenVariant(baseID) then
            -- 先移除当前普通饰品
            player:TryRemoveTrinket(currentTrinket)
            -- 添加对应金色版本（firstTime=false 避免重复触发拾取效果）
            player:AddTrinket(baseID + GOLDEN_FLAG, false)
        end
    end
end)

-- ============================================================
-- EID (External Item Descriptions) 适配
-- ============================================================

local function EID_Compat()
    if not EID then return end

    local playerDescZH = "饰品人 Trinketer#" ..
        "所有药丸有 50% 概率变为咕噜药#" ..
        "0 级道具被阻止并转化为 2 个随机饰品#" ..
        "1 级道具有 25% 概率被阻止并转化为 3 个随机饰品"

    local playerDescEN = "Trinketer#" ..
        "50% of pills become Gulp! on spawn#" ..
        "Quality 0 items are replaced by 2 random trinkets#" ..
        "Quality 1 items have 25% chance to be replaced by 3 random trinkets"

    local birthrightDescZH = "更好的饰品、更多的饰品！#" ..
        "使用咕噜药时，若当前饰品存在金色版本，则先变为金色版本再吞下#" ..
        "若当前饰品已是金色饰品，则在地面生成 1 个随机饰品"

    local birthrightDescEN = "Better trinkets, more trinkets!#" ..
        "When using Gulp!, if current trinket has a golden variant, convert to golden before gulping#" ..
        "If current trinket is already golden, spawn a random trinket on the ground"

    -- 角色描述
    if EID.addPlayerDescription then
        pcall(function()
            EID:addPlayerDescription(TRINKETER, playerDescZH, "饰品人", "zh_cn")
            EID:addPlayerDescription(TRINKETER, playerDescEN, "Trinketer", "en_us")
        end)
    elseif EID.addDescription then
        pcall(function()
            EID:addDescription("Player", TRINKETER, playerDescZH, "饰品人", "zh_cn")
            EID:addDescription("Player", TRINKETER, playerDescEN, "Trinketer", "en_us")
        end)
    end

    -- 长子名分描述
    if EID.addBirthrightDescription then
        pcall(function()
            EID:addBirthrightDescription(TRINKETER, birthrightDescZH, "zh_cn")
            EID:addBirthrightDescription(TRINKETER, birthrightDescEN, "en_us")
        end)
    end
end

EID_Compat()
