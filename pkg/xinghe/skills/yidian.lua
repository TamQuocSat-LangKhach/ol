local yidian = fk.CreateSkill{
  name = "yidian",
}

Fk:loadTranslationTable{
  ["yidian"] = "佚典",
  [":yidian"] = "若你使用的基本牌或普通锦囊牌在弃牌堆中没有同名牌，你可以为此牌指定一个额外目标（无距离限制）。",

  ["#yidian-choose"] = "佚典：你可以为此%arg额外指定一个目标",

  ["$yidian1"] = "无传书卷记，功过自有评。",
  ["$yidian2"] = "佚以典传，千秋谁记？",
}

yidian:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yidian.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not table.find(player.room.discard_pile, function(id)
        return Fk:getCardById(id).name == data.card.name
      end) and
      #data:getExtraTargets({bypass_distances = true}) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets({bypass_distances = true}),
      skill_name = yidian.name,
      prompt = "#yidian-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

return yidian
