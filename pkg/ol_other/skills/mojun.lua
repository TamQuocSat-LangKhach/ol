local mojun = fk.CreateSkill{
  name = "mojun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mojun"] = "魔军",
  [":mojun"] = "锁定技，当友方角色使用【杀】造成伤害后，你判定，若结果为黑色，友方角色各摸一张牌。",
}

mojun:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mojun.name) and data.from and
      data.from:isFriend(player) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = mojun.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge:matchPattern() then
      room:doIndicate(player, player:getFriends())
      for _, p in ipairs(player:getFriends()) do
        if not p.dead then
          p:drawCards(1, mojun.name)
        end
      end
    end
  end,
})

return mojun
