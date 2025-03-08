local tianhou = fk.CreateSkill{
  name = "tianhou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianhou"] = "天候",
  [":tianhou"] = "锁定技，准备阶段，你观看牌堆顶牌并选择是否用一张牌交换之，然后展示牌堆顶的牌，令一名角色根据此牌花色获得技能直到你下个准备阶段"..
  "（若你死亡，改为直到本轮结束时）："..
  "<font color='red'>♥</font><a href=':tianhou_hot'>〖烈暑〗</a>；"..
  "<font color='red'>♦</font><a href=':tianhou_fog'>〖凝雾〗</a>；"..
  "♠<a href=':tianhou_rain'>〖骤雨〗</a>；"..
  "♣<a href=':tianhou_frost'>〖严霜〗</a>。",

  ["#tianhou-exchange"] = "天候：你可以用一张手牌交换牌堆底部的牌",
  ["#tianhou-choose"] = "天候：令一名角色获得技能<br>〖%arg〗：%arg2",
  ["@@tianhou_hot"] = "烈暑",
  ["@@tianhou_fog"] = "凝雾",
  ["@@tianhou_rain"] = "骤雨",
  ["@@tianhou_frost"] = "严霜",

  ["$tianhou1"] = "雷霆雨露，皆为君恩。",
  ["$tianhou2"] = "天象之所显，世事之所为。",
}

tianhou:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianhou.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top_cards = room:getNCards(1)
    local piles = room:askToArrangeCards(player, {
      skill_name = tianhou.name,
      card_map = {
        "Top", top_cards,
        player.general, player:getCardIds("he"),
      },
      prompt = "#tianhou-exchange",
    })
    room:swapCardsWithPile(player, piles[1], piles[2], tianhou.name, "Top")
    if player.dead then return end
    top_cards = room:getNCards(1)
    player:showCards(top_cards)
    local suit = Fk:getCardById(top_cards[1], true).suit
    if suit == Card.NoSuit then return end
    local suits = {Card.Heart, Card.Diamond, Card.Spade, Card.Club}
    local i = table.indexOf(suits, suit)
    local skills = {"tianhou_hot", "tianhou_fog", "tianhou_rain", "tianhou_frost"}
    local skill = skills[i]
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = tianhou.name,
      prompt = "#tianhou-choose:::"..skill..":"..Fk:translate(":"..skill),
      cancelable = false,
    })[1]
    player.tag[tianhou.name] = {to.id, skill}
    room:handleAddLoseSkills(to, skill)
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Start and type(player.tag[tianhou.name]) == "table"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player.tag[tianhou.name]
    local p = room:getPlayerById(mark[1])
    room:handleAddLoseSkills(p, "-"..mark[2])
    player.tag[tianhou.name] = nil
  end,
})
tianhou:addEffect(fk.RoundEnd, {
  can_refresh = function (self, event, target, player, data)
    return type(player.tag[tianhou.name]) == "table" and player.dead
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player.tag[tianhou.name]
    local p = room:getPlayerById(mark[1])
    room:handleAddLoseSkills(p, "-"..mark[2])
    player.tag[tianhou.name] = nil
  end,
})

return tianhou
