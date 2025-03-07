local luanzhan = fk.CreateSkill{
  name = "luanzhan",
}

Fk:loadTranslationTable{
  ["luanzhan"] = "乱战",
  [":luanzhan"] = "当你造成或受到伤害后，你获得1枚“乱战”标记。当你使用【杀】或黑色普通锦囊牌指定目标后，若目标角色数小于X，"..
  "你移除一半“乱战”标记（向上取整）。你使用【杀】或黑色普通锦囊牌可以额外指定至多X个目标。（X为“乱战”标记数）",

  ["@luanzhan"] = "乱战",
  ["#luanzhan-choose"] = "乱战：你可以为%arg额外指定至多%arg2个目标",

  ["$luanzhan1"] = "受袁氏大恩，当效死力。",
  ["$luanzhan2"] = "现，正是我乌桓崛起之机。",
}

luanzhan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@luanzhan", 0)
end)

luanzhan:addEffect(fk.Damage, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(luanzhan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@luanzhan", 1)
  end,
})
luanzhan:addEffect(fk.Damaged, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(luanzhan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@luanzhan", 1)
  end,
})
luanzhan:addEffect(fk.TargetSpecified, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(luanzhan.name) and data.firstTarget and
      (data.card.trueName == "slash" or (data.card.color == Card.Black and data.card:isCommonTrick())) and
      #data.use.tos < player:getMark("@luanzhan")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@luanzhan", (player:getMark("@luanzhan") + 1) // 2)
  end,
})
luanzhan:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(luanzhan.name) and
      (data.card.trueName == "slash" or (data.card.color == Card.Black and data.card:isCommonTrick())) and
      #data:getExtraTargets() > 0 and player:getMark("@luanzhan") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = player:getMark("@luanzhan"),
      targets = data:getExtraTargets(),
      skill_name = luanzhan.name,
      prompt = "#luanzhan-choose:::"..data.card:toLogString()..":"..player:getMark("@luanzhan"),
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


return luanzhan
