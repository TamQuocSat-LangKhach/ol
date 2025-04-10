local fujian = fk.CreateSkill{
  name = "fujian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fujian"] = "伏间",
  [":fujian"] = "锁定技，准备阶段或结束阶段，你随机观看手牌数不是全场最多的一名其他角色的手牌。",

  ["$fujian1"] = "兵者，诡道也。",
  ["$fujian2"] = "粮资军备，一览无遗。",
}

local U = require "packages/utility/utility"

fujian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fujian.name) and (player.phase == Player.Finish or player.phase == Player.Start) then
      local n = 0
      local players = table.filter(player.room.alive_players, function (p)
        if p ~= player and not p:isKongcheng() then
          n = math.max(n, p:getHandcardNum())
          return true
        end
      end)
      if #players == 0 then return false end
      local targets = table.filter(players, function (p)
        return p:getHandcardNum() ~= n
      end)
      if #targets == 0 then
        targets = players
      end
      event:setCostData(self, {tos = table.random(targets, 1)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    U.viewCards(player, to:getCardIds("h"), fujian.name, "$ViewCardsFrom:"..to.id)
  end,
})

return fujian
