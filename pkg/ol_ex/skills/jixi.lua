local this = fk.CreateSkill {
  name = "ol_ex__jixi",
}

this:addEffect("viewas", {
  anim_type = "control",
  pattern = "snatch",
  prompt = "#ol_ex__jixi-viewas",
  expand_pile = "ol_ex__dengai_field",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:getPileNameOfId(to_select) == "ol_ex__dengai_field"
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("snatch")
    c.skillName = this.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return #player:getPile("ol_ex__dengai_field") > 0
  end,
  enabled_at_response = function(self, player)
    return #player:getPile("ol_ex__dengai_field") > 0
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__jixi"] = "急袭",
  [":ol_ex__jixi"] = "你可以将一张“田”当【顺手牵羊】使用。",

  ["#ol_ex__jixi-viewas"] = "你是否想要发动“急袭”，将一张“田”当【顺手牵羊】使用？",
  
  ["$ol_ex__jixi1"] = "良田为济，神兵天降！",
  ["$ol_ex__jixi2"] = "明至剑阁，暗袭蜀都！",
}

return this