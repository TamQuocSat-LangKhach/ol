local fuli = fk.CreateSkill{
  name = "ol_ex__fuli",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ol_ex__fuli"] = "伏枥",
  [":ol_ex__fuli"] = "限定技，当你处于濒死状态时，你可以将体力回复至X点且手牌摸至X张（X为全场势力数），若X大于你本局游戏造成的伤害值，你翻面。",
}

fuli:addEffect(fk.AskForPeaches, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuli.name) and player.dying and
      player:usedSkillTimes(fuli.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:recover{
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = fuli.name,
    }
    if player.dead then return end
    if player:getHandcardNum() < #kingdoms then
      player:drawCards(#kingdoms - player:getHandcardNum())
      if player.dead then return end
    end
    local n = 0
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.from == player then
        n = n + damage.damage
      end
      return n == #kingdoms
    end, Player.HistoryGame)
    if #kingdoms > n then
      player:turnOver()
    end
  end,
})

return fuli