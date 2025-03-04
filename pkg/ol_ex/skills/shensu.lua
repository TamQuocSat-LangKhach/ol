local shensu = fk.CreateSkill {
  name = "ol_ex__shensu"
}

Fk:loadTranslationTable{
  ["ol_ex__shensu"] = "神速",
  [":ol_ex__shensu"] = "你可以做出如下选择：1.跳过判定阶段和摸牌阶段；2.跳过出牌阶段并弃置一张装备牌；3.跳过弃牌阶段并翻面。你每选择一项，"..
  "便视为使用一张无距离限制的【杀】。",

  ["#ol_ex__shensu1-choose"] = "神速：你可以跳过判定阶段和摸牌阶段，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shensu2-choose"] = "神速：你可以跳过出牌阶段并弃置一张装备牌，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shensu3-choose"] = "神速：你可以跳过弃牌阶段并翻面，视为使用一张无距离限制的【杀】",

  ["$ol_ex__shensu1"] = "奔逸绝尘，不留踪影！",
  ["$ol_ex__shensu2"] = "健步如飞，破敌不备！",
}

shensu:addEffect(fk.EventPhaseChanging, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shensu.name) and not data.skipped then
      if data.phase == Player.Judge then
        if not player:canSkip(Player.Draw) then return end
      elseif data.phase == Player.Play then
        if player:isNude() then return end
      elseif data.phase == Player.Discard then
        return
      end
      return table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canUseTo(slash, p, {bypass_distances = true, bypass_times = true})
    end)
    if data.phase == Player.Judge or data.phase == Player.Discard then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = max_num,
        targets = targets,
        skill_name = shensu.name,
        prompt = "#ol_ex__shensu"..(data.phase == Player.Judge and 1 or 3).."-choose",
        cancelable = true,
      })
      if #tos > 0 then
        event:setCostData(self, {tos = tos})
        return true
      end
    elseif data.phase == Player.Play then
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = max_num,
        targets = targets,
        pattern = ".|.|.|.|.|equip",
        skill_name = shensu.name,
        prompt = "#ol_ex__shensu2-choose",
        cancelable = true,
        will_throw = true,
      })
      if #tos > 0 and #cards > 0 then
        event:setCostData(self, {tos = tos, cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.skipped = true
    if data.phase == Player.Play then
      room:throwCard(event:getCostData(self).cards, shensu.name, player, player)
    end
    if player.dead then return end
    local targets = event:getCostData(self).tos
    room:sortByAction(targets)
    room:useVirtualCard("slash", nil, player, targets, shensu.name, true)
  end,
})

return shensu
