local jili = fk.CreateSkill{
  name = "jili",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jili"] = "寄篱",
  [":jili"] = "锁定技，当与你距离为1的其他角色成为红色基本牌或红色普通锦囊牌的目标时，若你不是此牌的使用者和目标，你成为此牌的额外目标。",

  ["$jili1"] = "寄人篱下的日子，不好过呀！",
  ["$jili2"] = "这份恩德，白虎记下了！",
}

jili:addEffect(fk.TargetConfirming, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jili.name) and target:distanceTo(player) == 1 and
      data.card.color == Card.Red and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      data.from ~= player and not table.contains(data.use.tos, player) and
      not data.from:isProhibited(player, data.card)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.is_damage_card or
      table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name) or
      data.card.is_derived then
      player:broadcastSkillInvoke(jili.name, 1)
      room:notifySkillInvoked(player, jili.name, "negative")
    else
      player:broadcastSkillInvoke(jili.name, 2)
      room:notifySkillInvoked(player, jili.name, "control")
    end
    data:addTarget(player)
  end,
})

return jili
