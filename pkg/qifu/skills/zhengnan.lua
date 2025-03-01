local zhengnan = fk.CreateSkill{
  name = "ol__zhengnan",
}

Fk:loadTranslationTable{
  ["ol__zhengnan"] = "征南",
  [":ol__zhengnan"] = "当其他角色死亡后，你可以摸三张牌，然后获得〖武圣〗〖当先〗〖制蛮〗中的一个。",

  ["#ol__zhengnan-choice"] = "征南：选择获得的技能",

  ["$ol__zhengnan1"] = "得丞相之命，平南蛮之乱！",
  ["$ol__zhengnan2"] = "随丞相南征，定当为国建功！",
}

zhengnan:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengnan.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, zhengnan.name)
    if player.dead then return end
    local choices = {"ex__wusheng", "dangxian", "ty_ex__zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askToChoice(player, {
        choices = choices,
        skill_name = zhengnan.name,
        prompt = "#ol__zhengnan-choice",
        detailed = true,
      })
      player.room:handleAddLoseSkills(player, choice)
    end
  end,
})

return zhengnan
