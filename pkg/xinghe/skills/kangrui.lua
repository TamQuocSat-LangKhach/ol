local kangrui = fk.CreateSkill{
  name = "kangrui",
}

Fk:loadTranslationTable{
  ["kangrui"] = "亢锐",
  [":kangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并令其：1.回复1点体力；2.本回合下次造成的伤害+1。然后当其造成伤害时，"..
  "其此回合手牌上限改为0。",

  ["#kangrui-invoke"] = "亢锐：你可以摸一张牌，令 %dest 回复1点体力或本回合下次造成伤害+1",
  ["kangrui_damage"] = "本回合下次造成伤害+1",
  ["#kangrui-choice"] = "亢锐：选择令 %dest 执行的一项",
  ["@kangrui-turn"] = "亢锐",
  ["kangrui_adddamage"] = "加伤害",

  ["$kangrui1"] = "尔等魍魉，愿试吾剑之利乎？",
  ["$kangrui2"] = "诸君鼓力，克复中原指日可待！",
}

kangrui:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(kangrui.name) and not target.dead then
      local room = player.room
      if room.current ~= target then return false end
      local damage_event = room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
      if damage_event == nil then return false end
      local x = target:getMark("kangrui_record-turn")
      if x == 0 then
        room.logic:getActualDamageEvents(1, function (e)
          if e.data.to == target then
            x = e.id
            room:setPlayerMark(target, "kangrui_record-turn", x)
            return true
          end
          return false
        end)
      end
      return x == damage_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = kangrui.name,
      prompt = "#kangrui-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, kangrui.name)
    if player.dead or target.dead then return false end
    local choices = {"kangrui_damage"}
    if target:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = kangrui.name,
      prompt = "#kangrui-choice::"..target.id,
      all_choices = {"recover", "kangrui_damage"},
    })
    if choice == "recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = kangrui.name,
      }
      if target.dead then return false end
      room:setPlayerMark(target, "@kangrui-turn", "")
    else
      room:setPlayerMark(target, "@kangrui-turn", "kangrui_adddamage")
    end
  end,
})
kangrui:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@kangrui-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@kangrui-turn") == "kangrui_adddamage" then
      if player:hasSkill(kangrui.name, true) then
        room:notifySkillInvoked(player, kangrui.name, "offensive")
        player:broadcastSkillInvoke(kangrui.name)
      end
      data:changeDamage(1)
    end
    room:setPlayerMark(player, "@kangrui-turn", 0)
    room:setPlayerMark(player, "kangrui_minus-turn", 1)
  end,
})
kangrui:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:getMark("kangrui_minus-turn") > 0 then
      return 0
    end
  end,
})

return kangrui
