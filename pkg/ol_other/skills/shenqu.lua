local shenqu = fk.CreateSkill{
  name = "shenqu",
}

Fk:loadTranslationTable{
  ["shenqu"] = "神躯",
  [":shenqu"] = "一名角色的准备阶段，若你的手牌数不大于你的体力上限，你可以摸两张牌。当你受到伤害后，你可以使用一张【桃】。",

  ["#shenqu-invoke"] = "神躯：你可以摸两张牌",
  ["#shenqu-use"] = "神躯：你可以使用一张【桃】",

  ["$shenqu1"] = "别心怀侥幸了，你们不可能赢！",
  ["$shenqu2"] = "虎牢关，我一人镇守足矣。",
}

shenqu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shenqu.name) and target.phase == Player.Start and
      player:getHandcardNum() <= player.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shenqu.name,
      prompt = "#shenqu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, shenqu.name)
  end,
})
shenqu:addEffect(fk.Damaged, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shenqu.name) and player == target
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = shenqu.name,
      pattern = "peach",
      prompt = "#shenqu-use",
      cancelable = true,
    })
    if use then
      room:useCard(use)
    end
  end,
})

return shenqu
