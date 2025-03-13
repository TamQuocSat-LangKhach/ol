local zulong = fk.CreateSkill{
  name = "qin__zulong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__zulong"] = "祖龙",
  [":qin__zulong"] = "锁定技，你的回合开始时，若牌堆或弃牌堆内有【传国玉玺】或【真龙长剑】，你获得之；若没有，你摸两张牌。",

  ["$qin__zulong"] = "得龙血脉，万物初始！",
}

zulong:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zulong.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("qin_dragon_sword,qin_seal", 2, "allPiles")
    if #cards > 0 then
      room:obtainCard(player, cards, true, fk.ReasonJustMove, player, zulong.name)
    else
      player:drawCards(2, zulong.name)
    end
  end,
})

return zulong
