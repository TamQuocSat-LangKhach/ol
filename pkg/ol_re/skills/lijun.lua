local lijun = fk.CreateSkill {
  name = "ol__lijun",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["ol__lijun"] = "立军",
  [":ol__lijun"] = "主公技，其他吴势力角色的出牌阶段内限一次，当其使用【杀】结算结束后，其可以将此【杀】交给你，然后你可以令其摸一张牌且"..
  "其此阶段使用【杀】次数上限+1。",

  ["#ol__lijun-invoke"] = "立军：你可以将此【杀】交给 %src，然后其可令你摸一张牌",
  ["#ol__lijun-draw"] = "立军：你可以令 %src 摸一张牌且使用【杀】次数+1",

  ["$ol__lijun1"] = "能征善战，乃我东吴长久之风。",
  ["$ol__lijun2"] = "重赏之下，必有勇夫。",
}

lijun:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(lijun.name) and
      target.kingdom == "wu" and data.card.trueName == "slash" and target.phase == Player.Play and
      player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(lijun.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = lijun.name,
      prompt = "#ol__lijun-invoke:"..player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, lijun.name)
    if not player.dead and not target.dead and
      room:askToSkillInvoke(player,{
      skill_name = lijun.name,
      prompt = "#ol__lijun-draw:"..target.id,
    }) then
      room:addPlayerMark(target, MarkEnum.SlashResidue.."-phase", 1)
      target:drawCards(1, lijun.name)
    end
  end,
})

return lijun
