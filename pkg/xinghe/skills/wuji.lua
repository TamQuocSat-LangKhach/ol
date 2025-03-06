local wuji = fk.CreateSkill{
  name = "ol__wuji",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ol__wuji"] = "武继",
  [":ol__wuji"] = "觉醒技，结束阶段，若你本回合造成过至少3点伤害，你加1点体力上限并回复1点体力，失去技能〖虎啸〗，然后从牌堆、弃牌堆或场上获得"..
  "【青龙偃月刀】。",

  ["$ol__wuji1"] = "父亲的武艺，我已掌握大半。",
  ["$ol__wuji2"] = "有青龙偃月刀在，小女必胜。",
}

wuji:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuji.name) and player.phase == Player.Finish and
      player:usedSkillTimes(wuji.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local n = 0
    player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data
      n = n + damage.damage
      return n > 2
    end, Player.HistoryTurn)
    return n > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = wuji.name,
      }
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "-ol__huxiao")
    if player.dead then return end
    local ids = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "blade" and
        table.contains({Card.DrawPile, Card.DiscardPile, Card.PlayerEquip}, room:getCardArea(id)) then
        table.insert(ids, id)
      end
    end
    if #ids > 0 then
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonPrey, wuji.name, nil, true, player)
    end
  end,
})

return wuji
