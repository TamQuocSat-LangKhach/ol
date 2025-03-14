local caishi = fk.CreateSkill{
  name = "ol__caishi",
}

Fk:loadTranslationTable{
  ["ol__caishi"] = "才识",
  [":ol__caishi"] = "摸牌阶段开始时，你可以选择一项：1.手牌上限+1；2.回复1点体力，本回合你不能对自己使用牌。",

  ["ol__caishi_maxcards"] = "手牌上限+1",
  ["ol__caishi_recover"] = "回复1点体力，本回合不能对自己用牌",

  ["$ol__caishi1"] = "才学雅量，识古通今。",
  ["$ol__caishi2"] = "女子才智，自当有男子不及之处。",
}

caishi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caishi.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"ol__caishi_maxcards", "ol__caishi_recover", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if not player:isWounded() then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = caishi.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "ol__caishi_maxcards" then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      room:recover{
        who = player,
        num = 1,
        skillName = caishi.name,
      }
      if not player.dead then
        room:setPlayerMark(player, "ol__caishi-turn", 1)
      end
    end
  end,
})
caishi:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and from:getMark("ol__caishi-turn") > 0 and from == to
  end,
})

return caishi
