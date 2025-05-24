local tairan = fk.CreateSkill{
  name = "tairan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tairan"] = "泰然",
  [":tairan"] = "锁定技，回合结束时，你回复体力至体力上限，将手牌摸至体力上限；出牌阶段开始时，你失去上次以此法回复的体力值，弃置以此法获得的手牌。",

  ["@@tairan-inhand"] = "泰然",

  ["$tairan1"] = "撼山易，撼我司马氏难。",
  ["$tairan2"] = "云卷云舒，处之泰然。",
}

tairan:addEffect(fk.TurnEnd, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tairan.name) and
      (player:isWounded() or player:getHandcardNum() < player.maxHp)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      local n = player:getLostHp()
      room:setPlayerMark(player, "tairan_hp", n)
      room:recover{
        who = player,
        num = n,
        recoverBy = player,
        skillName = tairan.name,
      }
      if player.dead then return end
    end
    if player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum(), tairan.name, nil, "@@tairan-inhand")
    end
  end,
})
tairan:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tairan.name) and player.phase == Player.Play and
      (player:getMark("tairan_hp") > 0 or
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@tairan-inhand") > 0 and not player:prohibitDiscard(id)
      end))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("tairan_hp")
    if n > 0 then
      room:setPlayerMark(player, "tairan_hp", 0)
      room:loseHp(player, n, tairan.name)
    end
    if not player.dead then
      local cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@tairan-inhand") > 0 and not player:prohibitDiscard(id)
      end)
      if #cards > 0 then
        room:throwCard(cards, tairan.name, player, player)
      end
    end
  end,
})

return tairan
