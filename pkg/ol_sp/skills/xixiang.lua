local xixiang = fk.CreateSkill{
  name = "xixiang",
}

Fk:loadTranslationTable{
  ["xixiang"] = "西向",
  [":xixiang"] = "出牌阶段各限一次，你可以将至少X张牌当【杀】或【决斗】对一名角色使用（无距离次数限制，X为所有角色本回合使用基本牌数+1）。"..
  "此牌结算后，若其体力值：大于你的手牌数，你摸一张牌；大于你的体力值，你回复1点体力，然后获得其一张牌。",

  ["#xixiang"] = "西向：将至少%arg张牌当【杀】或【决斗】使用",
  ["#xixiang-prey"] = "西向：获得 %dest 一张牌",

  ["$xixiang1"] = "挥剑断浮云，诸君共西向！",
  ["$xixiang2"] = "西望故都，何忍君父辱于匹夫之手！",
}

local U = require "packages/utility/utility"

xixiang:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      return e.data.card.type == Card.TypeBasic
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "xixiang-phase", n)
  end
end)

xixiang:addEffect("active", {
  anim_type = "offensive",
  prompt = function (self, player)
    return "#xixiang:::"..player:getMark("xixiang-phase") + 1
  end,
  min_card_num = function (self, player)
    return player:getMark("xixiang-phase") + 1
  end,
  target_num = 1,
  interaction = function(self, player)
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if player:getMark("xixiang_"..name.."-phase") == 0 then
        table.insert(choices, name)
      end
    end
    return U.CardNameBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:getMark("xixiang_slash-phase") == 0 or player:getMark("xixiang_duel-phase") == 0
  end,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = xixiang.name
    card:addSubcards(selected)
    return not player:prohibitUse(card)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards <= player:getMark("xixiang-phase") or #selected > 0 or to_select == player or
      self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = xixiang.name
    card:addSubcards(selected_cards)
    return card.skill:targetFilter(player, to_select, {}, {}, card, {bypass_distances = true, bypass_times = true})
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, "xixiang_"..self.interaction.data.."-phase", 1)
    room:useVirtualCard(self.interaction.data, effect.cards, player, target, xixiang.name, true)
    if player.dead then return end
    if target.hp > player:getHandcardNum() then
      player:drawCards(1, xixiang.name)
    end
    if player.dead or target.dead then return end
    if target.hp > player.hp then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = xixiang.name,
        }
      end
      if not player.dead and not target.dead and not target:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = xixiang.name,
          prompt = "#xixiang-prey::"..target.id,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, xixiang.name, nil, false, player)
      end
    end
  end,
})
xixiang:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(xixiang.name, true) and data.card.type == Card.TypeBasic
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "xixiang-phase", 1)
  end,
})

return xixiang
