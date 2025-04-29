local liance = fk.CreateSkill {
  name = "liance",
}

Fk:loadTranslationTable{
  ["liance"] = "敛策",
  [":liance"] = "每轮你的回合外和回合内各限一次，当你的手牌数变化后，若为全场最少，你可以将手牌摸至体力上限，然后本回合下次有角色造成伤害时，"..
  "此伤害+1。",

  ["#liance-invoke"] = "敛策：你可以将手牌摸至体力上限，本回合下次伤害+1",
}

liance:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(liance.name) and player:getHandcardNum() < player.maxHp and
      table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) then
      if player.room.current == player then
        if player:getMark("liance1-round") > 0 then return end
      else
        if player:getMark("liance2-round") > 0 then return end
      end
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.room.current == player then
      room:setPlayerMark(player, "liance1-round", 1)
    else
      room:setPlayerMark(player, "liance2-round", 1)
    end
    player:drawCards(player.maxHp - player:getHandcardNum(), liance.name)
    local n = room:getBanner("liance-turn") or 0
    room:setBanner("liance-turn", n + 1)
  end,
})

liance:addEffect(fk.DamageCaused, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.room:getBanner("liance-turn")
  end,
  on_refresh = function (self, event, target, player, data)
    data:changeDamage(player.room:getBanner("liance-turn"))
    player.room:setBanner("liance-turn", nil)
  end,
})

liance:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "liance1-round", 0)
  room:setPlayerMark(player, "liance2-round", 0)
end)

return liance
