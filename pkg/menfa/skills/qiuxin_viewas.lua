local qiuxin_viewas = fk.CreateSkill{
  name = "qiuxin_viewas",
}

Fk:loadTranslationTable{
  ["qiuxin_viewas"] = "求心",
}

local U = require "packages/utility/utility"

qiuxin_viewas:addEffect("active", {
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local to = Fk:currentRoom():getPlayerById(self.qiuxin_to)
    local names = table.filter(all_names, function (card_name)
      local card = Fk:cloneCard(card_name)
      card.skillName = "qiuxin"
      return not (player:prohibitUse(card) or player:isProhibited(to, card)) and
        card.skill:modTargetFilter(player, to, {}, card, {bypass_distances = true})
    end)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "qiuxin"
    local to = Fk:currentRoom():getPlayerById(self.qiuxin_to)
    if #selected == 0 then
      return to_select == to and
        not player:isProhibited(to_select, card) and
        card.skill:modTargetFilter(player, to_select, {}, card, {bypass_distances = true, bypass_times = true})
    else
      return card.skill:targetFilter(player, to_select, selected, {}, card, {bypass_distances = true, bypass_times = true})
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "qiuxin"
    local to = Fk:currentRoom():getPlayerById(self.qiuxin_to)
    return #selected >= card.skill:getMinTargetNum(player) and selected[1] == to
  end,
})

return qiuxin_viewas
