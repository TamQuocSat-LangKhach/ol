local zhenying = fk.CreateSkill{
  name = "zhenying",
}

Fk:loadTranslationTable{
  ["zhenying"] = "镇荧",
  [":zhenying"] = "出牌阶段限两次，你可以与一名手牌数不大于你的其他角色同时摸或弃置手牌至至多两张，然后手牌数较少的角色视为对对方使用【决斗】。",

  ["#zhenying"] = "镇荧：与一名手牌数不大于你的其他角色同时选择将手牌调整至0~2",
  ["#zhenying-choice"] = "镇荧：选择你要调整至的手牌数",
  ["#zhenying-discard"] = "镇荧：请弃置%arg张手牌",

  ["$zhenying1"] = "吾闻世间有忠义，今欲为之。",
  ["$zhenying2"] = "吴虽兵临三郡，普宁死不降。",
}

local U = require "packages/utility/utility"

zhenying:addEffect("active", {
  anim_type = "control",
  prompt = "#zhenying",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(zhenying.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zhenying.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:getHandcardNum() >= to_select:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local tos = {player, target}
    local cardsMap = {}
    for _, p in ipairs(tos) do
      cardsMap[p.id] = table.filter(p:getCardIds("h"), function(id)
        return not p:prohibitDiscard(Fk:getCardById(id))
      end)
    end
    local result = U.askForJointChoice(tos, {"0", "1", "2"}, zhenying.name, "#zhenying-choice")
    local discard_num_map = {}
    for _, p in ipairs(tos) do
      discard_num_map[p.id] = p:getHandcardNum() - tonumber(result[p])
    end
    local req = Request:new(tos, "AskForUseActiveSkill")
    for _, p in ipairs(tos) do
      local num = math.min(discard_num_map[p.id], #cardsMap[p.id])
      if num > 0 then
        local extra_data = {
          num = num,
          min_num = num,
          include_equip = false,
          skillName = zhenying.name,
          pattern = ".",
          reason = zhenying.name,
        }
        req:setData(p, { "discard_skill", "#AskForDiscard:::"..num..":"..num, false, extra_data })
        req:setDefaultReply(p, table.random(cardsMap[p.id], discard_num_map[p.id]))
      end
    end
    req.players = table.filter(req.players, function(p) return req.data[p.id] ~= nil end)
    if #req.players > 0 then
      local moveInfos = {}
      req.focus_text = zhenying.name
      for _, p in ipairs(req.players) do
        local throw = req:getResult(p)
        if throw.card then
          throw = throw.card.subcards
        end
        table.insert(moveInfos, {
          ids = throw,
          from = p,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p,
          skillName = zhenying.name,
        })
      end
      room:moveCards(table.unpack(moveInfos))
    end
    for _, p in ipairs(tos) do
      if not p.dead then
        local num = discard_num_map[p.id]
        if num < 0 then
          p:drawCards(-num, zhenying.name)
        end
      end
    end
    if not player.dead and not target.dead and player:getHandcardNum() ~= target:getHandcardNum() then
      local from, to = player, target
      if player:getHandcardNum() > target:getHandcardNum() then
        from, to = target, player
      end
      room:useVirtualCard("duel", nil, from, to, zhenying.name)
    end
  end,
})

return zhenying
