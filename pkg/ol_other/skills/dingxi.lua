local dingxi = fk.CreateSkill{
  name = "dingxi",
}

Fk:loadTranslationTable{
  ["dingxi"] = "定西",
  [":dingxi"] = "当你使用伤害牌结算完毕进入弃牌堆后，你可以对你的上家使用其中一张伤害牌（无次数限制），然后将之置于你的武将牌上。结束阶段，"..
  "你摸X张牌（X为“定西”牌数）。",

  ["#dingxi-use"] = "定西：你可以对 %dest 使用其中一张牌",

  ["$dingxi1"] = "今天，我曹操誓要踏平祁连山！",
  ["$dingxi2"] = "饮马瀚海、封狼居胥，大丈夫当如此！",
}

local U = require "packages/utility/utility"

dingxi:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  derived_piles = "dingxi",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(dingxi.name) then
      local room = player.room
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == nil and move.moveReason == fk.ReasonUse then
          local move_event = room.logic:getCurrentEvent()
          local use_event = move_event.parent
          if use_event ~= nil and use_event.event == GameEvent.UseCard then
            local use = use_event.data
            if use.from == player and use.card.is_damage_card then
              local card_ids = room:getSubcardsByRule(use.card)
              for _, info in ipairs(move.moveInfo) do
                local card = Fk:getCardById(info.cardId, true)
                if table.contains(card_ids, info.cardId) and card.is_damage_card and
                  table.contains(room.discard_pile, info.cardId) then
                  table.insertIfNeed(cards, info.cardId)
                end
              end
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(room, cards)
      cards = table.filter(cards, function (id)
        local card = Fk:getCardById(id)
        if player:getLastAlive() == player then
          return player:canUseTo(card, player)
        else
          return not player:isProhibited(player:getLastAlive(), card)
        end
      end)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = dingxi.name,
      prompt = "#dingxi-use::"..player:getLastAlive().id,
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
        must_targets = {player:getLastAlive().id},
      },
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
    if #use.tos == 0 then
      use.tos = {player:getLastAlive()}
    end
    use.extra_data = use.extra_data or {}
    use.extra_data.dingxi = player
    room:useCard(use)
  end,
})
dingxi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dingxi.name) and player.phase == Player.Finish and
      #player:getPile(dingxi.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(#player:getPile(dingxi.name), dingxi.name)
  end,
})
dingxi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.dingxi == player and
      not player.dead and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function (self, event, target, player, data)
    player:addToPile(dingxi.name, data.card, true, dingxi.name, player)
  end,
})

return dingxi
