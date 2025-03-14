local beishi = fk.CreateSkill{
  name = "beishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["beishi"] = "卑势",
  [":beishi"] = "锁定技，当你首次发动〖三恇〗选择的角色失去最后的手牌后，你回复1点体力。",

  ["@@beishi"] = "卑势",

  ["$beishi1"] = "虎卑其势，将有所逮。",
  ["$beishi2"] = "至山穷水尽，复柳暗花明。",
}

beishi:addLoseEffect(function (self, player)
  local room = player.room
  if player:getMark(beishi.name) ~= 0 then
    local to = room:getPlayerById(player:getMark(beishi.name))
    if not table.find(room:getOtherPlayers(player, false), function (p)
      return p:getMark(beishi.name) == to.id
    end) then
      room:setPlayerMark(to, "@@beishi", 0)
    end
  end
end)

beishi:addEffect(fk.AfterCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(beishi.name) and player:isWounded() and player:getMark(beishi.name) ~= 0 then
      for _, move in ipairs(data) do
        if move.from and player:getMark(beishi.name) == move.from.id and move.from:isKongcheng() then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = beishi.name,
    })
  end,
})

return beishi
