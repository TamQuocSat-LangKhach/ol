local dangxian = fk.CreateSkill{
  name = "ol_ex__dangxian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__dangxian"] = "当先",
  [":ol_ex__dangxian"] = "锁定技，回合开始时，你执行一个额外的出牌阶段；此阶段开始时，你可以从牌堆或弃牌堆获得一张【杀】"..
  "（使用此【杀】无距离限制），若如此做，此阶段结束时，若你此阶段未造成过伤害，你对自己造成1点伤害。",

  ["#ol_ex__dangxian-invoke"] = "当先：是否获得一张无距离限制的【杀】？若此阶段未造成伤害则对自己造成1点伤害",
  ["@@ol_ex__dangxian-inhand"] = "当先",
}

dangxian:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangxian.name)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraPhase(Player.Play, dangxian.name)
  end,
})

dangxian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangxian.name) and
      player.phase == Player.Play and data.reason == dangxian.name
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = dangxian.name,
      prompt = "#ol_ex__dangxian-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    print(self.name)
    local cards = room:getCardsFromPileByRule("slash", 1, "allPiles")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, dangxian.name, nil, true, player, "@@ol_ex__dangxian-inhand")
    end
  end,
})

dangxian:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player:usedEffectTimes("#ol_ex__dangxian_2_trig", Player.HistoryPhase) > 0 and not player.dead and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryPhase) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player,
      damage = 1,
      skillName = dangxian.name,
    }
  end,
})

dangxian:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card)
    return card and card.trueName == "slash" and card:getMark("@@ol_ex__dangxian-inhand") > 0
  end,
})

return dangxian
