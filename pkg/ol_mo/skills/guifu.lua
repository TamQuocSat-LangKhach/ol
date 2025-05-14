local guifu = fk.CreateSkill{
  name = "guifu",
}

Fk:loadTranslationTable{
  ["guifu"] = "诡伏",
  [":guifu"] = "每轮开始时或你体力值变化后，你获得一张不计入手牌上限的【闪】。当技能或牌造成伤害后，你记录此技能或牌名。"..
  "你可以将因此技能获得的【闪】当记录的牌名使用（不计入次数限制，每回合每种牌名限一次）。",

  ["#guifu"] = "诡伏：将一张“诡伏”【闪】当一种记录的牌使用",
  ["@@guifu-inhand"] = "诡伏",

  ["$guifu1"] = "天命在我，何须急于一时。",
  ["$guifu2"] = "天数已定，如渊潜龙！",
}

local U = require "packages/utility/utility"

guifu:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#guifu",
  interaction = function (self, player)
    local all_names = player:getTableMark("guifu_card_record")
    local names = player:getViewAsCardNames(guifu.name, all_names, nil, player:getTableMark("guifu-turn"))
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@guifu-inhand") > 0
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = guifu.name
    card:addSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
    player.room:addTableMark(player, "guifu-turn", use.card.trueName)
  end,
  enabled_at_play = function (self, player)
    return #player:getViewAsCardNames(guifu.name, player:getTableMark("guifu_card_record"), nil, player:getTableMark("guifu-turn")) > 0
  end,
  enabled_at_response = function (self, player, response)
    return not response and
      #player:getViewAsCardNames(guifu.name, player:getTableMark("guifu_card_record"), nil, player:getTableMark("guifu-turn")) > 0
  end,
})

guifu:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, guifu.name)
  end,
})

guifu:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(guifu.name) and (data.card or (Fk.skills[data.skillName] and Fk.skills[data.skillName]:isPlayerSkill()))
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card then
      room:addTableMarkIfNeed(player, "guifu_card_record", data.card.trueName)
    elseif Fk.skill_skels[data.skillName] then
      if Fk.skills[data.skillName] then
        room:addTableMarkIfNeed(player, "guifu_skill_record", data.skillName)
      end
    end
  end,
})

local spec = {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(guifu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("jink", 1, "allPiles")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, guifu.name, nil, true, player, "@@guifu-inhand")
    end
  end,
}
guifu:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(guifu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})
guifu:addEffect(fk.Damaged, spec)
guifu:addEffect(fk.HpLost, spec)
guifu:addEffect(fk.HpRecover, spec)

guifu:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("@@guifu-inhand") > 0
  end,
})

guifu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "guifu_card_record", 0)
  room:setPlayerMark(player, "guifu_skill_record", 0)
  room:setPlayerMark(player, "guifu-turn", 0)
end)

return guifu