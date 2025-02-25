local this = fk.CreateSkill {
  name = "ol_ex__fangquan",
}

this:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and player == target and data.to == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:skip(Player.Play)
    return true
  end,
})

this:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar, card =  room:askToChooseCardAndPlayers(player, { targets = room:getOtherPlayers(player, false), min_num = 1, max_num = 1,
      flag = ".|.|.|hand", prompt = "#ol_ex__fangquan-choose", skill_name = self.name, cancelable = true
    })
    if #tar > 0 and card then
      room:throwCard(card, self.name, player, player)
      tar[1]:gainAnExtraTurn()
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__fangquan"] = "放权",
  [":ol_ex__fangquan"] = "出牌阶段开始前，你可跳过此阶段，然后弃牌阶段开始时，你可弃置一张手牌并选择一名其他角色，其获得一个额外回合。",

  ["#ol_ex__fangquan-choose"] = "放权：弃置一张手牌，令一名角色获得一个额外回合",

  ["$ol_ex__fangquan1"] = "蜀汉有相父在，我可安心。",
  ["$ol_ex__fangquan2"] = "这些事情，你们安排就好。",
}

return this