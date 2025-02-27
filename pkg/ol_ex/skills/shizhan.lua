local shizhan = fk.CreateSkill{
  name = "ol_ex__shizhan"
}

Fk:loadTranslationTable{
  ["ol_ex__shizhan"] = "势斩",
  [":ol_ex__shizhan"] = "出牌阶段限两次，你可以令一名其他角色视为对你使用【决斗】。",

  ["#ol_ex__shizhan"] = "势斩：你可以令一名其他角色视为对你使用【决斗】",

  ["$ol_ex__shizhan1"] = "看你能坚持几个回合！",
  ["$ol_ex__shizhan2"] = "兀那汉子，且报上名来！",
}

shizhan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol_ex__shizhan",
  times = function (self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(shizhan.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shizhan.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isProhibited(player, Fk:cloneCard("duel"))
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:useVirtualCard("duel", nil, target, player, shizhan.name, true)
  end,
})

return shizhan
