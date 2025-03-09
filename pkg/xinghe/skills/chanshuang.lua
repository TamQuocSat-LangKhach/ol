local chanshuang = fk.CreateSkill{
  name = "chanshuang",
}

Fk:loadTranslationTable{
  ["chanshuang"] = "缠双",
  [":chanshuang"] = "出牌阶段限一次，你可以与一名其他角色同时选择一项执行："..
  "1.重铸一张牌；2.使用一张【杀】；3.弃置两张牌。结束阶段，你依次执行上述前X项（X为你本回合以任意方式执行过的项数）。",

  ["#chanshuang"] = "缠双：选择一名其他角色，与其同时选择一项执行",
  ["#chanshuang-choice"] = "缠双：选择一项执行",
  ["chanshuang_recast"] = "重铸一张牌",
  ["chanshuang_slash"] = "使用一张杀",
  ["chanshuang_discard"] = "弃置两张牌",
  ["#chanshuang-recast"] = "缠双：选择一张牌重铸",
  ["#chanshuang-slash"] = "缠双：你可以使用一张【杀】",

  ["$chanshuang1"] = "武艺精熟，勇冠三军。",
  ["$chanshuang2"] = "以一敌二，易如反掌。",
}

chanshuang:addEffect("active", {
  anim_type = "offensive",
  prompt = "#chanshuang",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(chanshuang.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local tos = {player, target}
    local all_choices = {"chanshuang_recast", "chanshuang_slash", "chanshuang_discard"}
    local req = Request:new(tos, "AskForChoice")
    for _, p in ipairs(tos) do
      local choices = {"chanshuang_slash"}
      local cards = player:getCardIds("he")
      if #cards > 0 then
        table.insert(choices, "chanshuang_recast")
        if #table.filter(cards, function (id)
          return not p:prohibitDiscard(Fk:getCardById(id))
        end) > 1 then
          table.insert(choices, "chanshuang_discard")
        end
      end
      req:setData(p, {choices, all_choices, chanshuang.name, "#chanshuang-choice"})
      req:setDefaultReply(p, "chanshuang_slash")
    end
    req.focus_text = chanshuang.name
    req.receive_decode = false
    for _, p in ipairs(tos) do
      if not p.dead then
        local choice = req:getResult(p)
        if choice == "chanshuang_recast" then
          if not p:isNude() then
            local card = room:askToCards(p, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = chanshuang.name,
              prompt = "#chanshuang-recast",
              cancelable = false,
            })
            room:recastCard(card, p)
          end
        elseif choice == "chanshuang_slash" then
          local use = room:askToUseCard(p, {
            skill_name = chanshuang.name,
            pattern = "slash",
            prompt = "#chanshuang-slash",
            cancelable = true,
            extra_data = {
              bypass_times = true,
            }
          })
          if use then
            use.extraUse = true
            room:useCard(use)
          end
        elseif choice == "chanshuang_discard" then
          room:askToDiscard(p, {
            min_num = 2,
            max_num = 2,
            include_equip = true,
            skill_name = chanshuang.name,
            cancelable = false,
          })
        end
      end
    end
  end,
})
chanshuang:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(chanshuang.name) and player.phase == Player.Finish then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return false end
      local x = 0
      local use = nil
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        use = e.data
        if use.from == player and use.card.trueName == "slash" then
          x = 1
          return true
        end
      end, turn_event.id)
      local choices = {}
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        local a, b = 0, 0
        for _, move in ipairs(e.data) do
          if move.from == player then
            if move.moveReason == fk.ReasonRecast then
              a = a + #move.moveInfo
            elseif move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  b = b + 1
                end
              end
            end
          end
        end
        if a == 1 then
          table.insertIfNeed(choices, "a")
        end
        if b == 2 then
          table.insertIfNeed(choices, "b")
        end
        return #choices == 2
      end, turn_event.id)
      x = x + #choices
      if x > 0 then
        event:setCostData(self, {choice = x})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(self).choice
    if not player:isNude() then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = chanshuang.name,
        prompt = "#chanshuang-recast",
        cancelable = false,
      })
      room:recastCard(card, player)
      if player.dead then return end
    end
    if x > 1 then
      local use = room:askToUseCard(player, {
        skill_name = chanshuang.name,
        pattern = "slash",
        prompt = "#chanshuang-slash",
        cancelable = true,
        extra_data = {
          bypass_times = true,
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
      if player.dead then return false end
    end
    if x > 2 then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = chanshuang.name,
        cancelable = false,
      })
    end
  end,
})

return chanshuang
