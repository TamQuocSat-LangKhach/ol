local xufa = fk.CreateSkill{
  name = "xufa",
}

Fk:loadTranslationTable{
  ["xufa"] = "蓄发",
  [":xufa"] = "出牌阶段各限一次，你可以：1.将至少半数手牌置于你的武将牌上，称为“蓄发”，然后你可将一张牌当“蓄发”中的任意普通锦囊牌使用；" ..
  "2.移去至少半数“蓄发”牌，然后你可将一张牌当移去牌中的任意普通锦囊牌使用。",

  ["xufa_put"] = "置入蓄发",
  ["xufa_remove"] = "移去蓄发",
  ["xufa_viewAs"] = "蓄发",
  ["#xufa-use"] = "蓄发：你可以将一张牌当其中一张普通锦囊牌使用",
  ["#xufa_put"] = "将至少%arg张手牌置入“蓄发”，然后可将一张牌当“蓄发”中普通锦囊牌使用",
  ["#xufa_remove"] = "移去至少%arg张“蓄发”，然后可将一张牌当移去牌中普通锦囊牌使用",

  ["$xufa1"] = "常言道，积善之家必有余庆。",
  ["$xufa2"] = "蓄势待发，一鸣惊天下。",
}

xufa:addEffect("active", {
  anim_type = "offensive",
  target_num = 0,
  expand_pile = xufa.name,
  prompt = function (self, player)
    local choice = self.interaction.data
    if choice == "xufa_put" then
      return "#xufa_put:::"..math.max(player:getHandcardNum() // 2, 1)
    elseif choice == "xufa_remove" then
      return "#xufa_remove:::"..math.max(#player:getPile(xufa.name) // 2, 1)
    end
    return " "
  end,
  min_card_num = function(self, player)
    if self.interaction.data == "xufa_put" then
      return math.max(player:getHandcardNum() // 2, 1)
    end
    return math.max(#player:getPile(xufa.name) // 2, 1)
  end,
  interaction = function(self, player)
    local all_choices = { "xufa_put", "xufa_remove" }
    local choices = table.filter(all_choices, function(choice)
      return not table.contains(player:getTableMark("xufa-phase"), choice)
    end)
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  can_use = function(self, player)
    return #player:getTableMark("xufa-phase") < 2
  end,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == "xufa_put" then
      return table.contains(player:getCardIds("h"), to_select)
    else
      return table.contains(player:getPile(xufa.name), to_select)
    end
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "xufa-phase", self.interaction.data)

    local cardsToSearch = effect.cards
    if self.interaction.data == "xufa_put" then
      player:addToPile(xufa.name, effect.cards, true, xufa.name, player)
      cardsToSearch = player:getPile(xufa.name)
    else
      room:moveCardTo(effect.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, xufa.name, xufa.name, true, player)
    end
    if player.dead or (#player:getHandlyIds() == 0 and player:isNude()) then return end

    local tricks = {}
    for _, id in ipairs(cardsToSearch) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not table.contains(tricks, card.name) then
        local trick = Fk:cloneCard(card.name)
        if player:canUse(trick) then
          table.insert(tricks, card.name)
        end
      end
    end

    if #tricks > 0 then
      room:setPlayerMark(player, "xufa_tricks", tricks)
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "xufa_viewas",
        prompt = "#xufa-use",
        no_indicate = true,
      })
      room:setPlayerMark(player, "xufa_tricks", 0)

      if success and dat then
        local card = Fk:cloneCard(dat.interaction)
        card:addSubcards(dat.cards)
        card.skillName = xufa.name
        room:sortByAction(dat.targets)
        room:useCard{
          from = player,
          tos = dat.targets,
          card = card,
          extraUse = true,
        }
      end
    end
  end,
})

return xufa
