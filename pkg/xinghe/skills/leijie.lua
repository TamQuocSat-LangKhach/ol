local leijie = fk.CreateSkill{
  name = "leijie",
}

Fk:loadTranslationTable{
  ["leijie"] = "雷劫",
  [":leijie"] = "出牌阶段限一次，你可以令一名角色判定，若结果为♠2~9，你依次视为对其使用两张雷【杀】，否则其摸两张牌。",

  ["#leijie"] = "雷劫：令一名角色判定，若为♠2~9，视为对其使用两张雷【杀】，否则其摸两张牌",

  ["$leijie1"] = "雷劫锻体，清瘴涤魂。",
  ["$leijie2"] = "欲得长生，必受此劫。",
}

leijie:addEffect("active", {
  anim_type = "control",
  prompt = "#leijie",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(leijie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local judge = {
      who = target,
      reason = leijie.name,
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    if target.dead then return end
    if judge:matchPattern() then
      if player == target or player.dead then return end
      if room:useVirtualCard("thunder__slash", nil, player, target, leijie.name, true) and not (player.dead or target.dead) then
        room:useVirtualCard("thunder__slash", nil, player, target, leijie.name, true)
      end
    else
      target:drawCards(2, leijie.name)
    end
  end,
})

return leijie
