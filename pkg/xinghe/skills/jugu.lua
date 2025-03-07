local jugu = fk.CreateSkill{
  name = "jugu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jugu"] = "巨贾",
  [":jugu"] = "锁定技，你的手牌上限+X；游戏开始时，你摸X张牌。（X为你的体力上限）",

  ["$jugu1"] = "钱？要多少有多少。",
  ["$jugu2"] = "君子爱财，取之有道。",
}

jugu:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jugu.name)
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player.maxHp, jugu.name)
  end,
})
jugu:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(jugu.name) then
      return player.maxHp
    end
  end,
})

return jugu
