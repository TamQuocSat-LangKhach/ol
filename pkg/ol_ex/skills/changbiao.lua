local this = fk.CreateSkill{
  name = "ol_ex__changbiao",
}

this:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#ol_ex__changbiao-active",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards < 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  enabled_at_response = Util.FalseFunc,
  before_use = function(self, player, useData)
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.ol_ex__changbiaoUser = player.id
  end,
})

this:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@ol_ex__changbiao_draw-phase") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("@ol_ex__changbiao_draw-phase"), "ol_ex__changbiao")
  end,
})

this:addEffect(fk.CardUseFinished, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return (data.extra_data or {}).ol_ex__changbiaoUser == player.id and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ol_ex__changbiao_draw-phase", #data.card.subcards)
  end,
})

this:addEffect('targetmod', {
  bypass_distances =  function(self, player, skill, card, to)
    return table.contains(card.skillNames, self.name)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__changbiao"] = "长标",
  [":ol_ex__changbiao"] = "出牌阶段限一次，你可将至少一张手牌转化为【杀】使用（无距离限制），此阶段结束时，若此【杀】造成过伤害，你摸x张牌（X为以此法转化的牌数）。",

  ["#ol_ex__changbiao-active"] = "你是否想要发动”长标“，将任意张手牌当【杀】使用？",
  ["@ol_ex__changbiao_draw-phase"] = "长标",
  
  ["$ol_ex__changbiao1"] = "长标如虹，以伐蜀汉！",
  ["$ol_ex__changbiao2"] = "长标在此，谁敢拦我？",
}

return this
