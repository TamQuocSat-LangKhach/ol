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
    local ids = table.filter(table.connect(player:getHandlyIds(), player:getCardIds("e")), function (id)
      return Fk:getCardById(id).color == Card.Black and not player:prohibitResponse(Fk:getCardById(id))
    end)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = guidao.name,
      include_equip = true,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#ol_ex__guidao-ask::"..target.id..":"..data.reason,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    player.room:changeJudge{
      card = card,
      player = player,
      data = data,
      skillName = guidao.name,
      response = true,
      exchange = true,
    }
    if not player.dead and card.suit == Card.Spade and card.number > 1 and card.number < 10 then
      player:drawCards(1, guidao.name)
    end
  end,
})

return guidao
