local fenji = fk.CreateSkill {
  name = "fenji",
}

Fk:loadTranslationTable {
  ["fenji"] = "奋激",
  [":fenji"] = "当一名角色A因另一名角色B的弃置或获得而失去手牌后，你可失去1点体力，令A摸两张牌。",

  ["#fenji-invoke"] = "奋激：你可以失去1点体力，令 %dest 摸两张牌",

  ["$fenji1"] = "百战之身，奋勇趋前！",
  ["$fenji2"] = "两肋插刀，愿赴此去！",
}

fenji:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fenji.name) and player.hp >= 1 then
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey then
          if move.from and move.proposer and move.from ~= move.proposer then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if not table.contains(targets, move.from) and (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) then
        if move.from and move.proposer and move.from ~= move.proposer then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(targets, move.from)
              break
            end
          end
        end
      end
    end
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(fenji.name) or player.hp < 1 then break end
      if not p.dead then
        self:doCost(event, p, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = fenji.name,
      prompt = "#fenji-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = target})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, fenji.name)
    if not target.dead then
      target:drawCards(2, fenji.name)
    end
  end,
})

return fenji
