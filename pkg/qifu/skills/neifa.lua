local neifa = fk.CreateSkill{
  name = "neifa",
}

Fk:loadTranslationTable{
  ["neifa"] = "内伐",
  [":neifa"] = "出牌阶段开始时，你可以摸两张牌或获得场上一张牌，然后弃置一张牌。若弃置的牌：是基本牌，你本回合不能使用非基本牌，"..
  "本阶段使用【杀】次数上限+X，目标上限+1；不是基本牌，你本回合不能使用基本牌，使用普通锦囊牌的目标+1或-1，前两次使用装备牌时摸X张牌"..
  "（X为发动技能时手牌中因本技能不能使用的牌且至多为5）。",

  ["neifa_prey"] = "获得场上一张牌",
  ["#neifa-choose"] = "内伐：选择一名角色，获得其场上一张牌",
  ["#neifa-discard"] = "内伐：请弃置一张牌：若弃基本牌，你不能使用非基本牌；若弃非基本牌，你不能使用基本牌",
  ["@neifa-turn"] = "内伐",
  ["non_basic"] = "非基本牌",
  ["non_basic_char"] = "非基",
  ["#neifa_trigger-choose"] = "内伐：你可以为%arg增加/减少1个目标",

  ["$neifa1"] = "自相恩残，相煎何急。",
  ["$neifa2"] = "同室内伐，贻笑外人。",
}

neifa:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(neifa.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    local targets = table.filter(room.alive_players, function(p)
      return #p:getCardIds("ej") > 0
    end)
    if #targets > 0 then
      table.insert(choices, "neifa_prey")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = neifa.name,
    })
    if choice == "draw2" then
      player:drawCards(2, neifa.name)
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = neifa.name,
        prompt = "#neifa-choose",
        cancelable = false,
      })[1]
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "ej",
        skill_name = neifa.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, neifa.name, nil, true, player)
    end
    if player.dead or player:isNude() then return end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = neifa.name,
      prompt = "#neifa-discard",
      cancelable = false,
      skip = true,
    })
    local type = Fk:getCardById(card[1]).type
    room:throwCard(card, neifa.name, player, player)
    if player.dead then return end
    local list = {}
    if type == Card.TypeBasic then
      local cards = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).type ~= Card.TypeBasic
      end)
      list = {"basic_char", math.min(#cards, 5)}
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", math.min(#cards, 5))
    else
      local cards = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).type == Card.TypeBasic
      end)
      list = {"non_basic_char", math.min(#cards, 5)}
    end
    local mark = player:getTableMark("@neifa-turn")
    -- 未测试，暂定同类覆盖
    if mark[1] == list[1] then
      mark[2] = list[2]
    else
      table.insertTable(mark, list)
    end
    room:setPlayerMark(player, "@neifa-turn", mark)
  end,
})
neifa:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local mark = player:getTableMark("@neifa-turn")
      if #mark == 0 then return false end
      if data.card:isCommonTrick() and table.contains(mark, "non_basic_char") then
        local targets = data:getExtraTargets()
        if #data.tos > 1 then
          table.insertTable(targets, data.tos)
        end
        if #targets > 0 then
          event:setCostData(self, {tos = targets})
          return true
        end
      elseif data.card.trueName == "slash" and table.contains(mark, "basic_char") then
        local targets = data:getExtraTargets()
        if #targets > 0 then
          event:setCostData(self, {tos = targets})
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = event:getCostData(self).tos,
      skill_name = neifa.name,
      prompt = "#neifa_trigger-choose:::"..data.card:toLogString(),
      cancelable = true,
      --target_tip_name = "addandcanceltarget_tip",
      --extra_data = data.tos,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if table.contains(data.tos, to) then
      data:removeTarget(to)
      room:sendLog{
        type = "#RemoveTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = neifa.name,
        arg2 = data.card:toLogString(),
      }
    else
      data:addTarget(to)
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = neifa.name,
        arg2 = data.card:toLogString(),
      }
    end
  end,
})
neifa:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and target == player and data.card.type == Card.TypeEquip and
      player:usedEffectTimes(self.name, Player.HistoryTurn) < 2 then
      local mark = player:getTableMark("@neifa-turn")
      local index = table.indexOf(mark, "non_basic_char")
      return index > 0 and mark[index + 1] > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local mark = player:getTableMark("@neifa-turn")
    local index = table.indexOf(mark, "non_basic_char")
    if index > 0 and mark[index + 1] > 0 then
      player:drawCards(mark[index + 1], neifa.name)
    end
  end,
})
neifa:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local mark = player:getTableMark("@neifa-turn")
    if card.type == Card.TypeBasic then
      return table.contains(mark, "non_basic_char")
    else
      return table.contains(mark, "basic_char")
    end
  end,
})

return neifa
