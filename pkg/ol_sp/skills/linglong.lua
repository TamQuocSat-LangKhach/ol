local linglong = fk.CreateSkill{
  name = "ol__linglong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__linglong"] = "玲珑",
  [":ol__linglong"] = "锁定技，若你的装备区里没有：武器牌，你出牌阶段使用【杀】次数上限+1；防具牌，你视为装备着【八卦阵】；"..
  "坐骑牌，你的手牌上限+1；宝物牌，你视为拥有〖奇才〗。",

  ["$ol__linglong1"] = "本姑娘没你想象的那么弱不禁风。",
  ["$ol__linglong2"] = "读书，也是有好处的。",
}

local linglong_on_use = function (self, event, target, player, data)
  local room = player.room
  room:broadcastPlaySound("./packages/standard_cards/audio/card/eight_diagram")
  room:setEmotion(player, "./packages/standard_cards/image/anim/eight_diagram")
  local skill = Fk.skills["#eight_diagram_skill"]
  skill:use(event, target, player, data)
end
linglong:addEffect(fk.AskForCardUse, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(linglong.name) and not player:isFakeSkill(self) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      #player:getEquipments(Card.SubtypeArmor) == 0 and
      Fk.skills["#eight_diagram_skill"] ~= nil and Fk.skills["#eight_diagram_skill"]:isEffectable(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = linglong.name,
    })
  end,
  on_use = linglong_on_use,
})
linglong:addEffect(fk.AskForCardResponse, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(linglong.name) and not player:isFakeSkill(self) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      #player:getEquipments(Card.SubtypeArmor) == 0 and
      Fk.skills["#eight_diagram_skill"] ~= nil and Fk.skills["#eight_diagram_skill"]:isEffectable(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = linglong.name,
    })
  end,
  on_use = linglong_on_use,
})
linglong:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    if player:hasSkill(linglong.name) and #player:getEquipments(Card.SubtypeWeapon) == 0 and
      card and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(linglong.name) and #player:getEquipments(Card.SubtypeTreasure) == 0 and
      card and card.type == Card.TypeTrick
  end,
})
linglong:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(linglong.name) and
      #player:getEquipments(Card.SubtypeOffensiveRide) + #player:getEquipments(Card.SubtypeDefensiveRide) == 0 then
      return 1
    end
  end,
})

return linglong
