local sanku = fk.CreateSkill{
  name = "sanku",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["sanku"] = "三窟",
  [":sanku"] = "锁定技，当你进入濒死状态时，你减1点体力上限并回复体力至上限；当你的体力上限增加时，防止之。",

  ["$sanku1"] = "纲常难为，应存后路。",
  ["$sanku2"] = "世将大乱，当思保全。",
}

sanku:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sanku.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = sanku.name,
      }
    end
  end,
})
sanku:addEffect(fk.BeforeMaxHpChanged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sanku.name) and data.num > 0
  end,
  on_use = function(self, event, target, player, data)
    data:preventMaxHpChange()
  end,
})

return sanku
