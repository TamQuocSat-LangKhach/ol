local yidu = fk.CreateSkill{
  name = "yidu",
}

Fk:loadTranslationTable{
  ["yidu"] = "遗毒",
  [":yidu"] = "当你使用【杀】或伤害锦囊牌后，若有目标角色未受到此牌的伤害，你可以展示其至多三张手牌，若颜色均相同，你弃置这些牌。",

  ["#yidu-invoke"] = "遗毒：你可以展示 %dest 至多三张手牌，若颜色相同则全部弃置",

  ["$yidu1"] = "彼之砒霜，吾之蜜糖。",
  ["$yidu2"] = "巧动心思，以遗他人。",
}

yidu:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yidu.name) and data.card.is_damage_card and
      table.find(data.tos, function (p)
        return not (data.damageDealt and data.damageDealt[p]) and not p.dead and not p:isKongcheng()
      end)
  end,
  on_trigger = function (self, event, target, player, data)
    local targets = table.filter(data.tos, function (p)
      return not (data.damageDealt and data.damageDealt[p]) and not p.dead
    end)
    for _, p in ipairs(targets) do
      if not player:hasSkill(yidu.name) then return end
      if not p.dead and not p:isKongcheng() then
        event:setCostData(self, {tos = {p}})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if room:askToSkillInvoke(player, {
      skill_name = yidu.name,
      prompt = "#yidu-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = 3,
      flag = "h",
      skill_name = yidu.name,
    })
    local yes = table.every(cards, function (id)
      return Fk:getCardById(id):compareColorWith(Fk:getCardById(cards[1]))
    end)
    to:showCards(cards)
    if yes then
      cards = table.filter(cards, function (id)
        return table.contains(to:getCardIds("h"), id)
      end)
      if #cards > 0 then
        room:throwCard(cards, yidu.name, to, player)
      end
    end
  end,
})

return yidu
