local yirong = fk.CreateSkill{
  name = "yirong",
}

Fk:loadTranslationTable{
  ["yirong"] = "移荣",
  [":yirong"] = "出牌阶段限两次，你可以将手牌摸/弃至手牌上限并令你手牌上限-1/+1。",

  ["#yirong-discard"] = "移荣：弃置%arg张手牌，令你的手牌上限+1",
  ["#yirong-draw"] = "移荣：摸%arg张牌，令你的手牌上限-1",

  ["$yirong1"] = "花开彼岸，繁荣不减当年。",
  ["$yirong2"] = "移花接木，花容更胜从前。",
}

yirong:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player)
    local x = player:getHandcardNum() - player:getMaxCards()
    if x > 0 then
      return "#yirong-discard:::"..x
    else
      return "#yirong-draw:::"..(-x)
    end
  end,
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(yirong.name, Player.HistoryPhase) or -1
  end,
  target_num = 0,
  card_num = function(self, player)
    return math.max(0, player:getHandcardNum() - player:getMaxCards())
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yirong.name, Player.HistoryPhase) < 2 and
    player:getHandcardNum() ~= player:getMaxCards()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getHandcardNum() - player:getMaxCards() and
    table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if #effect.cards > 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      room:throwCard(effect.cards, yirong.name, player, player)
    else
      local n = player:getMaxCards() - player:getHandcardNum()
      if n > 0 then
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
        player:drawCards(n, yirong.name)
      end
    end
  end,
})

return yirong
