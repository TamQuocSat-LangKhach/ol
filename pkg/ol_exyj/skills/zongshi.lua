local zongshi = fk.CreateSkill{
  name = "ol_ex__zongshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__zongshi"] = "宗室",
  [":ol_ex__zongshi"] = "锁定技，你的手牌上限+X（X为全场势力数）。其他角色对你造成伤害时，防止此伤害并令其摸一张牌，每个势力限一次。",
}

zongshi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zongshi.name) and data.from and data.from ~= player and
      not table.contains(player:getTableMark("@ol_ex__zongshi"), data.from.kingdom)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:addTableMark(player, zongshi.name, data.from.kingdom)
    if not data.from.dead then
      room:doIndicate(player, {data.from})
      data.from:drawCards(1, zongshi.name)
    end
  end,
})

zongshi:addEffect("maxcards", {
  mute = true,
  correct_func = function(self, player)
    if player:hasSkill(zongshi.name) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms
    end
  end,
})

return zongshi