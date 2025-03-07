local yingbing = fk.CreateSkill{
  name = "ol__yingbing",
  tag = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__yingbing"] = "影兵",
  [":ol__yingbing"] = "锁定技，有“咒”的角色使用与“咒”颜色相同的牌时，你摸一张牌；若这是你第二次因该“咒”摸牌，你获得该“咒”。",

  ["$ol__yingbing1"] = "影兵虽虚，亦能伤人无形！",
  ["$ol__yingbing2"] = "撒豆成兵，挥剑成河！",
}

yingbing:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingbing.name) and #target:getPile("ol__zhangbao_zhou") > 0 and
      data.card.color == Fk:getCardById(target:getPile("ol__zhangbao_zhou")[1]).color
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local zhou = target:getPile("ol__zhangbao_zhou")[1]
    player:drawCards(1, yingbing.name)
    if player.dead then return end
    local record = player:getTableMark(yingbing.name)
    local n = (record[tostring(zhou)] or 0) + 1
    if n == 2 then
      n = 0
      if table.contains(target:getPile("ol__zhangbao_zhou"), zhou) then
        room:obtainCard(player, zhou, false, fk.ReasonPrey, player, yingbing.name)
      end
    end
    record[tostring(zhou)] = n
    room:setPlayerMark(player, yingbing.name, record)
  end,
})

return yingbing
