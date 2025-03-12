local zonglue = fk.CreateSkill{
  name = "zonglue",
}

Fk:loadTranslationTable{
  ["zonglue"] = "纵掠",
  [":zonglue"] = "出牌阶段限一次，你可以将一张牌当【杀】使用。当你使用【杀】对目标角色造成伤害后，若实体牌不为【杀】或没有实体牌，"..
  "你可以获得其每个区域各一张牌。",

  ["#zonglue"] = "纵掠：你可以将一张牌当【杀】使用",
  ["#zonglue-invoke"] = "纵掠：是否获得 %dest 每个区域各一张牌？",

  ["$zonglue1"] = "",
  ["$zonglue2"] = "",
}

local U = require "packages/utility/utility"

zonglue:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#zonglue",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = zonglue.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(zonglue.name, Player.HistoryPhase) == 0
  end,
})
zonglue:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zonglue.name) and
      data.card and data.card.trueName == "slash" and player.room.logic:damageByCardEffect() and
      not data.to.dead and not data.to:isAllNude() and
      data.card:isVirtual() and (#data.card.subcards ~= 1 or Fk:getCardById(data.card.subcards[1]).trueName ~= "slash")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zonglue.name,
      prompt = "#zonglue-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = U.askforCardsChosenFromAreas(player, data.to, "hej", zonglue.name, nil, nil, false)
    room:obtainCard(player, cards, false, fk.ReasonPrey, player, zonglue.name)
  end,
})

return zonglue
