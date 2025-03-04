local caozhao = fk.CreateSkill{
  name = "caozhaoh",
}

Fk:loadTranslationTable{
  ["caozhaoh"] = "草诏",
  [":caozhaoh"] = "出牌阶段限一次，你可展示一张手牌并声明一种未以此法声明过的基本牌或普通锦囊牌，令一名体力值不大于你的其他角色选择一项："..
  "令此牌视为你声明的牌，或其失去1点体力。然后若此牌声明成功，你可以将之交给一名其他角色。",

  ["#caozhaoh"] = "草诏：选择要声明的牌，然后选择展示的手牌和目标角色",
  ["#caozhaoh-log"] = "%from 声明了 %arg",
  ["#caozhaoh-choice"] = "草诏：允许 %src 将%arg视为【%arg2】，或点“取消”你失去1点体力",
  ["#caozhaoh-choose"] = "草诏：你可以将这张牌交给一名角色，点“取消”自己保留",
  ["@@caozhaoh-inhand"] = "草诏",

  ["$caozhaoh1"] = "草诏所宣，密勿从事。",
  ["$caozhaoh2"] = "惩恶扬功，四方之纲。",
}

local U = require "packages/utility/utility"

caozhao:addEffect("active", {
  anim_type = "control",
  prompt = "#caozhaoh",
  card_num = 1,
  target_num = 1,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = table.filter(all_names, function (name)
      return not table.contains(player:getTableMark(caozhao.name), Fk:cloneCard(name).trueName)
    end)
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(caozhao.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select.hp <= player.hp
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:sendLog{
      type = "#caozhaoh-log",
      from = player.id,
      arg = self.interaction.data,
      toast = true,
    }
    room:addTableMark(player, caozhao.name, Fk:cloneCard(self.interaction.data).trueName)
    player:showCards(effect.cards)
    if player.dead or not table.contains(player:getCardIds("h"), effect.cards[1]) then return end
    local id = effect.cards[1]
    local choice = room:askToSkillInvoke(target, {
      skill_name = caozhao.name,
      prompt = "#caozhaoh-choice:"..player.id.."::"..Fk:getCardById(id, true):toLogString()..":"..self.interaction.data,
    })
    if choice then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = caozhao.name,
        prompt = "#caozhaoh-choose",
        cancelable = true,
      })
      room:setCardMark(Fk:getCardById(id), "@@caozhaoh-inhand", self.interaction.data)
      if #to > 0 and to[1] ~= player then
        room:moveCardTo(effect.cards, Card.PlayerHand, to[1], fk.ReasonGive, caozhao.name, nil, true, player,
          {"@@caozhaoh-inhand", self.interaction.data})
      end
    else
      room:loseHp(target, 1, caozhao.name)
    end
  end,
})
caozhao:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@caozhaoh-inhand") ~= 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(card:getMark("@@caozhaoh-inhand"), card.suit, card.number)
  end,
})

return caozhao
