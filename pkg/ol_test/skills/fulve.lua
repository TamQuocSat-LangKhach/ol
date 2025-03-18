local fulve = fk.CreateSkill{
  name = "fulve",
}

Fk:loadTranslationTable{
  ["fulve"] = "复掠",
  [":fulve"] = "当你使用【杀】或伤害锦囊牌指定唯一目标后，你可以选择本回合未执行过的一项：1.此牌造成伤害+1；2.获得其一张牌。"..
  "此牌结算完成后，若未造成伤害，目标角色可以对你使用一张【杀】并执行另一项。",

  ["#fulve-invoke"] = "复掠：你可以对 %dest 执行一项，若未造成伤害，其可以对你使用【杀】并执行另一项",
  ["fulve_damage"] = "伤害+1",
  ["fulve_prey"] = "获得其一张牌",
  ["#fulve-use"] = "复掠：你可以对 %src 使用一张【杀】且%arg",

  ["$fulve1"] = "",
  ["$fulve2"] = "",
}

fulve:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(fulve.name) and data.card.is_damage_card and
      #data.use.tos == 1 and not data.to.dead and #player:getTableMark("fulve-turn") < 2 then
      if #player:getTableMark("fulve-turn") == 1 then
        if table.contains(player:getTableMark("fulve-turn"), "fulve_prey") then
          return true
        else
          return data.to == player and #player:getCardIds("e") > 0 or not data.to:isNude()
        end
      else
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if not table.contains(player:getTableMark("fulve-turn"), "fulve_prey") and
      (data.to == player and #player:getCardIds("e") > 0 or not data.to:isNude()) then
      table.insert(choices, 1, "fulve_prey")
    end
    if not table.contains(player:getTableMark("fulve-turn"), "fulve_damage") then
      table.insert(choices, 1, "fulve_damage")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fulve.name,
      prompt = "#fulve-invoke::"..data.to.id,
      all_choices = {"fulve_damage", "fulve_prey", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:addTableMark(player, "fulve-turn", choice)
    data.extra_data = data.extra_data or {}
    data.extra_data.fulve = {
      from = player,
      to = data.to,
      choice = choice,
    }
    if choice == "fulve_damage" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = data.to == player and "e" or "he",
        skill_name = fulve.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, fulve.name, nil, false, player)
    end
  end,
})
fulve:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return not data.damageDealt and data.extra_data and data.extra_data.fulve and
      data.extra_data.fulve.from == player and not player.dead and not data.extra_data.fulve.to.dead and
      player ~= data.extra_data.fulve.to
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = data.extra_data.fulve.to
    local choice = data.extra_data.fulve.choice == "fulve_damage" and "fulve_prey" or "fulve_damage"
    local use = room:askToUseCard(to, {
      skill_name = fulve.name,
      pattern = "slash",
      prompt = "#fulve-use:"..player.id.."::"..choice,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        exclusive_targets = {player.id},
      }
    })
    if use then
      use.extraUse = true
      if choice == "fulve_damage" then
        use.additionalDamage = (use.additionalDamage or 0) + 1
        room:addTableMarkIfNeed(player, "fulve-turn", "fulve_damage")
      else
        use.extra_data = use.extra_data or {}
        use.extra_data.fulve_delay = {
          from = player,
          to = to,
        }
      end
      room:useCard(use)
    end
  end,
})
fulve:addEffect(fk.TargetSpecified, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.fulve_delay and
      data.extra_data.fulve_delay.to == player and data.extra_data.fulve_delay.from == data.to and
      not data.to:isNude() and not data.to.dead
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(data.to, "fulve-turn", "fulve_prey")
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = fulve.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, fulve.name, nil, false, player)
  end,
})

return fulve
