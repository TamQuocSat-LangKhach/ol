local shouhun = fk.CreateSkill{
  name = "shouhun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shouhun"] = "兽魂",
  [":shouhun"] = "锁定技，你的摸牌阶段摸牌数+2、手牌上限+2、体力上限+2；当你受到伤害时，令数值最低的一项数值+1（最大+4）。",

  [":shouhun_inner"] = "锁定技，你的摸牌阶段摸牌数+{1}、手牌上限+{2}、体力上限+{3}；当你受到伤害时，令数值最低的一项数值+1（最大+4）。",
}

shouhun.dynamicDesc = function (self, player)
  return "shouhun_inner:" ..
    (player:getMark("shouhun1") + 2) .. ":" ..
    (player:getMark("shouhun2") + 2) .. ":" ..
    (player:getMark("shouhun3") + 2)
end

shouhun:addAcquireEffect(function (self, player, is_start)
  if player:getMark("shouhun_acquire") == 0 then
    player.room:changeMaxHp(player, 2)
    player.room:setPlayerMark(player, "shouhun_acquire", 1)
  end
end)

shouhun:addEffect(fk.DamageInflicted, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shouhun.name) and
      table.find({1, 2, 3}, function (i)
        return player:getMark("shouhun"..i) < 2
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for i = 0, 1, 1 do
      for j = 1, 3, 1 do
        if player:getMark("shouhun"..j) == i then
          room:addPlayerMark(player, "shouhun"..j, 1)
          if j == 3 then
            room:changeMaxHp(player, 1)
          end
          return
        end
      end
    end
  end,
})
shouhun:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(shouhun.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + 2 + player:getMark("shouhun1")
  end,
})
shouhun:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(shouhun.name) then
      return 2 + player:getMark("shouhun2")
    end
  end,
})

return shouhun
