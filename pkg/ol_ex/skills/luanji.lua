local this = fk.CreateSkill{
  name = "ol_ex__luanji",
}

this:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "archery_attack",
  prompt = "#ol_ex__luanji-viewas",
  handly_pile = true,
  card_filter = function(self, Player, to_select, selected)
    if #selected == 1 then
      return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and Fk:getCardById(to_select).suit == Fk:getCardById(selected[1]).suit
    elseif #selected == 2 then
      return false
    end
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end
    local c = Fk:cloneCard("archery_attack")
    c:addSubcards(cards)
    return c
  end,
})

this:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and data.card.name == "archery_attack" and #data.tos > 0
  end,
  on_cost = function(self, event, target, player, data)
    if #data.tos == 0 then return false end
    local tos = player.room:askToChoosePlayers(player, { targets = data.tos, min_num = 1, max_num = 1,
      prompt = "#ol_ex__luanji-choose", skill_name = "ol_ex__luanji", cancelable = true
    })
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ol_ex__luanji")
    room:notifySkillInvoked(player, "ol_ex__luanji", "control")
    data:removeTarget(self.cost_data)
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__luanji"] = "乱击",
  [":ol_ex__luanji"] = "①你可以将两张花色相同的手牌转化为【万箭齐发】使用。②当你使用【万箭齐发】选择目标后，你可取消其中一个目标。",
  
  ["#ol_ex__luanji-viewas"] = "你是否想要发动“乱击”，将两张花色相同的手牌当【万箭齐发】使用？",
  ["#ol_ex__luanji-choose"] = "乱击：可以为此【万箭齐发】减少一个目标",
  
  ["$ol_ex__luanji1"] = "我的箭支，准备颇多！",
  ["$ol_ex__luanji2"] = "谁都挡不住，我的箭阵！",
}

return this