local jieliang = fk.CreateSkill{
  name = "jieliang",
}

Fk:loadTranslationTable{
  ["jieliang"] = "截粮",
  [":jieliang"] = "其他角色摸牌阶段开始时，你可以弃置一张牌，令其本回合摸牌阶段摸牌数和手牌上限-1。若如此做，本回合弃牌阶段结束时，"..
  "你可以获得其中一张其于此阶段弃置的牌。",

  ["#jieliang-invoke"] = "截粮：你可以弃一张牌，令 %dest 本回合摸牌阶段摸牌数和手牌上限-1",
  ["#jieliang-prey"] = "截粮：是否获得一张弃置的牌？",

  ["$jieliang1"] = "伏兵起，粮道绝！",
  ["$jieliang2"] = "粮草根本，截之破敌！",
}

jieliang:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(jieliang.name) and target.phase == Player.Draw and
      not player:isNude() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jieliang.name,
      prompt = "#jieliang-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, jieliang.name, player, player)
    if not target.dead then
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 1)
    end
  end,
})
jieliang:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return player:usedSkillTimes(jieliang.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n - player:usedSkillTimes(jieliang.name, Player.HistoryTurn)
  end,
})
jieliang:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target.phase == Player.Discard and player:usedSkillTimes(jieliang.name, Player.HistoryTurn) > 0 and not player.dead then
      local ids = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == target and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jieliang.name,
      prompt = "#jieliang-prey",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = target,
      flag = { card_data = {{ "pile_discard", event:getCostData(self).cards }} },
      skill_name = jieliang.name,
    })
    room:obtainCard(player, card, true, fk.ReasonJustMove, player, jieliang.name)
  end,
})

return jieliang
