local juesheng = fk.CreateSkill{
  name = "juesheng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["juesheng"] = "决生",
  [":juesheng"] = "限定技，你可以视为使用一张伤害为X的【决斗】（X为第一个目标角色本局使用【杀】的数量+1），然后其获得本技能直到其下回合结束。",

  ["#juesheng"] = "决生：视为使用【决斗】，伤害值为目标本局使用【杀】的数量+1！",

  ["$juesheng1"] = "向死而生，索性拼个鱼死网破！",
  ["$juesheng2"] = "张翼德，我二人报仇来了！",
}

juesheng:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "duel",
  prompt = "#juesheng",
  card_filter = Util.FalseFunc,
  view_as = function(self)
    local c = Fk:cloneCard("duel")
    c.skillName = juesheng.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local to = use.tos[1]
    local num = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      return e.data.from == to and e.data.card.trueName == "slash"
    end, Player.HistoryGame)
    use.additionalDamage = (use.additionalDamage or 0) + math.max(num, 1)
  end,
  after_use = function (self, player, use)
    local room = player.room
    local tos = use.tos
    room:sortByAction(tos)
    for _, p in ipairs(tos) do
      if not p.dead and not p:hasSkill(juesheng.name, true) then
        room:setPlayerMark(p, juesheng.name, 1)
        room:handleAddLoseSkills(p, juesheng.name)
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(juesheng.name, Player.HistoryGame) == 0
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})
juesheng:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(juesheng.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, juesheng.name, 0)
    room:handleAddLoseSkills(player, "-juesheng")
  end,
})

return juesheng
