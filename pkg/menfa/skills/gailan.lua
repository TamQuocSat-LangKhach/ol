local gailan = fk.CreateSkill {
  name = "gailan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gailan"] = "该览",
  [":gailan"] = "锁定技，游戏开始时，你将四张<a href=':armillary_sphere'>【浑天仪】</a>洗入牌堆。回合开始时，"..
  "你将牌堆或弃牌堆中随机一张<a href=':armillary_sphere'>【浑天仪】</a>置入装备区。",

  ["$gailan1"] = "",
  ["$gailan2"] = "",
}

local U = require "packages/utility/utility"

gailan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gailan.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = "armillary_sphere"
    local cards = {
      {name, Card.Diamond, 1},
      {name, Card.Diamond, 3},
      {name, Card.Diamond, 10},
      {name, Card.Diamond, 12},
    }
    for _, id in ipairs(U.prepareDeriveCards(room, cards, gailan.name)) do
      if room:getCardArea(id) == Card.Void then
        table.removeOne(room.void, id)
        table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
        room:setCardArea(id, Card.DrawPile, nil)
      end
    end
    room:syncDrawPile()
    room:doBroadcastNotify("UpdateDrawPile", tostring(#room.draw_pile))
  end,
})

gailan:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gailan.name) and
      table.find(table.connect(player.room.draw_pile, player.room.discard_pile), function (id)
        return Fk:getCardById(id).name == "armillary_sphere" and player:canMoveCardIntoEquip(id, false)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
      return Fk:getCardById(id).name == "armillary_sphere" and player:canMoveCardIntoEquip(id, false)
    end)
    room:moveCardIntoEquip(player, table.random(cards), gailan.name, false, player)
  end,
})

return gailan
