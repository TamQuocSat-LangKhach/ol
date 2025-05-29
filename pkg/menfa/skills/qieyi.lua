local qieyi = fk.CreateSkill{
  name = "qieyi",
}

Fk:loadTranslationTable{
  ["qieyi"] = "切议",
  [":qieyi"] = "出牌阶段开始时，你可以观看牌堆顶两张牌。若如此做，本回合你使用每种花色的第一张牌结算后，展示牌堆顶的一张牌，若这两张牌："..
  "颜色或类别相同，你获得展示牌；均不同，你将一张牌置于牌堆顶。",

  ["@qieyi-turn"] = "切议",
  ["#qieyi-ask"] = "切议：请将一张牌置于牌堆顶",

  ["$qieyi1"] = "张角将成祸患，何不庙胜先分之、弱之？",
  ["$qieyi2"] = "昔授尚书于华光，今剖石壁于朝堂。",
}

local U = require "packages/utility/utility"

qieyi:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qieyi.name) and player.phase == Player.Play
  end,
  on_use = function (self, event, target, player, data)
    U.viewCards(player, player.room:getNCards(2), qieyi.name)
  end,
})

qieyi:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:usedSkillTimes(qieyi.name, Player.HistoryTurn) > 0 and
      data.card.suit ~= Card.NoSuit and not table.contains(player:getTableMark("@qieyi-turn"), data.card:getSuitString(true)) and
      not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "@qieyi-turn", data.card:getSuitString(true))
    local id = room:getNCards(1)[1]
    room:showCards(id)
    if Fk:getCardById(id).color == data.card.color or Fk:getCardById(id).type == data.card.type then
      room:setCardEmotion(id, "judgegood")
      room:delay(1000)
      room:obtainCard(player, id, true, fk.ReasonJustMove, player, qieyi.name)
    else
      room:setCardEmotion(id, "judgebad")
      if not player:isNude() then
        local card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = qieyi.name,
          prompt = "#qieyi-ask",
          cancelable = false,
        })
        room:moveCards({
          ids = card,
          from = player,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = qieyi.name,
        })
      end
    end
  end,
})

return qieyi
