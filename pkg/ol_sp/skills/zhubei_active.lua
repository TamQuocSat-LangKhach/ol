local zhubei_active = fk.CreateSkill{
  name = "zhubei_active",
}

Fk:loadTranslationTable{
  ["zhubei_active"] = "逐北",
}

local U = require "packages/utility/utility"

zhubei_active:addEffect("active", {
  min_card_num = function (self, player)
    return player:getMark("zhubei-tmp")[1] + 1
  end,
  target_num = 0,
  interaction = function(self, player)
    return U.CardNameBox { choices = player:getMark("zhubei-tmp")[2] }
  end,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "zhubei"
    card:addSubcards(selected)
    return not player:prohibitUse(card)  --盲猜无合法性判定
  end,
})

return zhubei_active
