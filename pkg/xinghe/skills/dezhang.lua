local dezhang = fk.CreateSkill{
  name = "dezhang",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["dezhang"] = "德彰",
  [":dezhang"] = "觉醒技，回合开始时，若你没有“绥”，你减1点体力上限，获得〖卫戍〗。",

  ["$dezhang1"] = "以德怀柔，广得军心。",
  ["$dezhang2"] = "德彰四海，威震八荒。",
}

dezhang:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dezhang.name) and
      player:usedSkillTimes(dezhang.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@appease") == 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "weishu")
  end,
})

return dezhang
