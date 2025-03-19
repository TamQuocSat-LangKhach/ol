local guanbian = fk.CreateSkill{
  name = "guanbian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guanbian"] = "观变",
  [":guanbian"] = "锁定技，游戏开始时，你的手牌上限、其他角色与你的距离、你与其他角色的距离+X。首轮结束后或你发动〖凶逆〗或〖封赏〗后，"..
  "你失去此技能。（X为游戏人数）",

  ["@guanbian-round"] = "观变",

  ["$guanbian1"] = "今日，老夫也想尝尝这鹿血的滋味！",
  ["$guanbian2"] = "这水搅得越浑，这鱼便越好捉。",
}

guanbian:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@guanbian-round", 0)
end)

guanbian:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guanbian.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@guanbian-round", #room.players)
  end,
})
guanbian:addEffect(fk.RoundEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guanbian.name)
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-guanbian")
  end,
})
guanbian:addEffect(fk.AfterSkillEffect, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guanbian.name) and
      (data.skill.name == "xiongni" or data.skill.name == "fengshang")
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-guanbian")
  end,
})
guanbian:addEffect("distance", {
  correct_func = function(self, from, to)
    return from:getMark("@guanbian-round") + to:getMark("@guanbian-round")
  end,
})
guanbian:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("@guanbian-round")
  end,
})

return guanbian
