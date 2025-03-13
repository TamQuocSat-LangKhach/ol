local chunqiu = fk.CreateSkill{
  name = "qin__chunqiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__chunqiu"] = "春秋",
  [":qin__chunqiu"] = "锁定技，每回合限一次，当你使用或打出牌时，你摸一张牌。",

  ["$qin__chunqiu"] = "吕氏春秋，举世之著作！",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chunqiu.name) and
      player:usedSkillTimes(chunqiu.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, chunqiu.name)
  end,
}

chunqiu:addEffect(fk.CardUsing, spec)
chunqiu:addEffect(fk.CardResponding, spec)

return chunqiu
