local kanpo = fk.CreateSkill{
  name = "kanpod",
}

Fk:loadTranslationTable{
  ["kanpod"] = "勘破",
  [":kanpod"] = "当你使用【杀】对目标角色造成伤害后，你可以观看其手牌并获得其中一张与此【杀】花色相同的牌。每回合限一次，你可以将一张手牌"..
  "当【杀】使用。",

  ["#kanpod"] = "勘破：你可以将一张手牌当【杀】使用",
  ["#kanpod-invoke"] = "勘破：你可以观看 %dest 的手牌并获得其中一张%arg牌",
  ["#kanpod-prey"] = "勘破：选择一张牌获得",

  ["$kanpod1"] = "兵锋相交，便可知其玄机。",
  ["$kanpod2"] = "先发一军，以探敌营虚实。",
}

kanpo:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#kanpod",
  pattern = "slash",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = kanpo.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
})
kanpo:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kanpo.name) and
      data.card and data.card.trueName == "slash" and player.room.logic:damageByCardEffect() and
      not data.to.dead and not data.to:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = kanpo.name,
      prompt = "#kanpod-invoke::"..data.to.id..":"..data.card:getSuitString(true),
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askToPoxi(player, {
      poxi_type = kanpo.name,
      data = {
        { data.to.general, data.to:getCardIds("h") },
      },
      extra_data = {
        suit = data.card.suit,
      },
      cancelable = true,
    })
    if #result > 0 then
      room:obtainCard(player, result, true, fk.ReasonPrey, player, kanpo.name)
    end
  end,
})
Fk:addPoxiMethod{
  name = "kanpod",
  prompt = "#kanpod-prey",
  card_filter = function(to_select, selected, data, extra_data)
    return #selected == 0 and Fk:getCardById(to_select).suit == extra_data.suit
  end,
  feasible = Util.TrueFunc,
}

return kanpo
