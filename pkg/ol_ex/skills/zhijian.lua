local U = require("packages.utility.utility")

local this = fk.CreateSkill{
  name = "ol_ex__zhijian",
}

this:addEffect("active", {
  anim_type = "support",
  prompt = "#ol_ex__zhijian-active",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and to_select ~= Self.id and
    U.canMoveCardIntoEquip(to_select, selected_cards[1], true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardIntoEquip(target, effect.cards[1], this.name, true, player)
    if not player.dead then
      room:drawCards(player, 1, this.name)
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__zhijian"] = "直谏",
  [":ol_ex__zhijian"] = "出牌阶段，你可以将一张装备牌置于其他角色装备区（替换原装备），然后摸一张牌。",
  
  ["#ol_ex__zhijian-active"] = "你是否想要发动“直谏”，将一张装备牌置入其他角色的装备区（替换原装备）？",
  
  ["$ol_ex__zhijian1"] = "君有恙，臣等当舍命除之。",
  ["$ol_ex__zhijian2"] = "臣有言在喉，不吐不快。",
}

return this
