local huamu = fk.CreateSkill{
  name = "huamu",
}

Fk:loadTranslationTable{
  ["huamu"] = "化木",
  [":huamu"] = "当你使用与本回合上一张使用的牌颜色不同的手牌后，你可以将之置于你的武将牌上，黑色牌称为「灵杉」，红色牌称为「玉树」。",

  ["huamu_lingshan"] = "灵杉",
  ["huamu_yushu"] = "玉树",

  ["$huamu1"] = "左杉右树，可共余生。",
  ["$huamu2"] = "夫君，当与妾共越此人间之阶！",
  ["$huamu3"] = "四月寻春花更香。",
  ["$huamu4"] = "一树樱桃带雨红。",
  ["$huamu5"] = "山重水复，心有灵犀。",
  ["$huamu6"] = "灵之来兮如云。",
}

huamu:addEffect(fk.CardUseFinished, {
  mute = true,
  derived_piles = {"huamu_yushu", "huamu_lingshan"},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(huamu.name) or not data:IsUsingHandcard(player) then return end
    local room = player.room
    local card_ids = Card:getIdList(data.card)
    if #card_ids == 0 then return end
    if data.card.type == Card.TypeEquip then
      if not table.every(card_ids, function (id)
        return table.contains(player:getCardIds("e"), id)
      end) then return end
    else
      if not table.every(card_ids, function (id)
        return room:getCardArea(id) == Card.Processing
      end) then return end
    end
    local yes = false
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      if e.id < room.logic:getCurrentEvent().id then
        yes = e.data.card:compareColorWith(data.card, true)
        return true
      end
    end, nil, Player.HistoryTurn)
    return yes
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = Card:getIdList(data.card)
    local reds, blacks = {}, {}
    for _, id in ipairs(card_ids) do
      local color = Fk:getCardById(id).color
      if color == Card.Red then
        table.insert(reds, id)
      elseif color == Card.Black then
        table.insert(blacks, id)
      end
    end
    local moveInfos = {}
    local audio_case = 3
    if #reds > 0 then
      table.insert(moveInfos, {
        ids = reds,
        from = data.card.type == Card.TypeEquip and player or nil,
        to = player,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonJustMove,
        skillName = huamu.name,
        specialName = "huamu_yushu",
        moveVisible = true,
        proposer = player,
      })
      audio_case = audio_case - 2
    end
    if #blacks > 0 then
      table.insert(moveInfos, {
        ids = blacks,
        from = data.card.type == Card.TypeEquip and player or nil,
        to = player,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonJustMove,
        skillName = huamu.name,
        specialName = "huamu_lingshan",
        moveVisible = true,
        proposer = player,
      })
      audio_case = audio_case - 1
    end
    if #moveInfos > 0 then
      room:notifySkillInvoked(player, huamu.name)
      player:broadcastSkillInvoke(huamu.name, audio_case * 2 + math.random(2))
      room:moveCards(table.unpack(moveInfos))
    end
  end,
})

return huamu
