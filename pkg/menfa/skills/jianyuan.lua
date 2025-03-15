local jianyuan = fk.CreateSkill{
  name = "jianyuan",
}

Fk:loadTranslationTable{
  ["jianyuan"] = "简远",
  [":jianyuan"] = "当一名角色发动“出牌阶段限一次”的技能后，你可以令其重铸任意张牌名字数为X的牌（X为其本阶段使用牌数）。",

  ["#jianyuan-invoke"] = "简远：你可以令 %dest 重铸牌",
  ["#jianyuan-ask"] = "简远：你可以重铸任意张牌名字数为%arg的牌",

  ["$jianyuan1"] = "我视天地为三，其为众妙之门。",
  ["$jianyuan2"] = "昔年孔明有言，宁静方能致远。",
}

jianyuan:addEffect(fk.AfterSkillEffect, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jianyuan.name) and target and not target.dead and not target:isKongcheng() and
      (data.skill:isInstanceOf(ActiveSkill) or data.skill:isInstanceOf(ViewAsSkill)) and
      data.skill:isPlayerSkill(target) and not data.skill.is_delay_effect and
      Fk:translate(":"..data.skill:getSkeleton().name, "zh_CN"):startsWith("出牌阶段限一次")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jianyuan.name,
      prompt = "#jianyuan-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 99, function(e)
      return e.data.from == target
    end, Player.HistoryPhase)
    if n == 0 then return end
    local cards = table.filter(target:getCardIds("he"), function (id)
      return Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len() == n
    end)
    local ids = room:askToCards(target, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = jianyuan.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#jianyuan-ask:::"..n,
      cancelable = true,
    })
    if #ids > 0 then
      room:recastCard(ids, target, jianyuan.name)
    end
  end,
})

return jianyuan
