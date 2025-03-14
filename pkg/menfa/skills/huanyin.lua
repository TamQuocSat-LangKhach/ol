local huanyin = fk.CreateSkill{
  name = "huanyin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huanyin"] = "还阴",
  [":huanyin"] = "锁定技，当你进入濒死状态时，你将手牌摸至四张。",

  ["$huanyin1"] = "且将此身，还于阴氏。",
  ["$huanyin2"] = "生不得同户，死可葬同穴乎？",
}

huanyin:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huanyin.name) and player:getHandcardNum() < 4
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(4 - player:getHandcardNum(), huanyin.name)
  end,
})

return huanyin
