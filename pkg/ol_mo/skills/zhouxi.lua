local zhouxi = fk.CreateSkill{
  name = "zhouxi",
}

Fk:loadTranslationTable{
  ["zhouxi"] = "骤袭",
  [":zhouxi"] = "准备阶段，你从三个可造成伤害的技能中选择一个获得直到你下回合开始。受到你伤害的角色于本轮结束时视为对你使用一张【杀】。",

  ["#zhouxi-choice"] = "骤袭：获得一个技能直到下回合开始",

  ["$zhouxi1"] = "你降，不降，都得死！",
  ["$zhouxi2"] = "我就像这夜，终将吞噬一切！",
}

local zhouxi_skills = {
  "ol__sanyao", "daoshu", "ol__kuizhu", "jianhe", "zhefu", "shuzi", "quhu", "duwu",
  "ol__zhendu", "ol__xuehen", "tianjie", "lieshi", "ol_ex__juece", "ol_ex__leiji", "ol_ex__qiangxi", "ex__ganglie",
}

zhouxi.zhouxi_skills = zhouxi_skills

zhouxi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhouxi.name) and player.phase == Player.Start and
      table.find(zhouxi_skills, function (skill)
        return Fk.skill_skels[skill] and not player:hasSkill(skill, true)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skills = table.filter(zhouxi_skills, function (skill)
      return Fk.skill_skels[skill] and not player:hasSkill(skill, true)
    end)
    local choice = room:askToChoice(player, {
      choices = table.random(skills, 3),
      skill_name = zhouxi.name,
      prompt = "#zhouxi-choice",
      detailed = true,
    })
    room:addTableMark(player, zhouxi.name, choice)
    room:handleAddLoseSkills(player, choice)
  end,
})

zhouxi:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(zhouxi.name) ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local skills = player:getMark(zhouxi.name)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
    room:setPlayerMark(player, zhouxi.name, 0)
  end,
})

zhouxi:addEffect(fk.RoundEnd, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(zhouxi.name) then
      local tos = {}
      player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        if damage.from == player and damage.to ~= player and not damage.to.dead then
          table.insertIfNeed(tos, damage.to)
        end
      end, Player.HistoryRound)
      if #tos > 0 then
        player.room:sortByAction(tos)
        event:setCostData(self, {tos = tos})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if player.dead then return end
      if not p.dead then
        room:useVirtualCard("slash", nil, p, player, zhouxi.name, true)
      end
    end
  end
})

return zhouxi