local zhubei = fk.CreateSkill{
  name = "zhubei",
}

Fk:loadTranslationTable{
  ["zhubei"] = "逐北",
  [":zhubei"] = "出牌阶段各限一次，你可以选择一名其他角色，令其将至少X张牌当【杀】或【决斗】对你使用（X为所有角色本回合使用基本牌数+1）。"..
  "若你以此法受到伤害后，你可以获得伤害牌；若你未以此法受到伤害，你回复1点体力，然后可以与其交换手牌。",

  ["#zhubei"] = "逐北：令一名角色将至少%arg张牌当【杀】或【决斗】对你使用",
  ["#zhubei-use"] = "逐北：请将至少%arg张牌当【杀】或【决斗】对 %src 使用",
  ["#zhubei-swap"] = "逐北：是否与 %dest 交换手牌？",
  ["#zhubei_dalay-invoke"] = "逐北：是否获得造成伤害的牌？",

  ["$zhubei1"] = "虎踞青兖，欲补薄暮苍天！",
  ["$zhubei2"] = "欲止戈，必先执戈！",
}

zhubei:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#zhubei:::"..player:getMark("zhubei-phase") + 1
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("zhubei_slash-phase") == 0 or player:getMark("zhubei_duel-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if not table.contains(player:getTableMark("zhubei_names-phase"), name) then
        table.insert(choices, name)
      end
    end
    local use = room:askToUseVirtualCard(target, {
      name = choices,
      skill_name = zhubei.name,
      prompt = "#zhubei-use:"..player.id.."::"..(1 + player:getMark("zhubei-phase")),
      cancelable = false,
      extra_data = {
        exclusive_targets = {player.id},
      },
      card_filter = {
        n = { 1 + player:getMark("zhubei-phase"), 999 },
      },
      skip = true,
    })
    if use then
      room:addTableMark(player, "zhubei_names-phase", use.card.trueName)
      use.extra_data = use.extra_data or {}
      use.extra_data.zhubei = player.id
      room:useCard(use)
    end
    if not (use and use.damageDealt and use.damageDealt[player]) then
      if player:isWounded() and not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = zhubei.name,
        }
      end
      if not player.dead and not target.dead and not (player:isKongcheng() and target:isKongcheng()) and
        room:askToSkillInvoke(player, {
          skill_name = zhubei.name,
          prompt = "#zhubei-swap::"..target.id,
        }) then
        room:swapAllCards(player, {player, target}, zhubei.name)
      end
    end
  end,
})

zhubei:addEffect(fk.Damaged, {
  anim_type = "masochism",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, zhubei.name) and
      player.room:getCardArea(data.card) == Card.Processing then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return end
      local use = use_event.data
      return use.extra_data and use.extra_data.zhubei == player.id
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhubei.name,
      prompt = "#zhubei_dalay-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, zhubei.name, nil, true, player)
  end,
})

zhubei:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(zhubei.name, true) and data.card.type == Card.TypeBasic
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "zhubei-phase", 1)
  end,
})

zhubei:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      return e.data.card.type == Card.TypeBasic
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "zhubei-phase", n)
  end
end)

zhubei:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "zhubei_names-phase", 0)
end)

return zhubei
