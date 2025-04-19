local hedao = fk.CreateSkill{
  name = "hedao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hedao"] = "合道",
  [":hedao"] = "锁定技，游戏开始时，你可以至多拥有两册<a href='tianshu_href'>“天书”</a>。你的首次濒死结算后，你可以至多拥有三册"..
  "<a href='tianshu_href'>“天书”</a>。",

  ["$hedao1"] = "不参黄泉，难悟大道。",
  ["$hedao2"] = "道者，亦置之死地而后生。",
  ["$hedao3"] = "因果开茅塞，轮回似醍醐。",
}

hedao:addEffect(fk.AfterDying, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hedao.name) and player:getMark("hedao_invoked") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "hedao_invoked", 1)
    room:setPlayerMark(player, "tianshu_max", 2)
  end,
})

hedao:addEffect(fk.GameStart, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(hedao.name)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "tianshu_max", 1)
  end,
})

return hedao
