local zhibing = fk.CreateSkill{
  name = "zhibing",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhibing"] = "执柄",
  [":zhibing"] = "主公技，锁定技，准备阶段，若其他群雄势力角色累计使用黑色牌达到：3张，你加1点体力上限并回复1体力；6张，你获得〖焚城〗；"..
  "9张，你获得〖崩坏〗",

  ["@zhibing"] = "执柄",

  ["$zhibing1"] = "老夫为这大汉江山是操碎了心呐。",
  ["$zhibing2"] = "老夫言尽于此，哪个敢说半个不字？",
}

zhibing:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@zhibing", 0)
end)

zhibing:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhibing.name) and player.phase == Player.Start then
      if player:getMark("@zhibing") > 2 and not table.contains(player:getTableMark(zhibing.name), 1) then
        return true
      end
      if player:getMark("@zhibing") > 5 and not table.contains(player:getTableMark(zhibing.name), 2) then
        return not player:hasSkill("ty_ex__fencheng", true)
      end
      if player:getMark("@zhibing") > 8 and not table.contains(player:getTableMark(zhibing.name), 3) then
        return not player:hasSkill("benghuai", true)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@zhibing") > 2 and not table.contains(player:getTableMark(zhibing.name), 1) then
      room:addTableMark(player, zhibing.name, 1)
      room:changeMaxHp(player, 1)
      if not player.dead and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = zhibing.name,
        }
      end
    end
    if player:getMark("@zhibing") > 5 and not table.contains(player:getTableMark(zhibing.name), 2) and
      not player:hasSkill("ty_ex__fencheng", true) then
      room:addTableMark(player, zhibing.name, 2)
      room:handleAddLoseSkills(player, "ty_ex__fencheng")
    end
    if player:getMark("@zhibing") > 8 and not table.contains(player:getTableMark(zhibing.name), 3) and
      not player:hasSkill("benghuai", true) then
      room:addTableMark(player, zhibing.name, 3)
      room:handleAddLoseSkills(player, "benghuai")
    end
    if #player:getTableMark(zhibing.name) == 3 then
      room:setPlayerMark(player, "@zhibing", 0)
    end
  end,
})
zhibing:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(zhibing.name, true) and target ~= player and
      target.kingdom == "qun" and data.card.color == Card.Black and
      table.find({1, 2, 3}, function (i)
        return not table.contains(player:getTableMark(zhibing.name), i)
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhibing", 1)
  end,
})

return zhibing
