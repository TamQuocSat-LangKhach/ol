
local shenxian = fk.CreateSkill {
  name = "ol__shenxian",
}

Fk:loadTranslationTable{
  ["ol__shenxian"] = "甚贤",
  [":ol__shenxian"] = "每回合限一次，当其他角色在你的回合外因弃置而失去基本牌后，你可以摸一张牌。",

  ["$ol__shenxian1"] = "夫君无断，妾身亲为。",
  ["$ol__shenxian2"] = "助君大业，立德维心。",
}

shenxian:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shenxian.name) and player.room.current ~= player and
      player:usedSkillTimes(shenxian.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard and move.from ~= player then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).type == Card.TypeBasic then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, shenxian.name)
  end,
})

return shenxian
