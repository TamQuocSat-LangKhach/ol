local lixian = fk.CreateSkill{
  name = "lixian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lixian"] = "理贤",
  [":lixian"] = "锁定技，每个结束阶段，你获得弃牌堆中所有本回合使用的目标包含你的锦囊牌。你以此法获得的牌仅可当作【杀】或【闪】使用。",

  ["#lixian"] = "理贤：将“理贤”牌当【杀】或【闪】使用",
  ["@@lixian-inhand"] = "理贤",
}

local U = require "packages/utility/utility"

lixian:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#lixian",
  interaction = function(self, player)
    local all_names = {"slash", "jink"}
    local names = player:getViewAsCardNames(lixian.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@lixian-inhand") > 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = lixian.name
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})
lixian:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lixian.name) and target.phase == Player.Finish then
      local cards = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.card.type == Card.TypeTrick and not use.card:isVirtual() and table.contains(player.room.discard_pile, use.card.id) and
          table.contains(use.tos or {}, player) then
          table.insertIfNeed(cards, use.card.id)
        end
      end, Player.HistoryTurn)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonJustMove, lixian.name, nil, true, player,
      "@@lixian-inhand")
  end,
})
lixian:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card:getMark("@@lixian-inhand") > 0
  end,
})

return lixian
