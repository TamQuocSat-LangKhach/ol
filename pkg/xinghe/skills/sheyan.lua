local sheyan = fk.CreateSkill{
  name = "sheyan",
}

Fk:loadTranslationTable{
  ["sheyan"] = "舍宴",
  [":sheyan"] = "当你成为一张普通锦囊牌的目标时，你可以为此牌增加一个目标或减少一个目标（目标数至少为一）。",

  ["#sheyan-choose"] = "舍宴：你可以为%arg增加或减少一个目标",

  ["$sheyan1"] = "公事为重，宴席不去也罢。",
  ["$sheyan2"] = "还是改日吧。",
}

sheyan:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(sheyan.name) and data.card:isCommonTrick() then
      local targets = data:getExtraTargets()
      local origin_targets = data.use.tos
      if #origin_targets > 1 then
        table.insertTable(targets, origin_targets)
      end
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = event:getCostData(self).extra_data,
      skill_name = sheyan.name,
      prompt = "#sheyan-choose:::"..data.card:toLogString(),
      cancelable = true,
      extra_data = table.map(data.use.tos, Util.IdMapper),
      target_tip_name = "addandcanceltarget_tip",
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    if table.contains(data.use.tos, to) then
      data:cancelTarget(to)
    else
      data:addTarget(to)
    end
  end,
})

return sheyan
