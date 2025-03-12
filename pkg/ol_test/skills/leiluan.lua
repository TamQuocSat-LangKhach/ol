local leiluan = fk.CreateSkill{
  name = "leiluan",
}

Fk:loadTranslationTable{
  ["leiluan"] = "累卵",
  [":leiluan"] = "每回合限一次，你可以将X张牌当一张你本轮未使用过的基本牌使用。每轮结束时，若你此轮至少使用过X张基本牌，你可以摸X张牌并视为"..
  "使用一张本轮进入弃牌堆的普通锦囊牌（X为你连续发动此技能的轮数，至少为1）。",

  ["#leiluan"] = "累卵：你可以将%arg张牌当基本牌使用",
  ["#leiluan-use"] = "累卵：你可以视为使用其中一张牌",

  ["$leiluan1"] = "",
  ["$leiluan2"] = "",
}

local U = require "packages/utility/utility"

leiluan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player)
    return "#leiluan:::"..math.max(player:getMark("leiluan_count"), 1)
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(leiluan.name, all_names, nil, player:getTableMark("leiluan-round"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected < math.max(Self:getMark("leiluan_count"), 1)
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= math.max(player:getMark("leiluan_count"), 1) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = leiluan.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryTurn)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedEffectTimes(self.name, Player.HistoryTurn) and
      #player:getViewAsCardNames(leiluan.name, Fk:getAllCardNames("b"), nil, player:getTableMark("leiluan-round")) > 0
  end,
})
leiluan:addEffect(fk.RoundEnd, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(leiluan.name) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 99, function(e)
        local use = e.data
        return use.from == player and use.card.type == Card.TypeBasic
      end, Player.HistoryRound) >= math.max(player:getMark("leiluan_count"), 1)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(player:getMark("leiluan_count") + 1, leiluan.name)
    if player.dead then return end
    local names = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card:isCommonTrick() then
              table.insertIfNeed(names, card.name)
            end
          end
        end
      end
    end, Player.HistoryRound)
    if #names == 0 then return end
    if player:getMark("leiluan_cards") == 0 then
      room:setPlayerMark(player, "leiluan_cards", U.getUniversalCards(room, "t"))
    end
    local other = table.filter(names, function (name)
      return not table.find(player:getTableMark("leiluan_cards"), function (id)
        return Fk:getCardById(id).name == name
      end)
    end)
    if #other > 0 then
      for _, name in ipairs(other) do
        local id = room:printCard(name).id
        room:addTableMark(player, "leiluan_cards", id)
      end
    end
    local cards = table.filter(player:getMark("leiluan_cards"), function (id)
      return table.contains(names, Fk:getCardById(id).name)
    end)
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = leiluan.name,
      prompt = "#leiluan-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
      },
      skip = true,
    })
    if use then
      use = {
        card = Fk:cloneCard(use.card.name),
        from = player,
        tos = use.tos,
      }
      use.card.skillName = leiluan.name
      room:useCard(use)
    end
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(leiluan.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    if player:usedSkillTimes(leiluan.name, Player.HistoryRound) > 0 then
      player.room:addPlayerMark(player, "leiluan_count", 1)
    else
      player.room:setPlayerMark(player, "leiluan_count", 0)
    end
  end,
})

leiluan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(leiluan.name, true) and data.card.type == Card.TypeBasic
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "leiluan-round", data.card.trueName)
  end,
})

leiluan:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player and use.card.type == Card.TypeBasic then
        table.insertIfNeed(names, use.card.trueName)
      end
    end, Player.HistoryRound)
    room:setPlayerMark(player, "leiluan-round", names)
  end
end)

return leiluan
