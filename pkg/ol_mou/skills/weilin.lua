local weilin = fk.CreateSkill{
  name = "weilingy",
}

Fk:loadTranslationTable{
  ["weilingy"] = "威临",
  [":weilingy"] = "每回合限一次，你可以将一张牌当任意一种【杀】或【酒】使用。"..
  "此牌的目标角色的所有与此牌颜色相同的手牌均视为【杀】直到回合结束。",

  ["#weilingy"] = "威临：将一张牌当任意属性的【杀】或【酒】使用",
  ["@weilingy-turn"] = "威临",

  ["$weilingy1"] = "汝等鼠辈，岂敢与某相抗！",
  ["$weilingy2"] = "义襄千里，威震华夏！",
}

local U = require "packages/utility/utility"

weilin:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#weilingy",
  pattern = "slash,analeptic",
  interaction = function(self, player)
    local all_names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if card.trueName == "slash" and not card.is_derived then
        table.insertIfNeed(all_names, card.name)
      end
    end
    table.insertIfNeed(all_names, "analeptic")
    return U.CardNameBox {
      choices = player:getViewAsCardNames(weilin.name, all_names),
      all_choices = all_names,
      default_choice = "AskForCardsChosen",
    }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk.all_card_types[self.interaction.data] ~= nil
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or Fk.all_card_types[self.interaction.data] == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = weilin.name
    return card
  end,
  before_use = function(self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.weilingy = player
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(weilin.name) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(weilin.name) == 0
  end,
})
weilin:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.weilingy == player and data.card.color ~= Card.NoColor
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local color = data.card:getColorString()
    for _, to in ipairs(data.tos) do
      if not to.dead then
        local mark = to:getTableMark("@weilingy-turn")
        if table.insertIfNeed(mark, color) then
          room:setPlayerMark(to, "@weilingy-turn", mark)
          to:filterHandcards()
        end
      end
    end
  end,
})
weilin:addEffect("filter", {
  mute = true,
  card_filter = function(self, to_select, player)
    return table.contains(player:getCardIds("h"), to_select.id) and
      table.contains(player:getTableMark("@weilingy-turn"), to_select:getColorString())
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
})

return weilin
