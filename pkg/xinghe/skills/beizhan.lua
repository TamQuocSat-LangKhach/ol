local beizhan = fk.CreateSkill{
  name = "beizhan",
}

Fk:loadTranslationTable{
  ["beizhan"] = "备战",
  [":beizhan"] = "回合结束时，你可以指定一名角色：若其手牌数少于X，其将手牌补至X（X为其体力上限且最多为5）；"..
  "该角色回合开始时，若其手牌数为全场最多，则其本回合内不能使用牌指定其他角色为目标。",

  ["#beizhan-choose"] = "备战：指定一名角色将手牌补至上限，若其回合开始时手牌数为最多，使用牌不能指定其他角色为目标",
  ["@@beizhan-turn"] = "备战",

  ["$beizhan1"] = "十，则围之；五，则攻之！",
  ["$beizhan2"] = "今伐曹氏，譬如覆手之举。",
}

beizhan:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(beizhan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = beizhan.name,
      prompt = "#beizhan-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = math.min(to.maxHp, 5) - to:getHandcardNum()
    if n > 0 then
      to:drawCards(n, beizhan.name)
      if to.dead then return end
    end
    room:setPlayerMark(to, beizhan.name, 1)
  end,
})
beizhan:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target:getMark(beizhan.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, beizhan.name, 0)
    if table.every(room.alive_players, function(p)
      return player:getHandcardNum() >= p:getHandcardNum()
    end) then
      room:setPlayerMark(target, "@@beizhan-turn", 1)
    end
  end,
})
beizhan:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@beizhan-turn") > 0 and card and from ~= to
  end,
})

return beizhan
