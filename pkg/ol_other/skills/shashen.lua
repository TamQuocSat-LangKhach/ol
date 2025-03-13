local shashen = fk.CreateSkill{
  name = "qin__shashen",
}

Fk:loadTranslationTable{
  ["qin__shashen"] = "杀神",
  [":qin__shashen"] = "你可以将一张手牌当【杀】使用或打出；当每回合你使用的第一张【杀】造成伤害后，你摸一张牌。",

  ["#qin__shashen"] = "杀神：你可以将一张手牌当【杀】使用或打出",

  ["$qin__shashen"] = "战场，是我的舞台！",
}

shashen:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#qin__shashen",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = shashen.name
    c:addSubcard(cards[1])
    return c
  end,
})
shashen:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shashen.name) and data.card and data.card.trueName == "slash" and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == player and use.card.trueName == "slash"
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1] == player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, shashen.name)
  end,
})

return shashen
