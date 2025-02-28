local xiaoshi = fk.CreateSkill{
  name = "xiaoshi",
}

Fk:loadTranslationTable{
  ["xiaoshi"] = "枭噬",
  [":xiaoshi"] = "出牌阶段内限一次，当你使用基本牌或普通锦囊牌指定目标时，可以额外指定一个目标（无距离限制），若此牌未造成伤害，你失去1点体力或"..
  "令其中一个目标摸X张牌（X为你上次发动〖矜名〗选择项的序号）。",

  ["#xiaoshi-choose"] = "枭噬：你可以为%arg额外指定一个目标",
  ["#xiaoshi-draw"] = "枭噬：你须令其中一名目标角色摸%arg张牌，或点“取消”失去1点体力！",

  ["$xiaoshi1"] = "胸有欲壑，泰山难填、息壤难掩。",
  ["$xiaoshi2"] = "子欲奉汝之骨肉为宴否？",
}

xiaoshi:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiaoshi.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player.phase == Player.Play and player:usedSkillTimes(xiaoshi.name, Player.HistoryPhase) == 0 and
      #data:getExtraTargets({bypass_distances = true}) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets({bypass_distances = true}),
      skill_name = xiaoshi.name,
      prompt = "#xiaoshi-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
    data.extra_data = data.extra_data or {}
    data.extra_data.xiaoshi = player
  end,
})
xiaoshi:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      data.extra_data and data.extra_data.xiaoshi == player and not data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function (p)
      return not p.dead
    end)
    if #targets == 0 or player:getMark("@jinming") == 0 then
      room:loseHp(player, 1, xiaoshi.name)
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xiaoshi.name,
        prompt = "#xiaoshi-draw:::"..player:getMark("@jinming"),
        cancelable = true,
      })
      if #to > 0 then
        to[1]:drawCards(player:getMark("@jinming"), xiaoshi.name)
      else
        room:loseHp(player, 1, xiaoshi.name)
      end
    end
  end,
})

return xiaoshi
