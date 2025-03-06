local aocai = fk.CreateSkill{
  name = "aocai",
}

Fk:loadTranslationTable{
  ["aocai"] = "傲才",
  [":aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌（若你没有手牌则改为四张），使用或打出其中你需要的牌。",

  ["#aocai"] = "傲才：你可以使用或打出其中你需要的基本牌",

  ["$aocai1"] = "哼，易如反掌。",
  ["$aocai2"] = "吾主圣明，泽披臣属。",
}

aocai:addEffect("viewas", {
  anim_type = "special",
  pattern = ".|.|.|.|.|basic",
  prompt = "#aocai",
  expand_pile = function(self, player)
    local n = player:isKongcheng() and 4 or 2
    local ids = {}
    for i = 1, n, 1 do
      if i > #Fk:currentRoom().draw_pile then break end
      table.insert(ids, Fk:currentRoom().draw_pile[i])
    end
    return ids
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(Fk:currentRoom().draw_pile, to_select) then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeBasic then
        if Fk.currentResponsePattern == nil then
          return player:canUse(card) and not player:prohibitUse(card)
        else
          return Exppattern:Parse(Fk.currentResponsePattern):match(card)
        end
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return Fk:currentRoom().current ~= player and
      #player:getViewAsCardNames(aocai.name, Fk:getAllCardNames("b")) > 0
  end,
})

return aocai
