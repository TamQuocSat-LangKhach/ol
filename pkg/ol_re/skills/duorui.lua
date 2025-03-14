local duorui = fk.CreateSkill{
  name = "ol__duorui",
}

Fk:loadTranslationTable {
  ["ol__duorui"] = "夺锐",
  [":ol__duorui"] = "当你于出牌阶段内对一名其他角色造成伤害后，若其没有因此技能而失效的技能，你可以令其武将牌上的一个技能失效直到"..
  "其下回合结束，然后结束此阶段。",

  ["#ol__duorui-choice"] = "夺锐：是否结束出牌阶段，令 %dest 一个技能失效直到其下回合结束？",
  ["@ol__duorui"] = "被夺锐",

  ["$ol__duorui1"] = "天下雄兵之锐，吾一人可尽夺之！",
  ["$ol__duorui2"] = "夺旗者勇，夺命者利，夺锐者神！",
}

duorui:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(duorui.name) and
      data.to ~= player and not data.to.dead and player.phase == Player.Play and
      data.to:getMark("@ol__duorui") == 0 then
      local skills = Fk.generals[data.to.general]:getSkillNameList()
      if data.to.deputyGeneral ~= "" then
        table.insertTable(skills, Fk.generals[data.to.deputyGeneral]:getSkillNameList())
      end
      return table.find(skills, function (s)
        return data.to:hasSkill(s, true)
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = Fk.generals[data.to.general]:getSkillNameList()
    if data.to.deputyGeneral ~= "" then
      table.insertTable(choices, Fk.generals[data.to.deputyGeneral]:getSkillNameList())
    end
    choices = table.filter(choices, function (s)
      return data.to:hasSkill(s, true)
    end)
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = duorui.name,
      prompt = "#ol__duorui-choice::"..data.to.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.to}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(data.to, "@ol__duorui", event:getCostData(self).choice)
    player:endPlayPhase()
  end,
})
duorui:addEffect(fk.TurnEnd, {
  late_refresh =  true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ol__duorui") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@ol__duorui", 0)
  end,
})
duorui:addEffect("invalidity", {
  invalidity_func = function(self, player, skill)
    return player:getMark("@ol__duorui") == skill.name
  end
})

return duorui
