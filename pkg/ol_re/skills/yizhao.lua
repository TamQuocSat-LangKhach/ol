local yizhao = fk.CreateSkill {
  name = "ol__yizhao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__yizhao"] = "异兆",
  [":ol__yizhao"] = "锁定技，当你使用或打出一张牌时，获得等同于此牌点数的“黄”标记（至多为184），然后若“黄”标记数的十位数变化，"..
  "你随机获得牌堆中一张点数为变化后十位数的牌。",

  ["@zhangjiao_huang"] = "黄",

  ["$ol__yizhao1"] = "尔等高高在上，为何看不见这人间疾苦！",
  ["$ol__yizhao2"] = "人间春秋万载，唯黎庶居水深火热。",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizhao.name) and data.card.number > 0 and player:getMark("@zhangjiao_huang") < 184
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = tostring(player:getMark("@zhangjiao_huang"))
    room:addPlayerMark(player, "@zhangjiao_huang", math.min(184 - player:getMark("@zhangjiao_huang"), data.card.number))
    local n2 = tostring(player:getMark("@zhangjiao_huang"))
    if #n1 == 1 then
      if #n2 == 1 then return end
    else
      if n1:sub(#n1 - 1, #n1 - 1) == n2:sub(#n2 - 1, #n2 - 1) then return end
    end
    local x = n2:sub(#n2 - 1, #n2 - 1)
    if x == "0" then x = "10" end
    local card = room:getCardsFromPileByRule(".|"..x)
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, yizhao.name, nil, false, player)
    end
  end,
}

yizhao:addEffect(fk.CardUsing, spec)
yizhao:addEffect(fk.CardResponding, spec)

yizhao:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@zhangjiao_huang", 0)
end)

return yizhao
