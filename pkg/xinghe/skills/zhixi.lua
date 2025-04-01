local zhixi = fk.CreateSkill{
  name = "ol__zhixi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__zhixi"] = "止息",
  [":ol__zhixi"] = "锁定技，出牌阶段，你至多使用X张牌，你使用锦囊牌后，不能再使用牌（X为你的体力值）。",

  ["@[ol__zhixi]"] = "止息",
  ["ol__zhixi_remains"] = "剩余",
  ["ol__zhixi_prohibit"] = "不能出牌",
}

Fk:addQmlMark{
  name = "ol__zhixi",
  qml_path = "",
  how_to_show = function(name, value, p)
    if p.phase == Player.Play then
      local x = p.hp - p:getMark("ol__zhixi-phase")
      if x < 1 or p:getMark("ol__zhixi_prohibit-phase") > 0 then
        return Fk:translate("ol__zhixi_prohibit")
      else
        return Fk:translate("ol__zhixi_remains") .. tostring(x)
      end
    end
    return "#hidden"
  end,
}
zhixi:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhixi.name) and player.phase == Player.Play
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeTrick then
      player.room:setPlayerMark(player, "ol__zhixi_prohibit-phase", 1)
    else
      room:addPlayerMark(player, "ol__zhixi-phase")
    end
  end,
})
zhixi:addEffect("prohibit", {
  prohibit_use = function(self, player)
    return player:hasSkill(zhixi.name) and player.phase == Player.Play and
      (player:getMark("ol__zhixi_prohibit-phase") > 0 or player:getMark("ol__zhixi-phase") >= player.hp)
  end,
})

zhixi:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  room:setPlayerMark(player, "@[ol__zhixi]", 1)
  if player.phase ~= Player.Play then return end
  local x = 0
  local use_trick = false
  room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
    local use = e.data
    if use.from == player then
      if use.card.type == Card.TypeTrick then
        use_trick = true
        return true
      end
      x = x + 1
    end
  end, Player.HistoryPhase)
  if use_trick then
    room:setPlayerMark(player, "ol__zhixi_prohibit-phase", 1)
  else
    room:setPlayerMark(player, "ol__zhixi-phase", x)
  end
end)

zhixi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[ol__zhixi]", 0)
end)

return zhixi
