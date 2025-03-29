local zongshi = fk.CreateSkill{
  name = "ol_ex__zongshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__zongshi"] = "宗室",
  [":ol_ex__zongshi"] = "锁定技，你的手牌上限+X（X为全场势力数）。其他角色对你造成伤害时，防止此伤害并令其获得你区域内的一张牌，每个势力限一次。",
}

zongshi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zongshi.name) and data.from and data.from ~= player and
      not table.contains(player:getTableMark(zongshi.name), data.from.kingdom)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:addTableMark(player, zongshi.name, data.from.kingdom)
    if not data.from.dead and not player:isAllNude() then
      room:doIndicate(player, {data.from})
      local card = room:askToChooseCard(data.from, {
        target = player,
        flag = "hej",
        skill_name = zongshi.name,
      })
      room:moveCardTo(card, Card.PlayerHand, data.from, fk.ReasonJustMove, zongshi.name, nil, false, data.from)
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