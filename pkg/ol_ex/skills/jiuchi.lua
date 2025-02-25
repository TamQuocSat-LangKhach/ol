local this = fk.CreateSkill{
  name = "ol_ex__jiuchi",
}

this:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "analeptic",
  prompt = "#ol_ex__jiuchi-viewas",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Spade and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("analeptic")
    c.skillName = this.name
    c:addSubcard(cards[1])
    return c
  end,
})

this:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(this.name) and skill.trueName == "analeptic_skill" and scope == Player.HistoryTurn
  end,
})

this:addEffect(fk.Damage, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(this.name) and data.card and data.card.trueName == "slash"
        and player:getMark("ol_ex__benghuai_invalidity-turn") == 0 then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if parentUseData then
        local drankBuff = parentUseData and (parentUseData.data[1].extra_data or {}).drankBuff or 0
        return drankBuff > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "ol_ex__benghuai_invalidity-turn")
  end,
})

this:addEffect('invalidity', {
  invalidity_func = function(self, from, skill)
    return from:getMark("ol_ex__benghuai_invalidity-turn") > 0 and skill.name == "benghuai"
  end
})

Fk:loadTranslationTable{
  ["ol_ex__jiuchi"] = "酒池",
  ["#ol_ex__jiuchi_trigger"] = "酒池",
  [":ol_ex__jiuchi"] = "①你可将一张♠手牌转化为【酒】使用。②你使用【酒】无次数限制。③当你造成伤害后，若渠道为受【酒】效果影响的【杀】，你的〖崩坏〗于当前回合内无效。",

  ["#ol_ex__jiuchi-viewas"] = "你是否想要发动“酒池”，将一张♠手牌当【酒】使用",

  ["$ol_ex__jiuchi1"] = "好酒，痛快！",
  ["$ol_ex__jiuchi2"] = "某，千杯不醉！",
}

return this