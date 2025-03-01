local weiyi = fk.CreateSkill{
  name = "weiyi",
}

Fk:loadTranslationTable{
  ["weiyi"] = "威仪",
  [":weiyi"] = "每名角色限一次，当一名角色受到伤害后，若其体力值：1.不小于你，你可以令其失去1点体力；2.不大于你，你可以令其回复1点体力。",

  ["#weiyi-choice"] = "威仪：选择令 %dest 执行的一项",

  ["$weiyi1"] = "无威仪者，不可奉社稷。",
  ["$weiyi2"] = "有威仪者，进止雍容。",
}

weiyi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "weiyi_targets", 0)
end)

weiyi:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weiyi.name) and not target.dead and
      not table.contains(player:getTableMark("weiyi_targets"), target.id) and
      (target:isWounded() or target.hp >= player.hp)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if target.hp >= player.hp then
      table.insert(choices, "loseHp")
    end
    if target.hp <= player.hp and target:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = weiyi.name,
      prompt = "#weiyi-choice::"..target.id,
      all_choices = {"loseHp", "recover", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "weiyi_targets", target.id)
    if event:getCostData(self).choice == "loseHp" then
      room:notifySkillInvoked(player, weiyi.name, "offensive", {target.id})
      player:broadcastSkillInvoke(weiyi.name, 1)
      room:loseHp(target, 1, weiyi.name)
    else
      room:notifySkillInvoked(player, weiyi.name, "support", {target.id})
      player:broadcastSkillInvoke(weiyi.name, 2)
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = weiyi.name
      }
    end
  end,
})

return weiyi
