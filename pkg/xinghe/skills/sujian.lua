local sujian = fk.CreateSkill{
  name = "sujian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["sujian"] = "素俭",
  [":sujian"] = "锁定技，弃牌阶段，你改为：将所有非本回合获得的手牌分配给其他角色，或弃置非本回合获得的手牌，并弃置一名其他角色至多等量的牌。",

  ["sujian_give"] = "分配非本回合获得的手牌",
  ["sujian_throw"] = "弃置这些牌，并弃置一名角色等量牌",
  ["#sujian-choose"] = "素俭：弃置一名其他角色至多 %arg 张牌",
  ["@@sujian"] = "素俭",

  ["$sujian1"] = "不苟素俭，不置私产。",
  ["$sujian2"] = "高风亮节，摆袖却金。",
}

sujian:addEffect(fk.EventPhaseProceeding, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sujian.name) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player._phase_end = true
    local ids = table.simpleClone(player:getCardIds("h"))
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryTurn)
    if #ids > 0 then
      local choice = "sujian_throw"
      if #room.alive_players  > 1 then
        for _, id in ipairs(ids) do
          room:setCardMark(Fk:getCardById(id), "@@sujian", 1)
        end
        choice = room:askToChoice(player, {
          choices = {"sujian_give", "sujian_throw"},
          skill_name = sujian.name,
        })
        for _, id in ipairs(ids) do
          room:setCardMark(Fk:getCardById(id), "@@sujian", 0)
        end
      end
      if choice == "sujian_give" then
        room:askToYiji(player, {
          min_num = #ids,
          max_num = #ids,
          skill_name = sujian.name,
          targets = room:getOtherPlayers(player, false),
          cards = ids,
        })
      else
        room:throwCard(ids, sujian.name, player, player)
        if player.dead then return true end
        local targets = table.filter(room:getOtherPlayers(player, false), function(p)
          return not p:isNude()
        end)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = targets,
            skill_name = sujian.name,
            prompt = "#sujian-choose:::"..#ids,
            cancelable = false,
          })[1]
          local cards = room:askToChooseCards(player, {
            target = to,
            min = 0,
            max = #ids,
            flag = "he",
            skill_name = sujian.name,
          })
          if #cards > 0 then
            room:throwCard(cards, sujian.name, to, player)
          end
        end
      end
    end
  end,
})

return sujian
