local weijing = fk.CreateSkill{
  name = "weijing",
}

Fk:loadTranslationTable{
  ["weijing"] = "卫境",
  [":weijing"] = "每轮限一次，当你需要使用【杀】或【闪】时，你可以视为使用之。",

  ["#weijing"] = "卫境：你可以视为使用【杀】或【闪】",

  ["$weijing1"] = "战事兴起，最苦的，仍是百姓。",
  ["$weijing2"] = "国乃大家，保大家才有小家。",
}

local U = require "packages/utility/utility"

weijing:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#weijing",
  interaction = function(self, player)
    local names = player:getViewAsCardNames(weijing.name, {"slash", "jink"})
    return U.CardNameBox {choices = names, all_choices = {"slash", "jink"}}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = weijing.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(weijing.name, Player.HistoryRound) == 0 and
      #player:getViewAsCardNames(weijing.name, {"slash"}) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(weijing.name, Player.HistoryRound) == 0 and
      #player:getViewAsCardNames(weijing.name, {"slash", "jink"}) > 0
  end,
})

return weijing
