local haizhu = fk.CreateSkill{
  name = "shengxiao_haizhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shengxiao_haizhu"] = "亥猪",
  [":shengxiao_haizhu"] = "锁定技，当其他角色的黑色牌因弃置而置入弃牌堆后，你获得这些牌；准备阶段，若你的手牌数为全场最多，你失去1点体力。",
}

local U = require "packages/utility/utility"

haizhu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(haizhu.name) then
      local ids = {}
      local room = player.room
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.moveReason == fk.ReasonDiscard and move.from and move.from ~= player then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                Fk:getCardById(info.cardId).color == Card.Black and
                table.contains(room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
      end
      ids = U.moveCardsHoldingAreaCheck(room, ids)
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonJustMove, haizhu.name, nil, true, player)
  end,
})
haizhu:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(haizhu.name) and player.phase == Player.Start and
      table.every(player.room.alive_players, function (p)
        return player:getHandcardNum() >= p:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, haizhu.name)
  end,
})

return haizhu
