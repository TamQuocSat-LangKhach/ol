local guangao = fk.CreateSkill{
  name = "guangao",
}

Fk:loadTranslationTable{
  ["guangao"] = "犷骜",
  [":guangao"] = "你使用【杀】可以额外指定一个目标；其他角色使用【杀】可以额外指定你为目标（均有距离限制）。以此法使用的【杀】指定目标后，"..
  "若你的手牌数为偶数，你摸一张牌，令此【杀】对任意名角色无效。",

  ["#guangao-choose"] = "犷骜：你可以为此%arg额外指定一个目标",
  ["#guangao2-invoke"] = "犷骜：此%arg可以额外指定 %src 为目标",
  ["#guangao-cancel"] = "犷骜：你可以令此%arg对任意名角色无效",

  ["$guangao1"] = "策马觅封侯，长驱万里之数。",
  ["$guangao2"] = "大丈夫行事，焉能畏首畏尾。",
}

guangao:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(guangao.name) and data.card.trueName == "slash" then
      if target == player then
        return #data:getExtraTargets() > 0
      else
        return table.contains(data:getExtraTargets(), player) and not target.dead
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if target == player then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = data:getExtraTargets(),
        skill_name = guangao.name,
        prompt = "#guangao-choose:::"..data.card:toLogString(),
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    elseif room:askToSkillInvoke(target, {
      skill_name = guangao.name,
      prompt = "#guangao2-invoke:"..player.id.."::"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {player}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(guangao.name)
    if target == player then
      room:notifySkillInvoked(player, guangao.name, "offensive")
    else
      room:notifySkillInvoked(player, guangao.name, "negative")
      room:doIndicate(target, {player})
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.guangao = data.extra_data.guangao or {}
    table.insertIfNeed(data.extra_data.guangao, player.id)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})
guangao:addEffect(fk.TargetSpecified, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(guangao.name) and data.card.trueName == "slash" and data.firstTarget and
      data.extra_data and data.extra_data.guangao and table.contains(data.extra_data.guangao, player.id) and
      player:getHandcardNum() % 2 == 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(1, guangao.name)
    if player.dead then return end
    local targets = table.filter(data.use.tos, function (p)
      return not p.dead
    end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 9,
        targets = targets,
        skill_name = guangao.name,
        prompt = "#guangao-cancel:::"..data.card:toLogString(),
        cancelable = true,
      })
      if #tos > 0 then
        data.use.nullifiedTargets = data.use.nullifiedTargets or {}
        for _, p in ipairs(tos) do
          table.insertIfNeed(data.use.nullifiedTargets, p)
        end
      end
    end
  end,
})

return guangao
