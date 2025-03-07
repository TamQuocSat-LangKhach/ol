local zhidao = fk.CreateSkill{
  name = "zhidao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhidao"] = "雉盗",
  [":zhidao"] = "锁定技，每回合限一次，当你于出牌阶段对区域内有牌的其他角色造成伤害后，你获得其每个区域各一张牌，"..
  "然后你使用牌不能指定其他角色为目标直到回合结束。",

  ["$zhidao1"] = "谁有地盘，谁是老大！",
  ["$zhidao2"] = "乱世之中，能者为王！",
}

local U = require "packages/utility/utility"

zhidao:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhidao.name) and player.phase == Player.Play and
      data.to ~= player and not data.to.dead and not data.to:isAllNude() and
      player:usedSkillTimes(zhidao.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.to}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = U.askforCardsChosenFromAreas(player, data.to, "hej", zhidao.name, nil, nil, false)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, zhidao.name, nil, false, player)
  end,
})
zhidao:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from:usedSkillTimes(zhidao.name, Player.HistoryTurn) > 0 and card and from ~= to
  end,
})

return zhidao
