local this = fk.CreateSkill{
  name = "ol_ex__miji",
}

this:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and target.phase == Player.Finish and player:isWounded() and
    (target == player or player:getMark("@@ol_ex__zhenlie-turn") > 0)
  end,
  on_cost = function(self, event, target, player, data)
    if target == player then
      return player.room:askToSkillInvoke(player, { skill_name = this.name })
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getLostHp()
    room:drawCards(player, n, this.name)
    if player.dead or player:isNude() then return false end
    n = player:getLostHp()
    if n > 0 then
      room:askToYiji(player, { min_num = 0, max_num = n, skill_name = this.name, targets = room:getOtherPlayers(player, false), cards = player:getCardIds("he") })
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__miji"] = "秘计",
  [":ol_ex__miji"] = "结束阶段，若你已受伤，你可以摸X张牌，然后可以将至多X张牌交给其他角色。（X为你已损失的体力值）",
}

return this