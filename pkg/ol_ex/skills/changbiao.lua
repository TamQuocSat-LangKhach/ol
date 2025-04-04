local changbiao = fk.CreateSkill{
  name = "changbiao",
}

Fk:loadTranslationTable {
  ["changbiao"] = "长标",
  [":changbiao"] = "出牌阶段限一次，你可以将任意张手牌当【杀】使用（无距离限制），若此【杀】造成过伤害，此阶段结束时，你摸等量的牌。",

  ["#changbiao"] = "长标：你可以将任意张手牌当【杀】使用",
  ["@changbiao_draw-phase"] = "长标",

  ["$changbiao1"] = "长标如虹，以伐蜀汉！",
  ["$changbiao2"] = "长标在此，谁敢拦我？",
}

changbiao:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#changbiao",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, player, cards)
    if #cards < 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = changbiao.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.changbiao = player
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(changbiao.name, Player.HistoryPhase) < 1
  end,
  enabled_at_response = Util.FalseFunc,
})

changbiao:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@changbiao_draw-phase") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("@changbiao_draw-phase"), "changbiao")
  end,
})

changbiao:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return (data.extra_data or {}).changbiao == player and data.damageDealt and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@changbiao_draw-phase", #data.card.subcards)
  end,
})

changbiao:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return table.contains(card.skillNames, changbiao.name)
  end,
})

return changbiao
