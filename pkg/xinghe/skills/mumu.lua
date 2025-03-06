local mumu = fk.CreateSkill{
  name = "ol__mumu",
}

Fk:loadTranslationTable{
  ["ol__mumu"] = "穆穆",
  [":ol__mumu"] = "出牌阶段开始时，你可以选择一项：弃置一名其他角色装备区内的一张牌；获得一名角色装备区内的防具牌，然后你本回合不能"..
  "使用或打出【杀】。",

  ["ol__mumu_discard"] = "弃置其他角色装备区里的一张牌",
  ["ol__mumu_get"] = "获得场上一张防具牌，本回合不可出杀",
  ["#ol__mumu-discard"] = "穆穆：选择一名角色，弃置其一张装备",
  ["#ol__mumu-get"] = "穆穆：选择一名角色，获得其一张防具",
  ["#ol__mumu-prey"] = "穆穆：获得其中一张防具牌",
  ["@@ol__mumu-turn"] = "禁止出杀",

  ["$ol__mumu1"] = "穆穆语言，不惊左右。",
  ["$ol__mumu2"] = "亲人和睦，国家安定就好。",
}

mumu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mumu.name) and player.phase == Player.Play and
      (table.find(player.room:getOtherPlayers(player, false), function (p)
        return #p:getCardIds("e") > 0
      end) or
      table.find(player.room.alive_players, function (p)
        return #p:getEquipments(Card.SubtypeArmor) > 0
      end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if table.find(room.alive_players, function(p)
      return #p:getEquipments(Card.SubtypeArmor) > 0
    end) then
      table.insert(choices, 1, "ol__mumu_get")
    end
    if table.find(room:getOtherPlayers(player, false), function (p)
      return #p:getCardIds("e") > 0
    end) then
      table.insert(choices, 1, "ol__mumu_discard")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = mumu.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "ol__mumu_discard" then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return #p:getCardIds("e") > 0
      end)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = mumu.name,
        prompt = "#ol__mumu-discard",
        cancelable = false,
      })[1]
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "e",
        skill_name = mumu.name,
      })
      room:throwCard(id, mumu.name, to, player)
    else
      local targets = table.filter(room.alive_players, function(p)
        return #p:getEquipments(Card.SubtypeArmor) > 0
      end)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = mumu.name,
        prompt = "#ol__mumu-get",
        cancelable = false,
      })[1]
      local ids = to:getEquipments(Card.SubtypeArmor)
      room:setPlayerMark(player, "@@ol__mumu-turn", 1)
      if #ids > 1 then
        ids = room:askToChooseCard(player, {
          target = to,
          flag = { card_data = {{ to.general, ids }} },
          skill_name = mumu.name,
          prompt = "#ol__mumu-prey",
        })
      end
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonPrey, mumu.name, nil, true, player)
    end
  end,
})
mumu:addEffect("prohibit", {
  prohibit_response = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("@@ol__mumu-turn") > 0
  end,
  prohibit_use = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("@@ol__mumu-turn") > 0
  end,
})

return mumu
