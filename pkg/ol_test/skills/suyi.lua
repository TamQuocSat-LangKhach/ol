local suyi = fk.CreateSkill{
  name = "suyi",
}

Fk:loadTranslationTable{
  ["suyi"] = "肃衣",
  [":suyi"] = "出牌阶段限一次，你可以令一名其他角色随机使用牌堆中的一张装备牌，然后视为对其使用一张【杀】。",

  ["#suyi"] = "肃衣：令一名角色使用随机装备，然后视为对其使用【杀】",
}

suyi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#suyi",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(suyi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = table.filter(room.draw_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and target:canUseTo(card, target)
    end)
    if #cards > 0 then
      room:useCard{
        from = target,
        tos = {target},
        card = Fk:getCardById(table.random(cards)),
      }
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, suyi.name, true)
      end
    end
  end,
})

return suyi