local guidao = fk.CreateSkill {
  name = "ol_ex__guidao",
}

Fk:loadTranslationTable{
  ["ol_ex__guidao"] = "鬼道",
  [":ol_ex__guidao"] = "当一名角色的判定结果确定前，你可打出一张黑色牌代替之，你获得原判定牌，若你打出的牌是♠2~9，你摸一张牌。",

  ["#ol_ex__guidao-ask"] = "鬼道：可以打出一张黑色牌替换 %dest 的“%arg”判定，若打出♠2~9，你摸一张牌",

  ["$ol_ex__guidao1"] = "鬼道运行，由我把控！",
  ["$ol_ex__guidao2"] = "汝之命运，吾来改之！",
}

guidao:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guidao.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local response = room:askToResponse(player, {
      skill_name = guidao.name,
      pattern = ".|.|spade,club|hand,equip",
      prompt = "#ol_ex__guidao-ask::"..target.id..":"..data.reason,
      cancelable = true,
    })
    if response then
      event:setCostData(self, {extra_data = response.card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local card = event:getCostData(self).extra_data
    player.room:retrial(card, player, data, guidao.name, true)
    if not player.dead and card.suit == Card.Spade and card.number > 1 and card.number < 10 then
      player:drawCards(1, guidao.name)
    end
  end,
})

return guidao
