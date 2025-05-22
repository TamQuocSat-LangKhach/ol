local aichen = fk.CreateSkill{
  name = "aichen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["aichen"] = "哀尘",
  [":aichen"] = "锁定技，当你进入濒死状态时，若〖落宠〗选项数大于1，你移除其中一项。",

  ["#aichen-choice"] = "哀尘：移除一种“落宠”选项",

  ["$aichen1"] = "泪干红落面，心结发垂头。",  --泪干红落脸，心尽白垂头。
  ["$aichen2"] = "思君一叹息，苦泪无言垂。",  --思君一叹息，苦泪应言垂。
}

aichen:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aichen.name) and player:hasSkill("luochong", true) and
      #player:getTableMark("luochong_removed") < 4
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.filter({1, 2, 3, 4}, function (n)
      return not table.contains(player:getTableMark("luochong_removed"), n)
    end)
    choices = table.map(choices, function (n)
      return "luochong"..n
    end)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = aichen.name,
      prompt = "#aichen-choice",
    })
    room:addTableMark(player, "luochong_removed", tonumber(choice[9]))
  end,
})

return aichen
