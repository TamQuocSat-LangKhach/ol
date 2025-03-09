local guanxu = fk.CreateSkill{
  name = "guanxu",
}

Fk:loadTranslationTable{
  ["guanxu"] = "观虚",
  [":guanxu"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以用其中一张牌交换牌堆顶的五张牌中的一张。"..
  "若如此做，你弃置其手牌中三张相同花色的牌。",

  ["#guanxu"] = "观虚：观看一名角色的手牌",
  ["#guanxu-exchange"] = "观虚：选择要交换的至多1张卡牌",
  ["#guanxu-discard"] = "观虚：选择三张花色相同的卡牌弃置",

  ["$guanxu1"] = "不识此阵者，必为所迷。",
  ["$guanxu2"] = "虚实相生，变化无穷。",
}

guanxu:addEffect("active", {
  anim_type = "control",
  prompt = "#guanxu",
  can_use = function(self, player)
    return player:usedSkillTimes(guanxu.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local result = room:askToPoxi(player, {
      poxi_type = "guanxu_exchange",
      data = {
        { "Top", room:getNCards(5) },
        { target.general, target:getCardIds("h") },
      },
      cancelable = true,
    })
    if #result ~= 2 then return end
    local cards1, cards2 = {result[1]}, {result[2]}
    if table.contains(target:getCardIds("h"), result[2]) then
      cards1, cards2 = {result[2]}, {result[1]}
    end
    room:swapCardsWithPile(target, cards1, cards2, guanxu.name, "Top", false, player)
    if player.dead or target.dead then return end

    local check = {{}, {}, {}, {}}
    for _, id in ipairs(target:getCardIds("h")) do
      local suit = Fk:getCardById(id).suit
      if suit < 5 then
        table.insert(check[suit], id)
      end
    end
    local ids = table.find(check, function (cids)
      return #cids > 2
    end)
    if ids == nil then return false end
    result = room:askToPoxi(player, {
      poxi_type = "guanxu_discard",
      data = {
        { target.general, target:getCardIds("h") },
      },
      cancelable = false,
    })
    if #result ~= 3 then
      result = table.slice(ids, 1, 4)
    end
    room:throwCard(result, guanxu.name, target, player)
  end,
})

Fk:addPoxiMethod{
  name = "guanxu_exchange",
  prompt = "#guanxu-exchange",
  card_filter = function(to_select, selected, data)
    if #selected < 2 then
      if #selected == 0 then
        return true
      else
        if table.contains(data[1][2], selected[1]) then
          return table.contains(data[2][2], to_select)
        else
          return table.contains(data[1][2], to_select)
        end
      end
    end
  end,
  feasible = function(selected)
    return #selected == 2
  end,
}
Fk:addPoxiMethod{
  name = "guanxu_discard",
  prompt = "#guanxu-discard",
  card_filter = function(to_select, selected, data)
    if #selected < 3 then
      if #selected == 0 then
        return Fk:getCardById(to_select).suit ~= Card.NoSuit
      else
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]))
      end
    end
  end,
  feasible = function(selected)
    return #selected == 3
  end,
}

return guanxu
