local yanxi = fk.CreateSkill{
  name = "yanxi",
}

Fk:loadTranslationTable{
  ["yanxi"] = "宴戏",
  [":yanxi"] = "出牌阶段限一次，你将一名其他角色的随机一张手牌与牌堆顶的两张牌混合后展示，你猜测哪张牌来自其手牌。若猜对，你获得三张牌；"..
  "若猜错，你获得选中的牌。你以此法获得的牌本回合不计入手牌上限。",

  ["#yanxi"] = "宴戏：将一名角色的一张手牌与牌堆顶的两张牌混合后，猜测哪张来自其手牌",
  ["#yanxi-ask"] = "宴戏：选择你认为来自 %dest 手牌的一张牌",
  ["@@yanxi-inhand-turn"] = "宴戏",

  ["$yanxi1"] = "宴会嬉趣，其乐融融。",
  ["$yanxi2"] = "宴中趣玩，得遇知己。",
}

yanxi:addEffect("active", {
  anim_type = "control",
  prompt = "#yanxi",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yanxi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = room:getNCards(2)
    local id = table.random(target:getCardIds("h"))
    table.insert(cards, id)
    table.shuffle(cards)
    local id2 = room:askToChooseCard(player, {
      target = target,
      flag = { card_data = {{ yanxi.name, cards }} },
      skill_name = yanxi.name,
      prompt = "#yanxi-ask::"..target.id
    })
    if id2 ~= id then
      cards = {id2}
    end
    room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, yanxi.name, nil, false, player, "@@yanxi-inhand-turn")
  end,
})
yanxi:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@yanxi-inhand-turn") > 0
  end,
})

return yanxi
