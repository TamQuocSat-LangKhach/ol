local jianji = fk.CreateSkill{
  name = "jianjiw",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["jianjiw"] = "见机",
  [":jianjiw"] = "限定技，一名角色的回合结束时，若与其相邻的角色于此回合内均未使用过牌，你可以与其各摸一张牌；"..
  "若与其相邻的角色于此回合内均未成为过牌的目标，你可以视为使用【杀】。",

  ["#jianjiw-draw"] = "见机：是否与 %dest 各摸一张牌？",
  ["#jianjiw-draw-slash"] = "见机：是否与 %dest 各摸一张牌，然后可以视为使用【杀】？",
  ["#jianjiw-slash"] = "见机：是否视为使用【杀】？",

  ["$jianjiw1"] = "",
  ["$jianjiw2"] = "",
}

jianji:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jianji.name) and not (target.dead or target:isRemoved()) and
      player:usedSkillTimes(jianji.name, Player.HistoryGame) == 0 then
      local room = player.room
      local choices = {"1", "2"}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from and table.contains({target:getNextAlive(), target:getLastAlive()}, use.from) then
          table.removeOne(choices, "1")
        end
        if table.contains(use.tos, target:getNextAlive()) or table.contains(use.tos, target:getLastAlive()) then
          table.removeOne(choices, "2")
        end
        return #choices == 0
      end, Player.HistoryTurn)
      if table.contains(choices, "2") and not player:canUse(Fk:cloneCard("slash"), {bypass_times = true}) then
        table.removeOne(choices, "2")
      end
      if #choices > 0 then
        event:setCostData(self, {extra_data = choices})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = table.simpleClone(event:getCostData(self).extra_data)
    if table.contains(choices, "1") then
      local prompt = "#jianjiw-draw::"..target.id
      if #choices > 1 then
        prompt = "#jianjiw-draw-slash::"..target.id
      end
      if room:askToSkillInvoke(player, {
        skill_name = jianji.name,
        prompt = prompt,
      }) then
        event:setCostData(self, {tos = {target}, choice = choices})
        return true
      end
    end
    if table.contains(choices, "2") then
      local use = room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = jianji.name,
        prompt = "#jianjiw-slash",
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        skip = true,
      })
      if use then
        event:setCostData(self, {extra_data = use, choice = choices})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.simpleClone(event:getCostData(self).choice)
    if table.contains(choices, "1") then
      player:drawCards(1, jianji.name)
      if not target.dead then
        target:drawCards(1, jianji.name)
      end
      if player.dead or #choices == 1 then return end
      room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = jianji.name,
        prompt = "#jianjiw-slash",
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
    else
      room:useCard(event:getCostData(self).extra_data)
    end
  end,
})

return jianji
