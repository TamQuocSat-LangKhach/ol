local taoyin = fk.CreateSkill{
  name = "taoyin",
  tags = { Skill.Hidden },
}

Fk:loadTranslationTable{
  ["taoyin"] = "不臣",
  [":taoyin"] = "隐匿技，当你于其他角色的回合登场后，你可以令其本回合的手牌上限-2。",

  ["#taoyin-invoke"] = "韬隐：你可以令 %dest 本回合手牌上限-2",

  ["$taoyin1"] = "司马氏善谋、善忍，善置汝于绝境！",
  ["$taoyin2"] = "隐忍数载，亦不坠青云之志！",
}

taoyin:addEffect(fk.GeneralAppeared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasShownSkill(taoyin.name) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local to = turn_event.data.who
      if to ~= player and not to.dead then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = taoyin.name,
      prompt = "#taoyin-invoke::"..room.current.id,
    }) then
      event:setCostData(self, {tos = {room.current}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room.current, MarkEnum.MinusMaxCardsInTurn, 2)
  end,
})

return taoyin
