local bingzheng_active = fk.CreateSkill{
  name = "bingzheng_active",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["bingzheng_active"] = "秉正",
}

bingzheng_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = {"draw1", "bingzheng_discard"} },
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select:getHandcardNum() ~= to_select.hp then
      if self.interaction.data == "draw1" then
        return true
      else
        return not to_select:isKongcheng()
      end
    end
  end,
})

return bingzheng_active
