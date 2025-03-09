local zhanjin = fk.CreateSkill{
  name = "zhanjin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhanjin"] = "蘸金",
  [":zhanjin"] = "锁定技，若你的装备区里没有武器牌且你的武器栏未被废除，你视为装备着【贯石斧】。",

  ["$zhanjin1"] = "寒光纵横，血战八方！",
  ["$zhanjin2"] = "蘸金霜刃，力贯山河！",
}

zhanjin:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhanjin.name) and #player:getEquipments(Card.SubtypeWeapon) == 0 and
      #player:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 and
      data.from == player and data.card.trueName == "slash" and not data.to.dead and
      Fk.skills["#axe_skill"]:isEffectable(player)
  end,
  on_use = function (self, event, target, player, data)
    Fk.skills["#axe_skill"]:doCost(event, target, player, data)
  end,
})
zhanjin:addEffect("atkrange", {
  fixed_func = function (self, from)
    if from:hasSkill(zhanjin.name) and #from:getEquipments(Card.SubtypeWeapon) == 0 and
      #from:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 then
      return 3
    end
  end,
})

return zhanjin
