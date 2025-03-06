local jieyan = fk.CreateSkill{
  name = "jieyan",
}

Fk:loadTranslationTable{
  ["jieyan"] = "节言",
  [":jieyan"] = "一名角色一次失去恰好两张牌后，你可以与其从牌堆两端各摸一张牌并展示，若花色不同，此技能本回合失效。",

  ["#jieyan-invoke"] = "节言：是否与 %dest 从牌堆两端各摸一张牌？",

  ["$jieyan1"] = "父高居殿陛，德当配其位。",
  ["$jieyan2"] = "君子善行，阿耶固君子，应有所不为。",
}

jieyan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jieyan.name) then
      local dat = {}
      for _, move in ipairs(data) do
        if move.from and not move.from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              dat[move.from] = (dat[move.from] or 0) + 1
            end
          end
        end
      end
      local targets = {}
      for p, n in pairs(dat) do
        if n == 2 then
          table.insert(targets, p)
        end
      end
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(event:getCostData(self).extra_data)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(jieyan.name) then return end
      if not p.dead then
        event:setCostData(self, {tos = {p}})
        self:doCost(event, nil, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if room:askToSkillInvoke(player, {
      skill_name = jieyan.name,
      prompt = "#jieyan-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local a = player.seat
    local b = to.seat
    local c = room.current.seat
    if a < c then
      a = a + c
    end
    if b < c then
      b = b + c
    end
    local playerA, playerB = to, player
    if a < b then
      playerA = player
      playerB = to
    end
    local cards = playerA:drawCards(1, jieyan.name)
    local suit = Card.NoSuit
    local invalidateSkill = false
    if #cards > 0 then
      suit = Fk:getCardById(cards[1]).suit
      if not playerA.dead and table.contains(playerA:getCardIds("h"), cards[1]) then
        playerA:showCards(cards[1])
      end
    end
    if not playerB.dead then
      cards = playerB:drawCards(1, jieyan.name, "bottom")
      if #cards > 0 then
        if suit == Card.NoSuit or suit ~= Fk:getCardById(cards[1]).suit then
          invalidateSkill = true
        end
        if not playerB.dead and table.contains(playerB:getCardIds("h"), cards[1]) then
          playerB:showCards(cards[1])
        end
      end
    end
    if player:hasSkill(jieyan.name, true) and invalidateSkill then
      room:invalidateSkill(player, jieyan.name, "-turn")
    end
  end,
})

return jieyan
