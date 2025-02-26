local duanliang = fk.CreateSkill{
  name = "ol_ex__duanliang",
}

Fk:loadTranslationTable{
  ["ol_ex__duanliang"] = "断粮",
  [":ol_ex__duanliang"] = "你可以将一张黑色非锦囊牌当【兵粮寸断】使用。若你于当前回合内未造成过伤害，你使用【兵粮寸断】无距离限制。",

  ["#ol_ex__duanliang"] = "断粮：你可以将一张黑色非锦囊牌当【兵粮寸断】使用",

  ["$ol_ex__duanliang1"] = "兵行无常，计行断粮。",
  ["$ol_ex__duanliang2"] = "焚其粮营，断其粮道。",
}

duanliang:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    if room.current == player and
      #room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0 then
      room:setPlayerMark(player, "ol_ex__duanliang_damage-turn", 1)
    end
  end
end)

duanliang:addEffect("viewas", {
  anim_type = "control",
  pattern = "supply_shortage",
  prompt = "#ol_ex__duanliang",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and
      Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = duanliang.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

duanliang:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(duanliang.name, true) and player.room.current == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "ol_ex__duanliang_damage-turn", 1)
  end,
})

duanliang:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(duanliang.name) and skill.name == "supply_shortage_skill" and
      player:getMark("ol_ex__duanliang_damage-turn") == 0
  end,
})

return duanliang
