local siqi = fk.CreateSkill{
  name = "siqi",
}

Fk:loadTranslationTable{
  ["siqi"] = "思泣",
  [":siqi"] = "当你的牌移至弃牌堆后，你将其中的红色牌置于牌堆底。"..
  "当你受到伤害后，你可以亮出牌堆底的X张牌（X为从牌堆底开始连续的红色牌数且至多为3），"..
  "依次可以使用其中的所有【桃】、【无中生有】和装备牌（可以对其他角色使用），然后摸等同于其他牌数的牌。",

  ["#siqi-use"] = "思泣：你可以依次使用亮出的牌（可以对其他角色使用）",

  ["$siqi1"] = "红泪落霜鬓，自此无处归乡。",
  ["$siqi2"] = "挥泪别古道，唯见瘦马曳西风。",
}

local U = require "packages/utility/utility"

siqi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(siqi.name) then return false end
    local room = player.room
    local logic = room.logic
    local move_event = logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
    if move_event == nil then return false end
    local subcards = {}
    local cards
    local p_event = move_event.parent
    if p_event ~= nil and (p_event.event == GameEvent.UseCard or p_event.event == GameEvent.RespondCard) then
      local p_data = p_event.data
      if p_data.from == player then
        cards = Card:getIdList(p_data.card)
        local moveEvents = p_event:searchEvents(GameEvent.MoveCards, 1, function(e)
          return e.parent and e.parent.id == p_event.id
        end)
        if #moveEvents > 0 then
          for _, move in ipairs(moveEvents[1].data) do
            if move.from == player and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResonpse) then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  if table.removeOne(cards, info.cardId) then
                    table.insert(subcards, info.cardId)
                  end
                end
              end
            end
          end
        end
      end
    end
    cards = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId, true).color == Card.Red then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        elseif move.from == nil and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResonpse) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and table.removeOne(subcards, info.cardId) and
            Fk:getCardById(info.cardId, true).color == Card.Red then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end
    cards = U.moveCardsHoldingAreaCheck(room, cards)
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:moveCards {
      ids = event:getCostData(self).cards,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = siqi.name,
      proposer = player,
      moveVisible = true,
      drawPilePosition = -1
    }
  end,
})
siqi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(siqi.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local dp_cards = room.draw_pile
    local x = #dp_cards
    if x == 0 then return false end
    local id
    local card
    local to_show = {}
    local cards = {}
    for i = 1, math.min(3, x), 1 do
      id = dp_cards[x+1-i]
      card = Fk:getCardById(id, true)
      if card.color == Card.Red then
        table.insert(to_show, id)
        if card.type == Card.TypeEquip or card.trueName == "peach" or card.trueName == "ex_nihilo" then
          table.insert(cards, id)
        end
      else
        break
      end
    end
    if #to_show == 0 then return false end
    room:turnOverCardsFromDrawPile(player, to_show, siqi.name)
    local to_use
    repeat
      to_use = table.filter(cards, function(cid)
        if room:getCardArea(cid) ~= Card.Processing then return false end
        card = Fk:getCardById(cid, true)
        return not (player:prohibitUse(card) or table.every(room.alive_players, function(p)
          return player:isProhibited(p, card) or not card.skill:modTargetFilter(player, p, {}, card, {bypass_times = true})
        end))
      end)
      if #to_use == 0 then break end
      room:setPlayerMark(player, "siqi-tmp", to_use)
      local _, dat = room:askToUseActiveSkill(player, {
        skill_name = "siqi_active",
        prompt = "#siqi-use",
        no_indicate = true,
      })
      room:setPlayerMark(player, "siqi-tmp", 0)
      if dat then
        room:useCard{
          card = Fk:getCardById(dat.cards[1], true),
          from = player,
          tos = #dat.targets > 0 and dat.targets or { player },
          extraUse = true,
        }
      else
        break
      end
    until player.dead
    if not player.dead then
      x = #to_show - #cards
      if x > 0 then
        room:drawCards(player, x, siqi.name)
      end
    end
    room:cleanProcessingArea(to_show, siqi.name)
  end,
})

return siqi
