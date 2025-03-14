local anran_active = fk.CreateSkill{
  name = "anran_active",
}

Fk:loadTranslationTable{
  ["anran_active"] = "岸然",
}

anran_active:addEffect("active", {
  interaction = function(self, player)
    local n = math.min(player:usedSkillTimes("anran", Player.HistoryGame) + 1, 4)
    return UI.ComboBox {choices = {"anran_draw:::"..n, "anran_choose:::"..n}}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if self.interaction.data:startsWith("anran_draw") then
      return false
    else
      return #selected < math.min(player:usedSkillTimes("anran", Player.HistoryGame) + 1, 4)
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if self.interaction.data:startsWith("anran_draw") then
      return #selected == 0
    else
      return #selected > 0 and #selected <= math.min(player:usedSkillTimes("anran", Player.HistoryGame) + 1, 4)
    end
  end,
})

return anran_active
