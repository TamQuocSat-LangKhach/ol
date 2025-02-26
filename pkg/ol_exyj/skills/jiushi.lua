local this = fk.CreateSkill{
  name = "ol_ex__jiushi",
}

this:addEffect("viewas", {
  anim_type = "support",
  pattern = "analeptic",
  prompt = "#ol_ex__jiushi",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self)
    local c = Fk:cloneCard("analeptic")
    c.skillName = this.name
    return c
  end,
  enabled_at_play = function (self, player)
    return player.faceup
  end,
  enabled_at_response = function (self, player, response)
    return player.faceup and not response
  end,
})

this:addEffect(fk.Damaged, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(this.name) and not player.faceup then
      return target == player and (data.extra_data or {}).ol_ex__jiushi_check
    end
  end,
  on_use =function (self, event, target, player, data)
    player:turnOver()
  end,
})

this:addEffect(fk.AfterCardsMove, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(this.name) and not player.faceup then
      for _, move in ipairs(data) do
        if move.skillName == "luoying" and move.to == player.id then
          if player:getMark("@ol_ex__jiushi_count") >= player.maxHp then
            return true
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:turnOver()
  end,
})

this:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(this.name) and not player.faceup then
      return target == player and data.card:getMark("@@luoying-inhand") > 0 and (data.card.trueName == "slash" or data.card:isCommonTrick())
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
  end
})

this:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self, true) and not player.faceup then
      return target == player
    end
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ol_ex__jiushi_check = true
  end
})

this:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self, true) and not player.faceup then
      for _, move in ipairs(data) do
        if move.skillName == "luoying" and move.to == player.id and player.phase == Player.NotActive then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.skillName == "luoying" and move.to == player.id then
        room:addPlayerMark(player, "@ol_ex__jiushi_count", #move.moveInfo)
      end
    end
  end
})

this:addEffect(fk.TurnedOver, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("@ol_ex__jiushi_count") > 0 then
      return player.faceup
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@ol_ex__jiushi_count", 0)
  end
})

this:addEffect(fk.EventLoseSkill, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("@ol_ex__jiushi_count") > 0 then
      return target == player and data == self
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@ol_ex__jiushi_count", 0)
  end
})

this:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(this.name) and not player.faceup and card:getMark("@@luoying-inhand") > 0
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__jiushi"] = "酒诗",
  [":ol_ex__jiushi"] = "若你的武将牌正面朝上，你可以翻面视为使用一张【酒】。若你的武将牌背面朝上，你使用“落英”牌无距离限制且不可被响应。"..
  "当你受到伤害时或当你于回合外发动〖落英〗累计获得至少X张牌后（X为你的体力上限），若你的武将牌背面朝上，你可以翻至正面。",

  ["#ol_ex__jiushi_targetmod"] = "酒诗",
  ["#ol_ex__jiushi"] = "酒诗：你可以翻面，视为使用一张【酒】",
  ["@ol_ex__jiushi_count"] = "酒诗",
}

return this
