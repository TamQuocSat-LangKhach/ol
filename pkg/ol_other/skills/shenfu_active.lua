local shenfu_active = fk.CreateSkill{
  name = "shenfu_active",
}

Fk:loadTranslationTable{
  ["shenfu_active"] = "神赋",
}

shenfu_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = {"shenfu_draw", "shenfu_discard"} },
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected == 0 and not table.contains(player:getTableMark("shenfu-phase"), to_select.id) then
      if self.interaction.data == "draw1" then
        return true
      elseif not to_select:isKongcheng() then
        return to_select ~= player or
          table.find(player:getCardIds("h"), function (id)
            return not player:prohibitDiscard(id)
          end)
      end
    end
  end,
})

return shenfu_active
