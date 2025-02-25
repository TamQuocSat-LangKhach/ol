local this = fk.CreateSkill { name = "ol_ex__fenji", }

this:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) and player.hp >= 1 then
      for _, move in ipairs(data) do
        if (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) then
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
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(this.name) or player.hp < 1 then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = this.name, prompt = "#ol_ex__fenji-invoke::"..target.id})
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player.room:loseHp(player, 1, this.name)
    if not target.dead then
      target:drawCards(2, this.name)
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__fenji"] = "奋激",
  [":ol_ex__fenji"] = "当一名角色A因另一名角色B的弃置或获得而失去手牌后，你可失去1点体力，令A摸两张牌。",

  ["#ol_ex__fenji-invoke"] = "奋激：你可以失去1点体力，令 %dest 摸两张牌",
  
  ["$ol_ex__fenji1"] = "百战之身，奋勇趋前！",
  ["$ol_ex__fenji2"] = "两肋插刀，愿赴此去！",
}

return this
