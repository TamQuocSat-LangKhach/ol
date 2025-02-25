local this = fk.CreateSkill{
  name = "ol_ex__shizhan"
}

this:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol_ex__shizhan-active",
  times = function (self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(this.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(this.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
    and not to_select:isProhibited(player, Fk:cloneCard("duel"))
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:useVirtualCard("duel", nil, target, player, this.name, true)
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__shizhan"] = "势斩",
  [":ol_ex__shizhan"] = "出牌阶段限两次，你可以令一名其他角色视为对你使用【决斗】。",
  ["#ol_ex__shizhan-active"] = "你是否想要发动“势斩”，令一名其他角色视为对你使用【决斗】",

  ["$ol_ex__shizhan1"] = "看你能坚持几个回合！",
  ["$ol_ex__shizhan2"] = "兀那汉子，且报上名来！",
}

return this
