local ruilue_active = fk.CreateSkill {
  name = "ruilue&",
}

Fk:loadTranslationTable{
  ["ruilue&"] = "睿略",
  [":ruilue&"] = "出牌阶段限一次，你可以将一张【杀】或伤害锦囊牌交给司马师。",

  ["#ruilue"] = "睿略：你可以将一张伤害牌交给司马师",
}

ruilue_active:addEffect("active", {
  anim_type = "support",
  prompt = "#ruilue",
  mute = true,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    if player:usedSkillTimes(ruilue_active.name, Player.HistoryPhase) < 1 and player.kingdom == "jin" then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p:hasSkill("ruilue") and p ~= player
      end)
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).is_damage_card and
      table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room.alive_players, function(p)
      return p:hasSkill("ruilue") and p ~= player
    end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = "ruilue",
        prompt = "#ruilue",
        cancelable = false,
      })[1]
    end
    if not target then return end
    room:notifySkillInvoked(target, "ruilue")
    target:broadcastSkillInvoke("ruilue")
    room:doIndicate(player, {target})
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, "ruilue", nil, true, player)
  end,
})

return ruilue_active
