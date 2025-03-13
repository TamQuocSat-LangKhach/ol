local wuma = fk.CreateSkill{
  name = "shengxiao_wuma",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shengxiao_wuma"] = "午马",
  [":shengxiao_wuma"] = "锁定技，你不能被翻面。你的阶段不能被跳过。当你成为其他角色使用锦囊牌的目标后，你摸一张牌。",
}

wuma:addEffect(fk.BeforeTurnOver, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wuma.name) and player.faceup
  end,
  on_use = Util.TrueFunc,
})
wuma:addEffect(fk.EventPhaseSkipping, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wuma.name)
  end,
  on_use = function (self, event, target, player, data)
    data.skipped = true
  end,
})
wuma:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wuma.name) and
      data.card.type == Card.TypeTrick and data.from ~= player
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, wuma.name)
  end,
})

return wuma
