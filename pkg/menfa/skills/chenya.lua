local chenya = fk.CreateSkill{
  name = "chenya",
}

Fk:loadTranslationTable{
  ["chenya"] = "沉雅",
  [":chenya"] = "一名角色发动“出牌阶段限一次”的技能后，你可以令其重铸任意张牌名字数为X的牌（X为其手牌数）。",

  ["#chenya-invoke"] = "沉雅：你可以令 %dest 重铸牌",
  ["#chenya-ask"] = "沉雅：你可以重铸任意张牌名字数为%arg的牌",

  ["$chenya1"] = "喜怒不现于形，此为执中之道。",
  ["$chenya2"] = "胸有万丈之海，故而波澜不惊。",
}

chenya:addEffect(fk.AfterSkillEffect, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenya.name) and target and not target.dead and not target:isKongcheng() and
      (data.skill:isInstanceOf(ActiveSkill) or data.skill:isInstanceOf(ViewAsSkill)) and
      data.skill:isPlayerSkill(target) and not data.skill.is_delay_effect and
      Fk:translate(":"..data.skill:getSkeleton().name, "zh_CN"):startsWith("出牌阶段限一次")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chenya.name,
      prompt = "#chenya-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(target:getCardIds("he"), function (id)
      return Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len() == target:getHandcardNum()
    end)
    local ids = room:askToCards(target, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = chenya.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#chenya-ask:::"..target:getHandcardNum(),
      cancelable = true,
    })
    if #ids > 0 then
      room:recastCard(ids, target, chenya.name)
    end
  end,
})

return chenya
