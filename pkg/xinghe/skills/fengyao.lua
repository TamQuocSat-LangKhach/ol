local fengyao = fk.CreateSkill{
  name = "fengyao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengyao"] = "凤瑶",
  [":fengyao"] = "锁定技，当♠牌离开一名角色装备区后，你回复1点体力。当你对其他角色造成伤害时，你弃置你或其场上一张♠牌，令此伤害+1。",

  ["#fengyao-choose"] = "凤瑶：弃置你或 %dest 场上一张♠牌，令你对其造成的伤害+1",
  ["#fengyao-discard"] = "凤瑶：弃置其中一张♠牌",

  ["$fengyao1"] = "尔等看好了，我便是凤瑶军统帅！",
  ["$fengyao2"] = "青丝为刀剑，弑尽敌血点绛唇。",
}

fengyao:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fengyao.name) and player:isWounded() then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).suit == Card.Spade then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = fengyao.name,
    }
  end,
})
fengyao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fengyao.name) and data.to ~= player then
      return table.find(player:getCardIds("ej"), function (id)
        return Fk:getCardById(id).suit == Card.Spade and not player:prohibitDiscard(id)
      end) or table.find(data.to:getCardIds("ej"), function (id)
        return Fk:getCardById(id).suit == Card.Spade
      end)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    if table.find(player:getCardIds("ej"), function (id)
      return Fk:getCardById(id).suit == Card.Spade and not player:prohibitDiscard(id)
    end) then
      table.insert(targets, player)
    end
    if table.find(data.to:getCardIds("ej"), function (id)
      return Fk:getCardById(id).suit == Card.Spade
    end) then
      table.insert(targets, data.to)
    end
    local to = targets
    if #targets > 1 then
      to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = fengyao.name,
        prompt = "#fengyao-choose::"..data.to.id,
        cancelable = false,
      })
    end
    to = to[1]
    local card = table.filter(to:getCardIds("ej"), function (id)
      return Fk:getCardById(id).suit == Card.Spade and not player:prohibitDiscard(id)
    end)
    if #card > 1 then
      card = room:askToChooseCard(player, {
        target = to,
        flag = { card_data = {{ to.general, card }} },
        skill_name = fengyao.name,
        prompt = "#fengyao-discard",
      })
    end
    room:throwCard(card, fengyao.name, to, player)
    data:changeDamage(1)
  end,
})

return fengyao
