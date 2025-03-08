local yuanzi = fk.CreateSkill{
  name = "yuanzi",
}

Fk:loadTranslationTable{
  ["yuanzi"] = "援资",
  [":yuanzi"] = "每轮限一次，其他角色的准备阶段，你可以交给其所有手牌。若如此做，当其本回合造成伤害后，若其手牌数不小于你，你可以摸两张牌。",

  ["#yuanzi-invoke"] = "援资：你可以将所有手牌交给 %dest，其本回合造成伤害后你可以摸牌",
  ["#yuanzi-draw"] = "援资：你可以摸两张牌",

  ["$yuanzi1"] = "不过是些身外之物罢了。",
  ["$yuanzi2"] = "兹之家资，将军可尽取之。",
}

yuanzi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuanzi.name) and target ~= player and target.phase == Player.Start and
      not player:isKongcheng() and not target.dead and
      player:usedSkillTimes(yuanzi.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yuanzi.name,
      prompt = "#yuanzi-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(target, player:getCardIds("h"), false, fk.ReasonGive, player, yuanzi.name)
  end,
})
yuanzi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(yuanzi.name, Player.HistoryTurn) > 0 and
      target == player.room.current and target:getHandcardNum() >= player:getHandcardNum()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yuanzi.name,
      prompt = "#yuanzi-draw",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, yuanzi.name)
  end,
})

return yuanzi
