local runwei = fk.CreateSkill{
  name = "runwei",
}

Fk:loadTranslationTable{
  ["runwei"] = "润微",
  [":runwei"] = "一名角色弃牌阶段开始时，若其已受伤，你可以选择一项：1.令其弃置一张牌，其本回合手牌上限+1；"..
  "2.令其摸一张牌，其本回合手牌上限-1。",

  ["#runwei-invoke"] = "润微：你可以令 %dest 执行一项",
  ["runwei1"] = "令其弃一张牌，手牌上限+1",
  ["runwei2"] = "令其摸一张牌，手牌上限-1",

  ["$runwei1"] = "流水不言，泽德万物。",
  ["$runwei2"] = "生如春雨，润物无声。",
}

runwei:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(runwei.name) and target.phase == Player.Discard and
      target:isWounded() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"runwei2", "Cancel"}
    if not target:isNude() and
      (target ~= player or table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end)) then
        table.insert(choices, 1, "runwei1")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = runwei.name,
      prompt = "#runwei-invoke::"..target.id,
      all_choices = {"runwei1", "runwei2", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "runwei1" then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = runwei.name,
        cancelable = false,
      })
    else
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 1)
      target:drawCards(1, runwei.name)
    end
  end,
})

return runwei
