local zhongfu = fk.CreateSkill{
  name = "qin__zhongfu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__zhongfu"] = "仲父",
  [":qin__zhongfu"] = "锁定技，准备阶段，你随机获得以下一项技能直到你下回合开始：〖奸雄〗、〖仁德〗、〖制衡〗。",

  ["$qin__zhongfu"] = "吾有一日，便护国一日安康！",
}

zhongfu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongfu.name) and player.phase == Player.Start and
      table.find({"ex__jianxiong", "ex__rende", "ex__zhiheng"}, function (s)
        return not player:hasSkill(s, true)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.filter({"ex__jianxiong", "ex__rende", "ex__zhiheng"}, function (s)
      return not player:hasSkill(s, true)
    end)
    local skill = table.random(skills)
    room:setPlayerMark(player, zhongfu.name, skill)
    room:handleAddLoseSkills(player, skill)
  end,
})
zhongfu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(zhongfu.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skill = player:getMark(zhongfu.name)
    room:setPlayerMark(player, zhongfu.name, 0)
    room:handleAddLoseSkills(player, "-"..skill)
  end,
})

return zhongfu
