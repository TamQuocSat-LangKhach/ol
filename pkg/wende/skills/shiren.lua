local shiren = fk.CreateSkill{
  name = "shiren",
  tags = { Skill.Hidden },
}

Fk:loadTranslationTable{
  ["shiren"] = "识人",
  [":shiren"] = "隐匿技，当你于其他角色的回合登场后，你可以对其发动〖宴戏〗。",

  ["#shiren-invoke"] = "识人：你可以对 %dest 发动〖宴戏〗",

  ["$shiren1"] = "宠过必乱，不可大任。",
  ["$shiren2"] = "开卷有益，识人有法",
}

shiren:addEffect(fk.GeneralAppeared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasShownSkill(shiren.name) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local to = turn_event.data.who
      if to ~= player and not to.dead and not to:isKongcheng() then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shiren.name,
      prompt = "#shiren-invoke::"..room.current.id,
    }) then
      event:setCostData(self, {tos = {room.current}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    Fk.skills["yanxi"]:onUse(room, {
      from = player,
      tos = {room.current},
    })
  end,
})

return shiren
