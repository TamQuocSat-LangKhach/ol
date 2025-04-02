local deru = fk.CreateSkill{
  name = "deru",
}

Fk:loadTranslationTable{
  ["deru"] = "德辱",
  [":deru"] = "出牌阶段限一次，你可以猜测一名其他角色手牌中的基本牌牌名，若你：有猜对，你回复1点体力；有猜错，随机获得其一张基本牌；全猜对，"..
  "你将手牌摸至体力值。",

  ["#deru"] = "德辱：选择一名角色，猜测其手牌中的基本牌牌名",
  ["#deru-choice"] = "德辱：选择你认为 %dest 手牌中有的基本牌",

  ["$deru1"] = "我闻唯德可以辱人，不闻以骂。",
  ["$deru2"] = "涣去他处，复骂将军，可乎？",
}

local U = require "packages/utility/utility"

deru:addEffect("active", {
  anim_type = "control",
  prompt = "#deru",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(deru.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local all_names = Fk:getAllCardNames("b", true)
    local choices = U.askForChooseCardNames(room, player, all_names, 0, #all_names, deru.name,
      "#deru-choice::"..target.id, all_names, false, false)
    local names = {}
    for _, id in ipairs(target:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        table.insertIfNeed(names, card.trueName)
      end
    end
    local n = 0
    for _, name in ipairs(all_names) do
      if (table.contains(choices, name) and table.contains(names, name)) or
        (not table.contains(choices, name) and not table.contains(names, name)) then
        n = n + 1
      end
    end
    if n > 0 and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = deru.name,
      }
      if player.dead then return end
    end
    if n < #all_names and not target.dead then
      local cards = table.filter(target:getCardIds("h"), function (id)
        return Fk:getCardById(id).type == Card.TypeBasic
      end)
      if #cards > 0 then
        room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonPrey, deru.name, nil, false, player)
      end
      if player.dead then return end
    end
    if n == #all_names and player:getHandcardNum() < player.hp then
      player:drawCards(player.hp - player:getHandcardNum(), deru.name)
    end
  end,
})

return deru
