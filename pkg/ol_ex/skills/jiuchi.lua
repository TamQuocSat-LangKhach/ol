local jiuchi = fk.CreateSkill{
  name = "ol_ex__jiuchi",
}

Fk:loadTranslationTable{
  ["ol_ex__jiuchi"] = "酒池",
  ["#ol_ex__jiuchi_trigger"] = "酒池",
  [":ol_ex__jiuchi"] = "你可以将一张♠手牌当【酒】使用。你使用【酒】无次数限制。当你造成伤害后，若渠道为受【酒】效果影响的【杀】，"..
  "你的〖崩坏〗本回合无效。",

  ["#ol_ex__jiuchi"] = "酒池：你可以将一张♠手牌当【酒】使用",

  ["$ol_ex__jiuchi1"] = "好酒，痛快！",
  ["$ol_ex__jiuchi2"] = "某，千杯不醉！",
}

jiuchi:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "analeptic",
  prompt = "#ol_ex__jiuchi",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Spade and
      Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("analeptic")
    c.skillName = jiuchi.name
    c:addSubcard(cards[1])
    return c
  end,
})

jiuchi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(jiuchi.name) and skill.trueName == "analeptic_skill" and scope == Player.HistoryTurn
  end,
})

jiuchi:addEffect(fk.Damage, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jiuchi.name) and data.card and data.card.trueName == "slash" and
      player:hasSkill("benghuai") then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local drankBuff = use_event and (use_event.data.extra_data or {}).drankBuff or 0
        return drankBuff > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:invalidateSkill(player, "benghuai", "-turn")
  end,
})

return jiuchi