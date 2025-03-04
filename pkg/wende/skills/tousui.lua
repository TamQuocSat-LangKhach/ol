local tousui = fk.CreateSkill{
  name = "tousui",
}

Fk:loadTranslationTable{
  ["tousui"] = "透髓",
  [":tousui"] = "你可以将任意张牌置于牌堆底，视为使用一张需要等量张【闪】抵消的【杀】。",

  ["#tousui"] = "透髓：将任意张牌置于牌堆底，视为使用一张需要等量张【闪】抵消的【杀】！",

  ["$tousui1"] = "区区黄口孺帝，能有何作为？",
  ["$tousui2"] = "昔年沙场茹血，今欲饮帝血！",
}

tousui:addEffect("viewas", {
  pattern = "slash",
  anim_type = "offensive",
  prompt = "#tousui",
  card_filter = Util.TrueFunc,
  view_as = function(self, player, cards)
    if #cards < 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = tousui.name
    self.cost_data = cards
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    local cards = table.simpleClone(self.cost_data)
    use.extra_data = use.extra_data or {}
    use.extra_data.tousui = #cards
    if #cards > 1 then
      local result = room:askToGuanxing(player, {
        cards = cards,
        top_limit = { 0, 0 },
        skill_name = tousui.name,
        skip = true,
      })
      cards = result.bottom
    end
    room:moveCards({
      ids = cards,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = tousui.name,
      proposer = player,
      drawPilePosition = -1,
    })
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude()
  end,
})
tousui:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, tousui.name) and (data.extra_data or {}).tousui
  end,
  on_refresh = function(self, event, target, player, data)
    data.fixedResponseTimes = data.extra_data.tousui
    data.fixedAddTimesResponsors = data.fixedAddTimesResponsors or {}
    table.insertIfNeed(data.fixedAddTimesResponsors, data.to)
  end,
})

return tousui
