local this = fk.CreateSkill{
  name = "ol_ex__jiangchi",
}

this:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askToUseActiveSkill(player, { skill_name = "ol_ex__jiangchi_select", prompt = "#ol_ex__jiangchi-invoke", cancelable = true})
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:notifySkillInvoked(player, this.name, "offensive")
      player:broadcastSkillInvoke(this.name, 2)
      room:recastCard(self.cost_data, player, this.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_plus-turn")
    else
      room:notifySkillInvoked(player, this.name, "drawcard")
      player:broadcastSkillInvoke(this.name, 1)
      player:drawCards(1, this.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_minus-turn")
    end
  end,
})

this:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      local n = 0
      if player:getMark("ol_ex__jiangchi_plus-turn") > 0 then
        n = n + 1
      end
      if player:getMark("ol_ex__jiangchi_minus-turn") > 0 then
        n = n - 1
      end
      return n
    end
  end,
  bypass_distances = function (self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("ol_ex__jiangchi_plus-turn") > 0
  end,
})

this:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("ol_ex__jiangchi_minus-turn") > 0
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__jiangchi"] = "将驰",
  [":ol_ex__jiangchi"] = "摸牌阶段结束时，你可以选择一项：1.摸一张牌，本回合使用【杀】的次数上限-1，且【杀】不计入手牌上限；2.重铸一张牌，本回合使用【杀】无距离限制且次数上限+1。",
  
  ["#ol_ex__jiangchi-invoke"] = "1.摸一张牌，【杀】次数-1，不计入手牌上限；2.重铸一张牌，【杀】次数+1，无距离限制",
  
  ["$ol_ex__jiangchi1"] = "丈夫当将十万骑驰沙漠，立功建号耳。",
  ["$ol_ex__jiangchi2"] = "披坚执锐，临危不难，身先士卒。",
}

return this