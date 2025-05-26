local bojue = fk.CreateSkill{
  name = "bojue",
}

Fk:loadTranslationTable{
  ["bojue"] = "搏决",
  [":bojue"] = "出牌阶段限两次，你可以与一名其他角色同时选择摸或弃置一张牌，若你与其手牌数因此变化之和为：0，你与其弃置对方一张牌；"..
  "2，你与其视为对对方使用一张【杀】。",

  ["#bojue"] = "搏决：与一名角色同时选择摸或弃一张牌，根据双方选择执行效果",
  ["#bojue-ask"] = "搏决：与 %src 同时选择摸或弃一张牌",
  ["#bojue-discard"] = "搏决：弃置 %dest 一张牌",

  ["$bojue1"] = "匹夫，今日便让你尝尝我大刀之利！",
  ["$bojue2"] = "孙坚！你若有胆，便与我一对一！",
}

bojue:addEffect("active", {
  anim_type = "offensive",
  prompt = "#bojue",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(bojue.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(bojue.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]

    local extra_data = {
      num = 1,
      min_num = 1,
      include_equip = true,
      skillName = bojue.name,
      pattern = ".",
    }
    local req = Request:new({player, target}, "AskForUseActiveSkill")
    req.focus_text = bojue.name
    req:setData(player, { "discard_skill", "#bojue-ask:"..target.id, true, extra_data })
    req:setData(target, { "discard_skill", "#bojue-ask:"..player.id, true, extra_data })

    local moves, n = {}, 0
    for _, p in ipairs(req.players) do
      local result = req:getResult(p)
      if result then
        if result == "" then
          n = n + 1
          if not p.dead then
            p:drawCards(1, bojue.name)  --FIXME: 万恶的BeforeDrawCard时机
          end
        elseif not p.dead then
          local replyCard = result.card
          if table.contains(p:getCardIds("h"), replyCard.subcards[1]) then
            n = n - 1
          end
          if table.contains(p:getCardIds("he"), replyCard.subcards[1]) then
            table.insert(moves, {
              ids = replyCard.subcards,
              from = p,
              toArea = Card.DiscardPile,
              moveReason = fk.ReasonDiscard,
              proposer = p,
              skillName = bojue.name,
            })
          end
        end
      end
    end
    if #moves > 0 then
      room:moveCards(table.unpack(moves))
    end
    if n == 0 then
      if not player.dead and not target.dead and not target:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = bojue.name,
          prompt = "#bojue-discard::"..target.id,
        })
        room:throwCard(card, bojue.name, target, player)
      end
      if not player.dead and not target.dead and not player:isNude() then
        local card = room:askToChooseCard(target, {
          target = player,
          flag = "he",
          skill_name = bojue.name,
          prompt = "#bojue-discard::"..player.id,
        })
        room:throwCard(card, bojue.name, player, target)
      end
    elseif n == 2 then
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, bojue.name, true)
      end
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, target, player, bojue.name, true)
      end
    end
  end,
})

return bojue
