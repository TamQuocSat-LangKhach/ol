local chongshen = fk.CreateSkill{
  name = "chongshen",
}

Fk:loadTranslationTable{
  ["chongshen"] = "重身",
  [":chongshen"] = "你可以将一张你本轮得到的红色牌当【闪】使用。",

  ["#chongshen"] = "重身：将一张本轮获得的红色牌当【闪】使用",
  ["@@chongshen-inhand-round"] = "重身",

  ["$chongshen1"] = "妾死则矣，腹中稚婴何辜？",
  ["$chongshen2"] = "身怀六甲，君忘好生之德乎？",
}

chongshen:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "jink",
  prompt = "#chongshen",
  card_filter = function(self, player, to_select, selected)
    if #selected ~= 0 then return end
    local card = Fk:getCardById(to_select)
    return card.color == Card.Red and card:getMark("@@chongshen-inhand-round") > 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("jink")
    c.skillName = chongshen.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})
chongshen:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(chongshen.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@chongshen-inhand-round", 1)
          end
        end
      end
    end
  end,
})

return chongshen
