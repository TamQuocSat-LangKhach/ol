local caiwang = fk.CreateSkill{
  name = "caiwang",
}

Fk:loadTranslationTable{
  ["caiwang"] = "才望",
  [":caiwang"] = "当你使用/打出牌响应其他角色使用的牌后，或其他角色使用/打出牌响应你使用的牌后，若两张牌颜色相同，你可以弃置其一张牌。<br>"..
  "你可以将最后一张手牌当【闪】使用或打出；将最后一张你装备区里的牌当【无懈可击】使用；将最后一张你判定区的牌当【杀】使用或打出。",

  ["#caiwang-discard"] = "才望：你可以弃置 %dest 一张牌",
  ["#caiwang-prey"] = "才望：你可以获得 %dest 一张牌",
  ["#caiwang-jink"] = "才望：你可以将最后一张手牌当【闪】使用或打出",
  ["#caiwang-nullification"] = "才望：你可以将最后一张装备当【无懈可击】使用",
  ["#caiwang-slash"] = "才望：你可以将最后一张判定区内的牌当【杀】使用或打出",
  ["#caiwang"] = "才望：你可以将区域内最后一张牌当需要的牌使用或打出",

  ["$caiwang1"] = "才气不俗，声望四海。",
  ["$caiwang2"] = "绥怀之称，监守邺城。",
}

local U = require "packages/utility/utility"

local function CaiwangPattern(player)
  local names = {}
  if player:getHandcardNum() == 1 and #player:getViewAsCardNames(caiwang.name, {"jink"}, player:getCardIds("h")) > 0 then
    table.insert(names, "jink")
  end
  if #player:getCardIds("e") == 1 and #player:getViewAsCardNames(caiwang.name, {"nullification"}, player:getCardIds("e")) > 0 then
    table.insert(names, "nullification")
  end
  if #player:getCardIds("j") == 1 and #player:getViewAsCardNames(caiwang.name, {"slash"}, player:getCardIds("j")) > 0 then
    table.insert(names, "slash")
  end
  return names
end

caiwang:addEffect("viewas", {
  anim_type = "control",
  pattern = "jink,nullification,slash",
  prompt = function(self, player)
    return "#caiwang-"..self.interaction.data
  end,
  expand_pile = function (self, player)
    if table.contains(CaiwangPattern(player), "slash") then
      return player:getCardIds("j")
    else
      return {}
    end
  end,
  interaction = function(self, player)
    return U.CardNameBox { choices = CaiwangPattern(player) }
  end,
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "jink" then
        return table.contains(player:getCardIds("h"), to_select)
      elseif self.interaction.data == "nullification" then
        return table.contains(player:getCardIds("e"), to_select)
      elseif self.interaction.data == "slash" then
        return table.contains(player:getCardIds("j"), to_select)
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = caiwang.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #player:getCardIds("j") == 1 and table.contains(CaiwangPattern(player), "slash")
  end,
  enabled_at_response = function(self, player, response)
    return #CaiwangPattern(player) > 0
  end,
})

local caiwang_spec = {
  on_cost = function(self, event, target, player, data)
    local prompt = "#caiwang-discard"
    local to
    if data.responseToEvent.from == player then
      to = target
    elseif target == player then
      to = data.responseToEvent.from
    end
    if table.contains(player:getTableMark("naxiang"), to.id) then
      prompt = "#caiwang-prey"
    end
    if player.room:askToSkillInvoke(player, {
      skill_name = caiwang.name,
      prompt = prompt.."::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}, choice = prompt})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = caiwang.name,
    })
    if event:getCostData(self).choice:startsWith("#caiwang-discard") then
      room:throwCard(card, "caiwang", to, player)
    else
      room:obtainCard(player, card, false, fk.ReasonPrey, player, caiwang.name)
    end
  end,
}

caiwang:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if
      player:hasSkill(caiwang.name) and
      data.responseToEvent and
      data.responseToEvent.card and
      data.responseToEvent.card:compareColorWith(data.card)
    then
      local to
      if data.responseToEvent.from == player then
        to = target
      elseif target == player then
        to = data.responseToEvent.from
      end
      return to and to ~= player and not to:isNude()
    end
  end,
  on_cost = caiwang_spec.on_cost,
  on_use = caiwang_spec.on_use,
})
caiwang:addEffect(fk.CardRespondFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(caiwang.name) and data.responseToEvent.card and data.responseToEvent.card:compareColorWith(data.card) then
      local to
      if data.responseToEvent.from == player then
        to = target
      elseif target == player then
        to = data.responseToEvent.from
      end
      return to and to ~= player and not to:isNude()
    end
  end,
  on_cost = caiwang_spec.on_cost,
  on_use = caiwang_spec.on_use,
})
return caiwang
