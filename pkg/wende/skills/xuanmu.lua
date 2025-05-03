local xuanmu = fk.CreateSkill{
  name = "xuanmu",
  tags = { Skill.Hidden, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xuanmu"] = "宣穆",
  [":xuanmu"] = "隐匿技，锁定技，你于其他角色的回合登场时，防止你受到的伤害直到回合结束。",

  ["@@xuanmu-turn"] = "宣穆",

  ["$xuanmu1"] = "四门穆穆，八面莹澈。",
  ["$xuanmu2"] = "天色澄穆，心明清静。",
}
local U = require "packages/utility/utility"
xuanmu:addEffect(U.GeneralAppeared, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(xuanmu.name) and player.room.current ~= player
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@xuanmu-turn", 1)
  end,
})
xuanmu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@xuanmu-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

return xuanmu
