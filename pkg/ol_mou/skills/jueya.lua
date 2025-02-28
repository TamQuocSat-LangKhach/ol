local jueya = fk.CreateSkill{
  name = "jueya",
}

Fk:loadTranslationTable{
  ["jueya"] = "绝崖",
  [":jueya"] = "若你没有手牌，你可以于需要时视为使用一张基本牌（每种牌名限一次）。",

  ["#jueya"] = "绝崖：视为使用一张基本牌",
}

local U = require "packages/utility/utility"

jueya:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#jueya",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    return U.CardNameBox {
      choices = player:getViewAsCardNames(jueya.name, all_names, nil, player:getTableMark(jueya.name)),
      all_choices = all_names,
    }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = jueya.name
    return card
  end,
  before_use = function (self, player, use)
    player.room:addTableMark(player, jueya.name, use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return player:isKongcheng() and
      #player:getViewAsCardNames(jueya.name, Fk:getAllCardNames("b"), nil, player:getTableMark(jueya.name)) > 0
  end,
  enabled_at_response = function(self, player, response)
    if response or not player:isKongcheng() then return end
    return #player:getViewAsCardNames(jueya.name, Fk:getAllCardNames("b"), nil, player:getTableMark(jueya.name)) > 0
  end,
})

return jueya
