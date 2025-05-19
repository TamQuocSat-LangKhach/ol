local lucun = fk.CreateSkill{
  name = "lucun",
}

Fk:loadTranslationTable{
  ["lucun"] = "赂存",
  [":lucun"] = "每回合限一次，你可以视为使用一张你本轮未以此法使用过的基本牌或普通锦囊牌，"..
    "然后当前回合角色将一张手牌置于你的武将牌上，称为“赂”。"..
    "若如此做，当前回合结束时，你移去一张“赂”，然后摸一张牌，若你本回合以此法使用的牌与移去的“赂”牌名相同，你多摸一张牌。",

  ["#lucun"] = "赂存：视为使用或打出一张基本牌或普通锦囊牌，然后令当前回合角色放置一张手牌",
  ["#lucun-push"] = "赂存：将一张手牌放置为%src的“赂”",

  ["olmou__zhangrang_lu"] = "赂",

  ["$lucun1"] = "",
  ["$lucun2"] = "",
}

local U = require "packages/utility/utility"

lucun:addEffect("viewas", {
  pattern = ".",
  prompt = "#lucun",
  derived_piles = "olmou__zhangrang_lu",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(lucun.name, all_names, {}, player:getTableMark("lucun-round"))
    return U.CardNameBox { choices = names, all_choices = all_names, default_choice = "lucun" }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if Fk.all_card_types[self.interaction.data] == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = lucun.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:setPlayerMark(player, "lucun-turn", use.card.trueName)
    room:addTableMark(player, "lucun-round", use.card.trueName)
  end,
  after_use = function(self, player)
    if player.dead then return end
    local room = player.room
    local to = room.current
    if to == nil or to.dead or to:isKongcheng() then return end
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = lucun.name,
      cancelable = false,
      prompt = "#lucun-push:" .. player.id,
    })
    player:addToPile("olmou__zhangrang_lu", card, true, lucun.name, to)
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(self.name) == 0 and Fk:currentRoom():getCurrent()
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedEffectTimes(self.name) == 0 and Fk:currentRoom():getCurrent() and
      #player:getViewAsCardNames(lucun.name, Fk:getAllCardNames("bt"), nil, player:getTableMark("lucun-round")) > 0
  end,
})

lucun:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lucun.name) and player:getMark("lucun-turn") ~= 0 and #player:getPile("olmou__zhangrang_lu") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("olmou__zhangrang_lu")
    if #cards == 0 then return false end
    local id
    if #cards > 1 then
      id = room:askToChooseCard(player, {
        target = player,
        flag = {
          card_data = {
            { "olmou__zhangrang_lu", cards }
          }
        },
        skill_name = lucun.name
      })
    else
      id = cards[1]
    end
    local x = player:getMark("lucun-turn") == Fk:getCardById(id, true).trueName and 2 or 1
    room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, lucun.name, nil, true, player)
    if not player.dead then
      room:drawCards(player, x, lucun.name)
    end
  end,
})

lucun:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "lucun-turn", 0)
  room:setPlayerMark(player, "lucun-round", 0)
end)

return lucun
