local cangxin = fk.CreateSkill{
  name = "cangxin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cangxin"] = "藏心",
  [":cangxin"] = "锁定技，摸牌阶段开始时，你展示牌堆底三张牌并摸其中<font color='red'>♥</font>牌数的牌。"..
  "当你每回合首次受到伤害时，你展示牌堆底三张牌并弃置其中任意张牌，令伤害值-X（X为以此法弃置的<font color='red'>♥</font>牌数）。",

  ["#cangxin-discard"] = "藏心：你可以弃置其中任意张牌，每弃置一张<font color='red'>♥</font>牌伤害-1",

  ["$cangxin1"] = "世间百味，品在唇而味在心。",
  ["$cangxin2"] = "我藏风雨于心，故而衣不沾雨。",
}

cangxin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cangxin.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:turnOverCardsFromDrawPile(player, room:getNCards(3, "bottom"), cangxin.name)
    room:delay(1500)
    local n = #table.filter(cards, function (id)
      return Fk:getCardById(id).suit == Card.Heart
    end)
    if n > 0 then
      player:drawCards(n, cangxin.name)
    end
    room:returnCardsToDrawPile(player, cards, cangxin.name, "bottom")
  end,
})
cangxin:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cangxin.name) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:turnOverCardsFromDrawPile(player, room:getNCards(3, "bottom"), cangxin.name)
    local to_throw = room:askToChooseCards(player, {
      target = player,
      min = 0,
      max = 3,
      flag = { card_data = {{ "Bottom", cards }} },
      skill_name = cangxin.name,
      prompt = "#cangxin-discard",
    })
    if #to_throw > 0 then
      local n = #table.filter(to_throw, function (id)
        return Fk:getCardById(id).suit == Card.Heart
      end)
      data:changeDamage(-n)
      room:moveCards {
        ids = to_throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = cangxin.name,
        proposer = player,
      }
    end
    room:returnCardsToDrawPile(player, cards, cangxin.name, "bottom")
  end,
})

return cangxin
