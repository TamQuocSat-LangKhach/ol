local qisi = fk.CreateSkill{
  name = "qisi",
}

Fk:loadTranslationTable{
  ["qisi"] = "奇思",
  [":qisi"] = "游戏开始时，将两张不同副类别的装备牌并置入你的装备区。摸牌阶段，你可以声明一种装备牌副类别，若牌堆或弃牌堆中有符合的牌，"..
  "你获得其中一张且本阶段少摸一张牌。",

  ["#qisi-invoke"] = "奇思：你可以少摸一张牌，声明一种装备牌副类别并获得一张",

  ["$qisi1"] = "匠作之道，当佐奇思。",
  ["$qisi2"] = "世无同刃，不循凡矩。",
}

qisi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qisi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local equipMap = {}
    for _, id in ipairs(room.draw_pile) do
      local sub_type = Fk:getCardById(id).sub_type
      if Fk:getCardById(id).type == Card.TypeEquip and player:hasEmptyEquipSlot(sub_type) then
        local list = equipMap[tostring(sub_type)] or {}
        table.insert(list, id)
        equipMap[tostring(sub_type)] = list
      end
    end
    local types = {}
    for k, _ in pairs(equipMap) do
      table.insert(types, k)
    end
    if #types == 0 then return end
    types = table.random(types, 2)
    local put = {}
    for _, t in ipairs(types) do
      table.insert(put, table.random(equipMap[t]))
    end
    room:moveCardIntoEquip(player, put, qisi.name, false, player)
  end,
})
qisi:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qisi.name) and data.n > 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qisi.name,
      prompt = "#qisi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"weapon", "armor", "equip_horse", "treasure"}
    local StrToSubtypeList = {
      ["weapon"] = { Card.SubtypeWeapon },
      ["armor"] = { Card.SubtypeArmor },
      ["treasure"] = { Card.SubtypeTreasure },
      ["equip_horse"] = { Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide }
    }
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qisi.name,
    })
    local list = StrToSubtypeList[choice]
    local piles = table.simpleClone(room.draw_pile)
    table.insertTable(piles, room.discard_pile)
    local cards = {}
    for _, id in ipairs(piles) do
      if table.contains(list, Fk:getCardById(id).sub_type) then
        table.insert(cards, id)
      end
    end
    if #cards == 0 then return end
    data.n = data.n - 1
    room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, qisi.name, nil, false, player)
  end,
})

return qisi
