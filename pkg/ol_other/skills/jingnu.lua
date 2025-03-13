local jingnu = fk.CreateSkill{
  name = "qin__jingnu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__jingnu"] = "劲弩",
  [":qin__jingnu"] = "锁定技，回合开始时，若你装备区里没有【秦弩】，你从游戏外使用一张【秦弩】（离开装备区时销毁）。",

  ["$qin__jingnu"] = "劲弩在手，百发皆中！"
}

jingnu:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jingnu.name) and
      not table.find(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == "qin_crossbow"
      end) and
      player:canUseTo(Fk:cloneCard("qin_crossbow", Card.Club, 1), player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local crossbow = table.find(room.void, function(id)
      local card = Fk:getCardById(id)
      return card.name == "qin_crossbow"
    end) or room:printCard("qin_crossbow", Card.Club, 1).id
    room:setCardMark(Fk:getCardById(crossbow), MarkEnum.DestructOutEquip, 1)
    room:useCard{
      from = player,
      tos = {player},
      card = Fk:getCardById(crossbow),
    }
  end,
})

return jingnu
