local zhangzheng = fk.CreateSkill{
  name = "qin__zhangzheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__zhangzheng"] = "掌政",
  [":qin__zhangzheng"] = "锁定技，准备阶段，所有非秦势力角色依次选择：1.弃置一张手牌；2.失去1点体力。",

  ["#qin__zhangzheng-discard"] = "掌政：你须弃置一张手牌，否则失去1点体力",

  ["$qin__zhangzheng"] = "幼子年弱，吾代为掌政！",
}

zhangzheng:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhangzheng.name) and
      table.find(player.room.alive_players, function (p)
        return p.kingdom ~= "qin"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room:getAlivePlayers(), function (p)
      return p.kingdom ~= "qin"
    end)
    event:setCostData(self, {tos = targets})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.kingdom ~= "qin" and not p.dead then
        if p:isKongcheng() or
          #room:askToDiscard(p, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            skill_name = zhangzheng.name,
            prompt = "#qin__zhangzheng-discard",
            cancelable = true,
          }) == 0 then
          room:loseHp(p, 1, zhangzheng.name)
        end
      end
    end
  end,
})

return zhangzheng
