local cuipo = fk.CreateSkill{
  name = "cuipo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cuipo"] = "摧破",
  [":cuipo"] = "锁定技，当你每回合使用第X张牌时（X为此牌牌名字数），若为【杀】或伤害锦囊牌，此牌伤害+1，否则你摸一张牌。",

  ["@cuipo-turn"] = "摧破",

  ["$cuipo1"] = "虎贲冯河，何惧千城！",
  ["$cuipo2"] = "长锋在手，万寇辟易。",
}

cuipo:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
      return e.data.from == player
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "@cuipo-turn", n)
  end
end)

cuipo:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuipo.name) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) == Fk:translate(data.card.trueName, "zh_CN"):len()
  end,
  on_use = function(self, event, target, player, data)
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      player:drawCards(1, cuipo.name)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuipo.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@cuipo-turn", 1)
  end,
})

return cuipo
