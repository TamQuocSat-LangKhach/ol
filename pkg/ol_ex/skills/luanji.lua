local luanji = fk.CreateSkill{
  name = "ol_ex__luanji",
}

Fk:loadTranslationTable{
  ["ol_ex__luanji"] = "乱击",
  [":ol_ex__luanji"] = "你可以将两张花色相同的手牌当为【万箭齐发】使用；当你使用【万箭齐发】选择目标后，你可取消其中一个目标。",

  ["#ol_ex__luanji"] = "乱击：你可以将两张花色相同的手牌当【万箭齐发】使用",
  ["#ol_ex__luanji-choose"] = "乱击：你可以为此%arg减少一个目标",

  ["$ol_ex__luanji1"] = "我的箭支，准备颇多！",
  ["$ol_ex__luanji2"] = "谁都挡不住，我的箭阵！",
}

luanji:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "archery_attack",
  prompt = "#ol_ex__luanji",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected < 2 and table.contains(player:getCardIds("h"), to_select) then
      if #selected == 0 then
        return Fk:getCardById(to_select).suit ~= Card.NoSuit
      elseif #selected == 1 then
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]))
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local c = Fk:cloneCard("archery_attack")
    c.skillName = luanji.name
    c:addSubcards(cards)
    return c
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

luanji:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(luanji.name) and data.card.name == "archery_attack" and #data.tos > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data.tos,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__luanji-choose:::"..data.card:toLogString(),
      skill_name = "ol_ex__luanji",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:removeTarget(event:getCostData(self).tos[1])
  end,
})

return luanji