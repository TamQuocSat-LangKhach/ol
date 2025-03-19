local qiaoli = fk.CreateSkill{
  name = "qiaoli",
}

Fk:loadTranslationTable{
  ["qiaoli"] = "巧力",
  [":qiaoli"] = "出牌阶段各限一次，1.你可以将一张武器牌当【决斗】使用，此牌对目标角色造成伤害后，你摸与之攻击范围等量张牌，然后可以分配"..
  "其中任意张牌；2.你可以将一张非武器装备牌当【决斗】使用且不能被响应，然后于结束阶段随机获得一张装备牌。",

  ["#qiaoli"] = "巧力：将一张装备牌当【决斗】使用",
  ["#qiaoli1"] = "巧力：将武器牌当【决斗】使用，造成伤害后摸此牌攻击范围张牌",
  ["#qiaoli2"] = "巧力：将非武器装备牌当【决斗】使用，不能被响应且结束阶段摸一张装备牌",
  ["#qiaoli-give"] = "巧力：你可以将这些牌任意分配给其他角色",

  ["$qiaoli1"] = "别跑，且吃我一斧！",
  ["$qiaoli2"] = "让我看看你的能耐。",
}

qiaoli:addEffect("viewas", {
  anim_type = "offensive",
  prompt = function (self, selected_cards)
    if #selected_cards == 0 then
      return "#qiaoli"
    elseif #selected_cards == 1 then
      if Fk:getCardById(selected_cards[1]).sub_type == Card.SubtypeWeapon then
        return "#qiaoli1"
      else
        return "#qiaoli2"
      end
    end
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip then
      if Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon then
        return player:getMark("qiaoli1-phase") == 0
      else
        return player:getMark("qiaoli2-phase") == 0
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = qiaoli.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function (self, player, use)
    local room = player.room
    ---@type Weapon
    local card = Fk:getCardById(use.card.subcards[1])
    if card.sub_type == Card.SubtypeWeapon then
      room:setPlayerMark(player, "qiaoli1-phase", 1)
      use.extra_data = use.extra_data or {}
      use.extra_data.qiaoli = {player, use.tos[1], card:getAttackRange(player)}
    else
      room:setPlayerMark(player, "qiaoli1-phase", 2)
      room:addPlayerMark(player, "qiaoli2-turn")
      use.disresponsiveList = table.simpleClone(room.alive_players)
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("qiaoli1-phase") == 0 or player:getMark("qiaoli2-phase") == 0
  end,
})
qiaoli:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and not player.dead and data.card and table.contains(data.card.skillNames, qiaoli.name) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        if use.extra_data and use.extra_data.qiaoli and
          use.extra_data.qiaoli[1] == player and use.extra_data.qiaoli[2] == data.to then
          event:setCostData(self, {choice = use.extra_data.qiaoli[3]})
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(event:getCostData(self).choice, qiaoli.name)
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 or player.dead then return end
    room:askToYiji(player, {
      min_num = 0,
      max_num = #cards,
      skill_name = qiaoli.name,
      targets = room:getOtherPlayers(player, false),
      cards = cards,
      prompt = "#qiaoli-give",
    })
  end,
})
qiaoli:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
      player:getMark("qiaoli2-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|equip", player:getMark("qiaoli2-turn"))
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, qiaoli.name, nil, false, player)
    end
  end,
})

return qiaoli
