local jiyun = fk.CreateSkill{
  name = "jiyun",
}

Fk:loadTranslationTable{
  ["jiyun"] = "集运",
  [":jiyun"] = "游戏开始时，将牌堆中不同类别的牌各一张置于你的武将牌上，称为“粮”。准备阶段，你可以令至多X名角色各摸一张牌"..
  "（X为你的“粮”数，至少为1），当这些角色使用以此法摸到的牌结算结束后，若你的“粮”数少于3，将之作为“粮”置于你的武将牌上。",

  ["ol__lifeng_liang"] = "粮",
  ["#jiyun-choose"] = "集运：令至多%arg名角色各摸一张牌，这些牌被使用后将置为“粮”",
  ["@@jiyun-inhand"] = "集运",

  ["$jiyun1"] = "",
  ["$jiyun2"] = "",
}

jiyun:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jiyun.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, type in ipairs({"basic", "trick", "equip"}) do
      local card = room:getCardsFromPileByRule(".|.|.|.|.|"..type)
      if #card > 0 then
        table.insert(cards, card[1])
      end
    end
    if #cards > 0 then
      player:addToPile("ol__lifeng_liang", cards, true, jiyun.name, player)
    end
  end,
})

jiyun:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiyun.name) and player.phase == Player.Start
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = math.max(#player:getPile("ol__lifeng_liang"), 1)
    local tos = room:askToChoosePlayers(player, {
      skill_name = jiyun.name,
      min_num = 1,
      max_num = n,
      targets = room.alive_players,
      prompt = "#jiyun-choose:::"..n,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        p:drawCards(1, jiyun.name, "top", {"@@jiyun-inhand", player.id})
      end
    end
  end,
})

jiyun:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiyun.name) and #player:getPile("ol__lifeng_liang") < 3 and
      data.extra_data and data.extra_data.jiyun == player.id and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:addToPile("ol__lifeng_liang", data.card, true, jiyun.name, player)
  end,
})

jiyun:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card:getMark("@@jiyun-inhand") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiyun = data.card:getMark("@@jiyun-inhand")
  end,
})

return jiyun
