local xiaofan = fk.CreateSkill{
  name = "xiaofan",
}

Fk:loadTranslationTable{
  ["xiaofan"] = "嚣翻",
  [":xiaofan"] = "当你需要使用牌时，你可以观看牌堆底的X+1张牌，使用其中你需要的牌，然后弃置你的前X区域里的所有牌："..
  "1.判定区；2.装备区；3.手牌区。（X为你于当前回合内使用过的牌的类别数）",

  ["#xiaofan"] = "嚣翻：观看牌堆底%arg张牌，使用其中你需要的牌",

  ["$xiaofan1"] = "吾得三顾之伯乐，必登九丈之高台。",
  ["$xiaofan2"] = "诸君食肉而鄙，空有大腹作碍。",
}

xiaofan:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local types = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(types, use.card.type)
      end
      return #types == 3
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "xiaofan_types-turn", types)
  end
end)

xiaofan:addEffect("viewas", {
  pattern = ".",
  prompt = function(self, player)
    return "#xiaofan:::"..(#player:getTableMark("xiaofan_types-turn") + 1)
  end,
  expand_pile = function (self, player)
    local ids = {}
    local draw_pile = Fk:currentRoom().draw_pile
    for i = 0, #player:getTableMark("xiaofan_types-turn"), 1 do
      if #draw_pile <= i then break end
      table.insert(ids, draw_pile[#draw_pile - i])
    end
    return ids
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(Fk:currentRoom().draw_pile, to_select) then
      local card = Fk:getCardById(to_select)
      if Fk.currentResponsePattern == nil then
        return player:canUse(card) and not player:prohibitUse(card)
      else
        return Exppattern:Parse(Fk.currentResponsePattern):match(card)
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  after_use = function (self, player, use)
    if player.dead then return end
    local x = #player:getTableMark("xiaofan_types-turn")
    local areas = {"j", "e", "h"}
    local to_throw = ""
    for i = 1, x, 1 do
      to_throw = to_throw..areas[i]
    end
    player:throwAllCards(to_throw, xiaofan.name)
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})
xiaofan:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(xiaofan.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "xiaofan_types-turn", data.card.type)
  end,
})

return xiaofan
