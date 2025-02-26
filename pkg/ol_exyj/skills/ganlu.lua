local U = require("packages/utility/utility")

local this = fk.CreateSkill{
  name = "ol_ex__ganlu",
}

this:addEffect("active", {
  anim_type = "control",
  target_num = 2,
  max_phase_use_time = 1,
  min_card_num = 0,
  prompt = function (self, player, selected_cards, selected_targets)
    if #selected_targets < 2 then
      return "#ol_ex__ganlu0:::"..player:getLostHp()
    else
      local n1 = #selected_targets[1]:getCardIds("e")
      local n2 = #selected_targets[2]:getCardIds("e")
      if math.abs(n1 - n2) <= player:getLostHp() then
        return "#ol_ex__ganlu1:"..selected_targets[1]..":"..selected_targets[2]
      else
        return "#ol_ex__ganlu2:"..selected_targets[1]..":"..selected_targets[2]..":"..math.abs(n1 - n2)
      end
    end
  end,
  card_filter = function (self, player, to_select, selected)
    return not player:prohibitDiscard(to_select) and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return not (#to_select:getCardIds("e") == 0 and #selected[1]:getCardIds("e") == 0)
    else
      return false
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected == 2 then
      local n1 = #selected[1]:getCardIds("e")
      local n2 = #selected[2]:getCardIds("e")
      if math.abs(n1 - n2) <= player:getLostHp() then
        return #selected_cards == 0
      else
        return #selected_cards == math.abs(n1 - n2)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if #effect.cards > 0 then
      room:throwCard(effect.cards, this.name, player, player)
    end
    local target1 = effect.tos[1]
    local target2 = effect.tos[2]
    if target1.dead or target2.dead then return end
    local cards1 = table.clone(target1:getCardIds("e"))
    local cards2 = table.clone(target2:getCardIds("e"))
    U.swapCards(room, player, target1, target2, cards1, cards2, this.name, Card.PlayerEquip)
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__ganlu"] = "甘露",
  [":ol_ex__ganlu"] = "出牌阶段限一次，你可以令两名角色交换装备区里的牌。若X大于你已损失体力值，你须先弃置X张手牌。（X为其装备区牌数之差）",
  
  ["#ol_ex__ganlu0"] = "甘露：令两名角色交换装备区里的牌，若牌数之差大于%arg，须先弃置手牌",
  ["#ol_ex__ganlu1"] = "甘露：令 %src 和 %dest 交换装备区里的牌",
  ["#ol_ex__ganlu2"] = "甘露：弃置%arg张手牌，令 %src 和 %dest 交换装备区里的牌",

  ["$ol_ex__ganlu1"] = "今见玄德，真佳婿也。",
  ["$ol_ex__ganlu2"] = "吾家有女，当择良婿。",
}

return this
