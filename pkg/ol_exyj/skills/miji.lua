local miji = fk.CreateSkill{
  name = "ol_ex__miji",
}

Fk:loadTranslationTable{
  ["ol_ex__miji"] = "秘计",
  [":ol_ex__miji"] = "结束阶段，若你已受伤，你可以摸X张牌，然后可以将至多X张牌交给其他角色。（X为你已损失的体力值）",
}

miji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(miji.name) and target.phase == Player.Finish and player:isWounded() and
      (target == player or player:getMark("@@ol_ex__zhenlie-turn") > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getLostHp()
    player:drawCards(n, miji.name)
    if player.dead or player:isNude() or #room:getOtherPlayers(player, false) == 0 then return false end
    n = player:getLostHp()
    if n > 0 then
      room:askToYiji(player, {
        min_num = 0,
        max_num = n,
        skill_name = miji.name,
        targets = room:getOtherPlayers(player, false),
        cards = player:getCardIds("he"),
      })
    end
  end,
})

return miji