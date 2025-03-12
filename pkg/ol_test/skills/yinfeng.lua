local yinfeng = fk.CreateSkill{
  name = "yinfeng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yinfeng"] = "引锋",
  [":yinfeng"] = "锁定技，游戏开始时，你将【赤血青锋】置入手牌。【赤血青锋】因弃置进入弃牌堆后，你失去1点体力并获得之。"..
  "当其他角色得到你的手牌后，若你手牌中有【赤血青锋】，你对其造成1点伤害；若其获得了【赤血青锋】，其对你造成1点伤害。",

  ["$yinfeng1"] = "丞相委我以重任，恩必践以剑在人在！",
  ["$yinfeng2"] = "这叫青釭剑，等闲之辈可背不起！",
}

yinfeng:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(yinfeng.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:printCard("blood_sword", Card.Spade, 6)
    room:obtainCard(player, card, true, fk.ReasonJustMove, player, yinfeng.name)
  end,
})
yinfeng:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(yinfeng.name) then
      local choices = {}
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "blood_sword" then
              table.insert(choices, {"loseHp", info.cardId})
            end
          end
        end
        if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand and not move.to.dead and
          table.find(move.moveInfo, function (info)
            return info.fromArea == Card.PlayerHand
          end) then
          if table.find(player:getCardIds("h"), function (id)
            return Fk:getCardById(id).name == "blood_sword"
          end) then
            table.insert(choices, {"yinfeng1", move.to})
          end
          if table.find(move.moveInfo, function (info)
            return Fk:getCardById(info.cardId).name == "blood_sword"
          end) then
            table.insert(choices, {"yinfeng2", move.to})
          end
        end
      end
      if #choices > 0 then
        event:setCostData(self, {extra_data = choices})
        return true
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local choices = event:getCostData(self).extra_data
    for _, dat in ipairs(choices) do
      if not player:hasSkill(yinfeng.name) then return end
      if dat[1] == "loseHp" then
        event:setCostData(self, {choice = "loseHp", cards = {dat[2]}})
        self:doCost(event, target, player, data)
      elseif dat[1] == "yinfeng1" then
        if not dat[2].dead then
          event:setCostData(self, {tos = {dat[2]}, choice = "yinfeng1"})
          self:doCost(event, target, player, data)
        end
      elseif dat[1] == "yinfeng2" then
        if not dat[2].dead then
          event:setCostData(self, {extra_data = {dat[2]}, choice = "yinfeng2"})
          self:doCost(event, target, player, data)
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    player:broadcastSkillInvoke(yinfeng.name)
    if choice == "loseHp" then
      room:notifySkillInvoked(player, yinfeng.name, "negative")
      room:loseHp(player, 1, yinfeng.name)
      local id = event:getCostData(self).cards[1]
      if table.contains(room.discard_pile, id) and not player.dead then
        room:obtainCard(player, id, true, fk.ReasonJustMove, player, yinfeng.name)
      end
    elseif choice == "yinfeng1" then
      room:notifySkillInvoked(player, yinfeng.name, "offensive")
      room:damage{
        from = player,
        to = event:getCostData(self).tos[1],
        damage = 1,
        skillName = yinfeng.name,
      }
    elseif choice == "yinfeng2" then
      room:notifySkillInvoked(player, yinfeng.name, "negative")
      room:doIndicate(event:getCostData(self).extra_data[1], {player})
      room:damage{
        from = event:getCostData(self).extra_data[1],
        to = player,
        damage = 1,
        skillName = yinfeng.name,
      }
    end
  end,
})

return yinfeng
