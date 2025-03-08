local chenshuo = fk.CreateSkill{
  name = "chenshuo",
}

Fk:loadTranslationTable{
  ["chenshuo"] = "谶说",
  [":chenshuo"] = "结束阶段，你可以展示一张手牌。若如此做，展示牌堆顶牌，若两张牌类型/花色/点数/牌名字数中任意项相同且展示牌数不大于3，"..
  "重复此流程。然后你获得以此法展示的牌。",

  ["#chenshuo-invoke"] = "谶说：你可以展示一张手牌，亮出并获得牌堆顶至多三张类型、花色、点数或字数相同的牌",

  ["$chenshuo1"] = "命数玄奥，然吾可言之。",
  ["$chenshuo2"] = "天地神鬼之辩，在吾唇舌之间。",
}

chenshuo:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chenshuo.name) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chenshuo.name,
      prompt = "#chenshuo-invoke",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    player:showCards(event:getCostData(self).cards)
    room:delay(1000)
    if player.dead then return end
    local cards = {}
    for i = 1, 3, 1 do
      local get = room:turnOverCardsFromDrawPile(player, room:getNCards(1), chenshuo.name)
      table.insert(cards, get[1])
      local card2 = Fk:getCardById(get[1])
      if card.type == card2.type or card.suit == card2.suit or card.number == card2.number or
        Fk:translate(card.trueName, "zh_CN"):len() == Fk:translate(card2.trueName, "zh_CN"):len() then
        room:setCardEmotion(get[1], "judgegood")
        room:delay(1000)
      else
        room:setCardEmotion(get[1], "judgebad")
        room:delay(1000)
        break
      end
    end
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player, chenshuo.name)
  end,
})

return chenshuo
