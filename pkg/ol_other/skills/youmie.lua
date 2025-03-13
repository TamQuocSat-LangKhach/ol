local youmie = fk.CreateSkill{
  name = "qin__youmie",
}

Fk:loadTranslationTable{
  ["qin__youmie"] = "诱灭",
  [":qin__youmie"] = "出牌阶段限一次，你可以将一张牌交给一名其他角色，直到你下回合开始或你死亡，该角色于其回合外不能使用或打出牌。",

  ["#qin__youmie"] = "诱灭：将一张牌交给一名角色，直到你下回合开始，其于回合外不能使用或打出牌",
  ["@@qin__youmie"] = "诱灭",

  ["$qin__youmie"] = "美色误人，红颜灭国哟。",
}

youmie:addEffect("active", {
  anim_type = "offensive",
  prompt = "#qin__youmie",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(youmie.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(target, "@@qin__youmie", player.id)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, youmie.name, nil, false, player)
  end,
})
youmie:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@qin__youmie") ~= 0 and card and Fk:currentRoom().current ~= player
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@qin__youmie") ~= 0 and card and Fk:currentRoom().current ~= player
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(youmie.name, Player.HistoryGame) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removeTableMark(p, "@@qin__youmie", player.id)
    end
  end,
}

youmie:addEffect(fk.TurnStart, spec)
youmie:addEffect(fk.Death, spec)

return youmie
