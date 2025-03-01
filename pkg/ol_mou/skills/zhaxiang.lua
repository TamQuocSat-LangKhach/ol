local zhaxiang = fk.CreateSkill{
  name = "ol_ex__zhaxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__zhaxiang"] = "诈降",
  [":ol_ex__zhaxiang"] = "锁定技，当你失去1点体力后，你摸三张牌，若在你的出牌阶段，你本回合你使用【杀】次数上限+1、"..
  "使用红色【杀】无距离限制且不可被响应。",

  ["@@ol_ex__zhaxiang-turn"] = "诈降",
}

zhaxiang:addEffect(fk.HpLost, {
  anim_type = "drawcard",
  trigger_times = function(self, event, target, player, data)
    return data.num
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, zhaxiang.name)
    if player.phase == Player.Play then
      local room = player.room
      room:setPlayerMark(player, "@@ol_ex__zhaxiang-turn", 1)
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn")
    end
  end,
})
zhaxiang:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and data.card.color == Card.Red and
      player:getMark("@@ol_ex__zhaxiang-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = player.room.alive_players
  end,
})
zhaxiang:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card)
    return player:getMark("@@ol_ex__zhaxiang-turn") > 0 and card and card.trueName == "slash" and card.color == Card.Red
  end,
})

return zhaxiang
