local jiaoyu = fk.CreateSkill{
  name = "jiaoyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaoyu"] = "椒遇",
  [":jiaoyu"] = "锁定技，每轮开始时，你判定X次（X为你空置装备栏数），然后声明一种颜色并获得弃牌堆里此颜色的判定牌。"..
  "你的下个回合的结束阶段结束时，你获得一个额外出牌阶段，此阶段内其他角色不能使用与你装备区内牌颜色相同的牌直到有角色受到伤害。",

  ["@jiaoyu-round"] = "椒遇",
  ["#jiaoyu-choice"] = "椒遇：选择获得一种颜色的判定牌",

  ["$jiaoyu1"] = "",
  ["$jiaoyu2"] = "",
}

jiaoyu:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiaoyu.name) and
      table.find({3, 4, 5, 6, 7}, function (sub_type)
        return player:hasEmptyEquipSlot(sub_type)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiaoyu_extra_phase-round", 1)
    local n = #table.filter({3, 4, 5, 6, 7}, function (sub_type)
      return player:hasEmptyEquipSlot(sub_type)
    end)
    local cards = {}
    for _ = 1, n, 1 do
      local judge = {
        who = player,
        reason = jiaoyu.name,
        pattern = ".",
      }
      room:judge(judge)
      if judge.card then
        table.insert(cards, judge.card.id)
      end
    end
    if not player.dead then
      local color = room:askToChoice(player, {
        choices = {"red", "black"},
        skill_name = jiaoyu.name,
        prompt = "#jiaoyu-choice",
      })
      room:setPlayerMark(player, "@jiaoyu-round", color)
      local get = table.filter(cards, function (id)
        return Fk:getCardById(id):getColorString() == color and table.contains(room.discard_pile, id)
      end)
      if #get > 0 then
        room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, jiaoyu.name, nil, true, player)
      end
    end
  end,
})
jiaoyu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:getMark("jiaoyu_extra_phase-round") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiaoyu_extra_phase-round", 0)
    room:setPlayerMark(player, "jiaoyu_prohibit-turn", 1)
    player:gainAnExtraPhase(Player.Play, jiaoyu.name)
  end,
})
jiaoyu:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("jiaoyu_prohibit-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiaoyu_prohibit-turn", 0)
    room:setPlayerMark(player, "jiaoyu_prohibit-phase", 1)
  end,
})
jiaoyu:addEffect(fk.Damaged, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("jiaoyu_prohibit-phase") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "jiaoyu_prohibit-phase", 0)
  end,
})
jiaoyu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local src = table.find(Fk:currentRoom().alive_players, function (p)
      return p:getMark("jiaoyu_prohibit-phase") > 0
    end)
    if src and src ~= player then
      return table.find(src:getCardIds("e"), function (id)
        return card:compareColorWith(Fk:getCardById(id))
      end)
    end
  end,
})

return jiaoyu
