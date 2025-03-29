local shichou = fk.CreateSkill{
  name = "ol__shichou",
}

Fk:loadTranslationTable{
  ["ol__shichou"] = "誓仇",
  [":ol__shichou"] = "你使用【杀】可以多选择至多X+1名角色为目标（X为你已损失的体力值）。",

  ["#ol__shichou-choose"] = "誓仇：你可以为此%arg额外指定至多%arg2个目标",

  ["$ol__shichou1"] = "你们一个都别想跑！",
  ["$ol__shichou2"] = "新仇旧恨，一并结算！",
}

shichou:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shichou.name) and data.card.trueName == "slash" and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = player:getLostHp() + 1,
      targets = data:getExtraTargets(),
      skill_name = shichou.name,
      prompt = "#ol__shichou-choose:::"..data.card:toLogString()..":"..player:getLostHp() + 1,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return shichou
