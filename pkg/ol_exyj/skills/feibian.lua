local feibian = fk.CreateSkill {
  name = "feibian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["feibian"] = "飞辩",
  [":feibian"] = "锁定技，游戏开始时，你的出牌时间改为15秒。当你于回合内使用一张牌后，或当其他角色对你使用一张牌后，使用者"..
  "随机弃置一张手牌且本轮出牌时间减1秒（最少为1秒）。每个回合结束时，本回合出牌超时的角色失去1点体力。",
}

feibian:addEffect(fk.AfterAskForCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(feibian.name)
  end,
  on_refresh = function (self, event, target, player, data)
  end,
})

return feibian
