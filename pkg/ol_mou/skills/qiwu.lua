local qiwu = fk.CreateSkill{
  name = "qiwu",
}

Fk:loadTranslationTable{
  ["qiwu"] = "栖梧",
  [":qiwu"] = "每回合限一次，当你受到伤害时，若你于当前回合内未受到过伤害，且来源为你或来源在你的攻击范围内，"..
  "你可以弃置一张红色牌，防止此伤害。",

  ["#qiwu-invoke"] = "栖梧：你可以弃置一张红色牌，防止此伤害",

  ["$qiwu1"] = "诶~没打着~",
  ["$qiwu2"] = "除了飞来的暗箭，无物可伤我。",
}

qiwu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiwu.name) and
      player:usedSkillTimes(qiwu.name, Player.HistoryTurn) == 0 and not player:isNude() and
      data.from and (data.from == player or player:inMyAttackRange(data.from)) and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qiwu.name,
      cancelable = true,
      pattern = ".|.|heart,diamond",
      prompt = "#qiwu-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    player.room:throwCard(event:getCostData(self).cards, qiwu.name, player, player)
  end,
})

return qiwu
