local yilie = fk.CreateSkill{
  name = "yilie",
}

Fk:loadTranslationTable{
  ["yilie"] = "义烈",
  [":yilie"] = "你可以将两张颜色相同的手牌当一张本轮未以此法使用过的基本牌使用。",

  ["#yilie"] = "义烈：将两张颜色相同的手牌当一张基本牌使用",

  ["$yilie1"] = "从来天下义，只在青山中！",
  ["$yilie2"] = "沥血染征袍，英名万古存！",
}

local U = require "packages/utility/utility"

yilie:addEffect("viewas", {
  prompt = "#yilie",
  pattern = ".|.|.|.|.|basic",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(yilie.name, all_names, {}, player:getTableMark("yilie-round"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getHandlyIds(), to_select) and #selected < 2 and
      table.every(selected, function (id)
        return Fk:getCardById(id):compareColorWith(Fk:getCardById(to_select))
      end)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = yilie.name
    card:addSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "yilie-round", use.card.trueName)
  end,
  enabled_at_response = function(self, player, response)
    return #player:getViewAsCardNames(yilie.name, Fk:getAllCardNames("b"), {}, player:getTableMark("yilie-round")) > 0
  end,
})

return yilie
