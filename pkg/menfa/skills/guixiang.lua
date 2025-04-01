local guixiang = fk.CreateSkill{
  name = "guixiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guixiang"] = "贵相",
  [":guixiang"] = "锁定技，你回合内第X个阶段改为出牌阶段（X为你的手牌上限）。",

  ["#PhaseChanged"] = "%from 的 %arg 被改为了 %arg2",
  ["@[guixiang]"] = "贵相",

  ["$guixiang1"] = "女相显贵，凤仪从龙。",
  ["$guixiang2"] = "正官七杀，天生富贵。",
}

Fk:addQmlMark{
  name = "guixiang",
  qml_path = "",
  how_to_show = function(name, value, p)
    local x = p:getMaxCards() + 1
    if x > 1 and x < 8 then
      return Fk:translate(Util.PhaseStrMapper(x))
    end
    return " "
  end,
}

guixiang:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, "@[guixiang]", 1)
end)

guixiang:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@[guixiang]", 0)
end)

guixiang:addEffect(fk.EventPhaseChanging, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(guixiang.name) and
      data.phase ~= Player.Play and data.phase >= Player.Start and data.phase <= Player.Finish then
      local room = player.room
      return #room.logic:getEventsOfScope(GameEvent.Phase, player:getMaxCards(), function (e)
        return e.data.phase >= Player.Start and e.data.phase <= Player.Finish
      end, Player.HistoryTurn) + 1 == player:getMaxCards()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sendLog{
      type = "#PhaseChanged",
      from = player.id,
      arg = Util.PhaseStrMapper(data.phase),
      arg2 = "phase_play",
    }
    data.phase = Player.Play
  end,
})

return guixiang
