local qiaoshe = fk.CreateSkill{
  name = "qin__qiaoshe",
}

Fk:loadTranslationTable{
  ["qin__qiaoshe"] = "巧舌",
  [":qin__qiaoshe"] = "一名角色判定牌生效前，你可以令之点数增加或减少至多3。",

  ["#qin__qiaoshe-choice"] = "巧舌：你可以令 %dest 的“%arg”判定结果增加或减少至多3",

  ["$qin__qiaoshe"] = "巧舌如簧，虚实乱象。",
}

qiaoshe:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiaoshe.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = -3, 3, 1 do
      if data.card.number + i > 0 and data.card.number + i < 14 then
        if i <= 0 then
          table.insert(choices, tostring(i))
        else
          table.insert(choices, "+"..tostring(i))
        end
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qiaoshe.name,
      prompt = "#qin__qiaoshe-choice::"..target.id..":"..data.reason,
    })
    if choice ~= "0" then
      event:setCostData(self, {tos = {target}, choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local new_card = Fk:cloneCard(data.card.name, data.card.suit, data.card.number + event:getCostData(self).choice)
    new_card.id = data.card.id
    new_card.skillName = qiaoshe.name
    data.card = new_card
  end,
})

return qiaoshe
