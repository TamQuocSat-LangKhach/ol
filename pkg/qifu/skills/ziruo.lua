local ziruo = fk.CreateSkill{
  name = "ziruo",
  tags = { Skill.Switch, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ziruo"] = "自若",
  [":ziruo"] = "转换技，锁定技，当你使用，阳：最左侧的手牌时，你摸一张牌；阴：最右侧的手牌时，你摸一张牌。你以此法摸牌后本回合不能调整手牌。<br>" ..
  "<font color='gray'>注：未做禁止排序，点击“牌序”按钮并不会更改实际牌序，若不小心使用则点击武将上的“自若”标记查看真实牌序。</font>",

  ["@@ziruo_left-inhand"] = "最左",
  ["@@ziruo_right-inhand"] = "最右",
  ["@[ziruo_cards]"] = "自若",

  ["$ziruo1"] = "泰山虽崩于前，我亦风清云淡。",
  ["$ziruo2"] = "诸君勿忧，一切尽在掌握。",
}

ziruo:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  local handcards = player:getCardIds("h")
  for index, id in ipairs(handcards) do
    local card = Fk:getCardById(id)
    if index == 1 then
      room:setCardMark(card, "@@ziruo_left-inhand", 1)
    end
    if index == #handcards then
      room:setCardMark(card, "@@ziruo_right-inhand", 1)
    end

    if card:getMark("@@ziruo_left-inhand") ~= 0 and index > 1 then
      room:setCardMark(card, "@@ziruo_left-inhand", 0)
    end
    if card:getMark("@@ziruo_right-inhand") ~= 0 and index < #handcards then
      room:setCardMark(card, "@@ziruo_right-inhand", 0)
    end
  end

  if player:getMark("@[ziruo_cards]") == 0 then
    room:setPlayerMark(player, "@[ziruo_cards]", { value = player.id })
  end
end)

ziruo:addLoseEffect(function (self, player, is_death)
  local room = player.room
  local handcards = player:getCardIds("h")
  for _, id in ipairs(handcards) do
    local card = Fk:getCardById(id)
    if card:getMark("@@ziruo_left-inhand") ~= 0 then
      room:setCardMark(card, "@@ziruo_left-inhand", 0)
    end
    if card:getMark("@@ziruo_right-inhand") ~= 0 then
      room:setCardMark(card, "@@ziruo_right-inhand", 0)
    end
  end
  room:setPlayerMark(player, "@[ziruo_cards]", 0)
end)

Fk:addQmlMark{
  name = "ziruo_cards",
  qml_path = function(name, value, p)
    if Self == p then
      return "packages/ol/qml/ZiRuo"
    end
    return ""
  end,
  how_to_show = function(name, value, p)
    return " "
  end,
}
ziruo:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and
      data.extra_data and data.extra_data.ziruoSideCards then
      if player:getSwitchSkillState(ziruo.name) == fk.SwitchYang then
        return table.contains(Card:getIdList(data.card), data.extra_data.ziruoSideCards[1])
      else
        return table.contains(Card:getIdList(data.card), data.extra_data.ziruoSideCards[2])
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, ziruo.name)
    if not player.dead then
      player.room:setPlayerMark(player, MarkEnum.SortProhibited, 1)--turn
    end
  end,
})
ziruo:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(ziruo.name, true) and not player:isKongcheng()
  end,
  on_refresh = function (self, event, target, player, data)
    local handcards = player:getCardIds("h")
    data.extra_data = data.extra_data or {}
    data.extra_data.ziruoSideCards = { handcards[1], handcards[#handcards] }
  end,
})
ziruo:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(ziruo.name, true) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local handcards = player:getCardIds("h")
    for index, id in ipairs(handcards) do
      local card = Fk:getCardById(id)
      if index == 1 then
        room:setCardMark(card, "@@ziruo_left-inhand", 1)
      end
      if index == #handcards then
        room:setCardMark(card, "@@ziruo_right-inhand", 1)
      end

      if card:getMark("@@ziruo_left-inhand") ~= 0 and index > 1 then
        room:setCardMark(card, "@@ziruo_left-inhand", 0)
      end
      if card:getMark("@@ziruo_right-inhand") ~= 0 and index < #handcards then
        room:setCardMark(card, "@@ziruo_right-inhand", 0)
      end
    end

    if player:getMark("@[ziruo_cards]") == 0 then
      room:setPlayerMark(player, "@[ziruo_cards]", { value = player.id })
    end
  end,
})

return ziruo
