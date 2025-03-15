local biri = fk.CreateSkill{
  name = "biri",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["biri"] = "蔽日",
  [":biri"] = "锁定技，每回合首次有角色不因摸牌获得牌后，你摸一张牌。",

  ["$biri1"] = "",
  ["$biri2"] = "",
}

biri:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(biri.name) and player:usedSkillTimes(biri.name, Player.HistoryTurn) == 0 then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return end
      for _, move in ipairs(data) do
        if move.from and move.toArea == Card.PlayerHand and move.moveReason ~= fk.ReasonDraw then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, biri.name)
  end,
})

return biri
