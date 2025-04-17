local zhuikong = fk.CreateSkill{
  name = "ol_ex__zhuikong",
}

Fk:loadTranslationTable{
  ["ol_ex__zhuikong"] = "惴恐",
  [":ol_ex__zhuikong"] = "其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，其本回合不能对除其以外的角色使用牌；"..
  "若你没赢，你获得其拼点牌，然后其视为对你使用一张【杀】。",

  ["#ol_ex__zhuikong-invoke"] = "惴恐：你可以与 %dest 拼点，若赢，其只能对自己使用牌，若没赢，你获得其拼点牌，其视为对你使用【杀】",
  ["@@ol_ex__zhuikong-turn"] = "惴恐",

  ["$ol_ex__zhuikong1"] = "曹贼一日不除，旦夕如不终日。",
  ["$ol_ex__zhuikong2"] = "见许田曹瞒骖乘，叫人如芒在背",
}

zhuikong:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(zhuikong.name) and player:isWounded() and
      player:canPindian(target) and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhuikong.name,
      prompt = "#ol_ex__zhuikong-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = player:pindian({target}, zhuikong.name)
    if pindian.results[target].winner == player then
      if not target.dead then
        room:setPlayerMark(target, "@@ol_ex__zhuikong-turn", 1)
      end
    elseif not player.dead then
      if pindian.results[target] and pindian.results[target].toCard and
        room:getCardArea(pindian.results[target].toCard) == Card.DiscardPile then
        room:moveCardTo(pindian.results[target].toCard, Card.PlayerHand, player, fk.ReasonJustMove, zhuikong.name, nil, true, player)
      end
      if not target.dead and not player.dead then
        room:useVirtualCard("slash", nil, target, player, zhuikong.name, true)
      end
    end
  end,
})
zhuikong:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from:getMark("@@ol_ex__zhuikong-turn") > 0 and card and from ~= to
  end,
})

return zhuikong
