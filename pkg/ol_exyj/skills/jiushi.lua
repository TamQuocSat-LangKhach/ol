local jiushi = fk.CreateSkill{
  name = "ol_ex__jiushi",
}

Fk:loadTranslationTable{
  ["ol_ex__jiushi"] = "酒诗",
  [":ol_ex__jiushi"] = "若你的武将牌正面朝上，你可以翻面视为使用一张【酒】。若你的武将牌背面朝上，你使用“落英”牌无距离限制且不可被响应。"..
  "当你受到伤害时或当你于回合外发动〖落英〗累计获得至少X张牌后（X为你的体力上限），若你的武将牌背面朝上，你可以翻至正面。",

  ["#ol_ex__jiushi"] = "酒诗：你可以翻面，视为使用一张【酒】",
  ["@ol_ex__jiushi_count"] = "酒诗",
}

jiushi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ol_ex__jiushi_count", 0)
end)

jiushi:addEffect("viewas", {
  anim_type = "support",
  prompt = "#ol_ex__jiushi",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self)
    local c = Fk:cloneCard("analeptic")
    c.skillName = jiushi.name
    return c
  end,
  enabled_at_play = function (self, player)
    return player.faceup
  end,
  enabled_at_response = function (self, player, response)
    return player.faceup and not response
  end,
})

jiushi:addEffect(fk.DamageInflicted, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiushi.name) and not player.faceup
  end,
  on_use = function (self, event, target, player, data)
    player:turnOver()
  end,
})

jiushi:addEffect(fk.AfterCardsMove, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(jiushi.name) and not player.faceup then
      for _, move in ipairs(data) do
        if move.skillName == "luoying" and move.to == player and player:getMark("@ol_ex__jiushi_count") >= player.maxHp then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:turnOver()
  end,

  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(jiushi.name, true) and not player.faceup then
      for _, move in ipairs(data) do
        if move.skillName == "luoying" and move.to == player and player.room.current ~= player then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.skillName == "luoying" and move.to == player then
        room:addPlayerMark(player, "@ol_ex__jiushi_count", #move.moveInfo)
      end
    end
  end,
})

jiushi:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(jiushi.name) and not player.faceup then
      return target == player and data.card:getMark("@@luoying-inhand") > 0 and
        (data.card.trueName == "slash" or data.card:isCommonTrick())
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

jiushi:addEffect(fk.TurnedOver, {
  can_refresh = function (self, event, target, player, data)
    return player.faceup and player:getMark("@ol_ex__jiushi_count") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@ol_ex__jiushi_count", 0)
  end,
})

jiushi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(jiushi.name) and not player.faceup and card and card:getMark("@@luoying-inhand") > 0
  end,
})

return jiushi
