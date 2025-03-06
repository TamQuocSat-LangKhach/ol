local kuangshou = fk.CreateSkill{
  name = "kuangshou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kuangshou"] = "㑌守",
  [":kuangshou"] = "锁定技，当你受到伤害后，你摸三张牌，然后弃置X张牌（X为本回合受到过伤害的角色数）。",

  ["$kuangshou1"] = "常言道以和为贵，打打杀杀作甚？",
  ["$kuangshou2"] = "诸位都是体面人，不可妄动刀兵。",
}

kuangshou:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, kuangshou.name)
    if player.dead or player:isNude() then return end
    local n = {}
    room.logic:getActualDamageEvents(1, function (e)
      table.insertIfNeed(n, e.data.to)
    end, Player.HistoryTurn)
    room:askToDiscard(player, {
      min_num = #n,
      max_num = #n,
      include_equip = true,
      skill_name = kuangshou.name,
      cancelable = false,
    })
  end,
})

return kuangshou
