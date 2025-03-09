local zhuyan_active = fk.CreateSkill{
  name = "zhuyan_active",
}

Fk:loadTranslationTable{
  ["zhuyan_active"] = "驻颜",
  ["#zhuyan_tip1"] = "体力%arg",
  ["#zhuyan_tip2"] = "手牌%arg",
  ["zhuyan_hp"] = "体力值",
  ["zhuyan_handcard"] = "手牌数",
}

zhuyan_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox {choices = {"zhuyan_hp", "zhuyan_handcard"}},
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    return #to_select:getTableMark("zhuyan") == 2 and
      not table.contains(player:getTableMark(self.interaction.data), to_select.id)
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    local mark = to_select:getTableMark("zhuyan")
    if #mark == 2 then
      local ret1, ret2
      if not table.contains(player:getTableMark("zhuyan_hp"), to_select.id) then
        local sig = ""
        local n = to_select:getMark("zhuyan")[1] - to_select.hp
        if n > 0 then
          sig = "+"
        end
        ret1 = sig..tostring(n)
      end
      if not table.contains(player:getTableMark("zhuyan_handcard"), to_select.id) then
        local sig = ""
        local n = to_select:getMark("zhuyan")[2] - to_select:getHandcardNum()
        if n > 0 then
          sig = "+"
        end
        ret2 = sig..tostring(n)
      end
      local ret = {}
      if ret1 then
        table.insert(ret, {
          content = "#zhuyan_tip1:::"..ret1,
          type = "normal",
        })
      end
      if ret2 then
        table.insert(ret, {
          content = "#zhuyan_tip2:::"..ret2,
          type = "normal",
        })
      end
      return ret
    end
  end,
})

return zhuyan_active
