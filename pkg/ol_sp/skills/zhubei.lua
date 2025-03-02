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

local U = require "packages/utility/utility"

zhubei:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      return e.data.card.type == Card.TypeBasic
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "zhubei-phase", n)
  end
end)

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
    return #selected == 0 and to_select ~= player and
      (#to_select:getHandlyIds() + #to_select:getCardIds("e")) > player:getMark("zhubei-phase")
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if player:getMark("zhubei_"..name.."-phase") == 0 then
        table.insert(choices, name)
      end
    end
    room:setPlayerMark(target, "zhubei-tmp", {player:getMark("zhubei-phase"), choices})
    local success, dat = room:askToUseActiveSkill(target, {
      skill_name = "zhubei_active",
      prompt = "#zhubei-use:"..player.id,
      cancelable = false,
    })
    room:setPlayerMark(target, "zhubei-tmp", 0)
    if not (success and dat) then
      dat = {}
      dat.interaction = choices[1]
      local all_cards = table.simpleClone(target:getHandlyIds())
      table.insertTable(all_cards, table.simpleClone(target:getCardIds("e")))
      dat.cards = table.random(all_cards, player:getMark("zhubei-phase") + 1)
    end
    room:setPlayerMark(player, "zhubei_"..dat.interaction.."-phase", 1)
    local card = Fk:cloneCard(dat.interaction)
    card:addSubcards(dat.cards)
    card.skillName = zhubei.name
    local use = {
      from = target,
      tos = {player},
      card = card,
      extraUse = true,
      extra_data = {
        zhubei = player.id
      },
    }
    room:useCard(use)
    if not (use.damageDealt and use.damageDealt[player]) then
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
        U.swapHandCards(room, player, player, target, zhubei.name)
      end
    end
  end,
})
zhubei:addEffect(fk.Damaged, {
  anim_type = "masochism",
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

return zhubei
