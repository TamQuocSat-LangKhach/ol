local hongju = fk.CreateSkill {
  name = "ol__hongju",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ol__hongju"] = "鸿举",
  [":ol__hongju"] = "觉醒技，准备阶段，若“荣”的数量不小于3，你可以用任意张手牌替换等量的“荣”，减1点体力上限，获得〖清侧〗。",

  ["#ol__hongju-exchange"] = "鸿举：你可以用手牌交换“荣”",

  ["$ol__hongju1"] = "鸿飞冲云天，魂归入魏土。",
  ["$ol__hongju2"] = "吾负淮阴之才，岂能受你摆布！",
}

hongju:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hongju.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(hongju.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("$guanqiujian__glory") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player:isKongcheng() then
      local piles = room:askToArrangeCards(player, {
        skill_name = hongju.name,
        card_map = {
          player:getPile("$guanqiujian__glory"), player:getCardIds(Player.Hand),
          "$guanqiujian__glory", "$Hand"
        },
        prompt = "#ol__hongju-exchange",
      })
      room:swapCardsWithPile(player, piles[1], piles[2], hongju.name, "$guanqiujian__glory", true)
      if player.dead then return end
    end
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "qingce", nil, true, false)
  end,
})

return hongju
