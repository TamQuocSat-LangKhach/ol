local luanfeng = fk.CreateSkill{
  name = "luanfeng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["luanfeng"] = "鸾凤",
  [":luanfeng"] = "限定技，当一名角色处于濒死状态时，若其体力上限不小于你，你可以令其将体力回复至3点，恢复其被废除的装备栏，令其手牌补至6-X张" ..
  "（X为以此法恢复的装备栏数量）。若该角色为你，重置你〖游龙〗使用过的牌名。",

  ["#luanfeng-invoke"] = "鸾凤：是否令 %dest 回复体力至3点、恢复被废除的装备栏并摸牌？",

  ["$luanfeng1"] = "凤栖枯木，浴火涅槃！",
  ["$luanfeng2"] = "青鸾归宇，雏凤还巢！",
}

luanfeng:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(luanfeng.name) and target.maxHp >= player.maxHp and
      player:usedSkillTimes(luanfeng.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = luanfeng.name,
      prompt = "#luanfeng-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      room:setPlayerMark(player, "@$youlong", 0)
    end
    room:recover {
      who = target,
      num = 3 - target.hp,
      recoverBy = player,
      skillName = luanfeng.name,
    }
    if target.dead then return end
    local slots = table.simpleClone(target.sealedSlots)
    table.removeOne(slots, Player.JudgeSlot)
    local x = #slots
    if x > 0 then
      room:resumePlayerArea(target, slots)
    end
    local n = target:getHandcardNum()
    if n < 6 - x then
      target:drawCards(6 - x - n, luanfeng.name)
    end
  end,
})

return luanfeng
