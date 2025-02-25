local this = fk.CreateSkill {
  name = "ol_ex__guidao",
}

this:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(player, { min_num =  1, max_num = 1, include_equip = true, skill_name = this.name, cancelable = true, pattern = ".|.|spade,club", prompt = "#ol_ex__guidao-ask::" .. target.id..":"..data.reason })
    if #cards == 1 then
      self.cost_data = {cards = cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:getCardById(self.cost_data.cards[1])
    player.room:retrial(card, player, data, this.name, true)
    if not player.dead and card.suit == Card.Spade and card.number > 1 and card.number < 10 then
      player:drawCards(1, this.name)
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__guidao"] = "鬼道",
  [":ol_ex__guidao"] = "当一名角色的判定结果确定前，你可打出一张黑色牌代替之，你获得原判定牌，若你打出的牌是♠2~9，你摸一张牌。",

  ["#ol_ex__guidao-ask"] = "鬼道：可以打出一张黑色牌替换 %dest 的“%arg”判定，若打出♠2~9，你摸一张牌",
  
  ["$ol_ex__guidao1"] = "鬼道运行，由我把控！",
  ["$ol_ex__guidao2"] = "汝之命运，吾来改之！",
}

return this
