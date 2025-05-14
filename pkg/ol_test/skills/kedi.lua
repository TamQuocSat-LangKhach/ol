local kedi = fk.CreateSkill{
  name = "kedi",
}

Fk:loadTranslationTable{
  ["kedi"] = "柯笛",
  [":kedi"] = "当你于出牌阶段使用的前两张手牌结算后，你可以令一名角色重铸一张牌，若重铸牌与你使用的牌花色相同，你可以使用此牌。",

  ["#kedi_nosuit-choose"] = "柯笛：令一名角色重铸一张牌",
  ["#kedi-choose"] = "柯笛：令一名角色重铸一张牌，若为%arg，你可以使用其重铸的牌",
  ["#kedi_nosuit-recast"] = "柯笛：请重铸一张牌",
  ["#kedi-recast"] = "柯笛：请重铸一张牌，若为%arg，%src 可以使用重铸的牌",
  ["#kedi-use"] = "柯笛：你可以使用这张牌",

  ["$kedi1"] = "",
  ["$kedi2"] = "",
}

kedi:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(kedi.name) and player.phase == Player.Play and data:isUsingHandcard(player) and
      table.find(player.room.alive_players, function (p)
        return not p:isNude()
      end) and player:usedSkillTimes(kedi.name, Player.HistoryPhase) < 2 then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function (e)
        local use = e.data
        if use.from == player then
          local moveEvents = e:searchEvents(GameEvent.MoveCards, 1, function(e2)
            return e2.parent and e2.parent.id == e.id
          end)
          if #moveEvents == 0 then return false end
          local subcheck = table.simpleClone(Card:getIdList(use.card))
          for _, move in ipairs(moveEvents[1].data) do
            if move.moveReason == fk.ReasonUse then
              for _, info in ipairs(move.moveInfo) do
                if table.removeOne(subcheck, info.cardId) and info.fromArea ~= Card.PlayerHand then
                  return false
                end
              end
            end
          end
          return #subcheck == 0
        end
      end, Player.HistoryPhase)
      return table.contains(use_events, player.room.logic:getCurrentEvent())
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = kedi.name,
      prompt = data.card.suit == Card.NoSuit and "#kedi_nosuit-choose" or "#kedi-choose:::"..data.card:getSuitString(true),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = kedi.name,
      prompt = data.card.suit == Card.NoSuit and "#kedi_nosuit-recast" or "#kedi-recast:"..player.id.."::"..data.card:getSuitString(true),
      cancelable = false,
    })
    room:recastCard(card, to, kedi.name)
    if player.dead then return end
    if Fk:getCardById(card[1]):compareSuitWith(data.card) and
      table.contains(room.discard_pile, card[1]) then
      room:askToUseRealCard(player, {
        pattern = card,
        skill_name = kedi.name,
        prompt = "#kedi-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = card,
        }
      })
    end
  end,
})

return kedi
