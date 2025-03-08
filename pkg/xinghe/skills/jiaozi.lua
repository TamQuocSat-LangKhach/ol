local jiaozi = fk.CreateSkill{
  name = "jiaozi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaozi"] = "骄恣",
  [":jiaozi"] = "锁定技，当你造成或受到伤害时，若你的手牌为全场唯一最多，则此伤害+1。",

  ["$jiaozi1"] = "数战之功，吾应得此赏！",
  ["$jiaozi2"] = "无我出力，怎会连胜？",
}

local jiaozi_spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaozi.name) and
      table.every(player.room:getOtherPlayers(player, false), function(p)
        return player:getHandcardNum() > p:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
}

jiaozi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = jiaozi_spec.can_trigger,
  on_use = jiaozi_spec.on_use,
})
jiaozi:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = jiaozi_spec.can_trigger,
  on_use = jiaozi_spec.on_use,
})

return jiaozi
