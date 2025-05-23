local juewei_active = fk.CreateSkill {
  name = "juewei_active",
}

Fk:loadTranslationTable{
  ["juewei_active"] = "绝围",
  ["juewei_recast"] = "重铸一张装备，此牌结算后可以视为使用之",
  ["juewei_discard"] = "弃置一张装备，此牌无效",
}

juewei_active:addEffect("active", {
  interaction = UI.ComboBox { choices = { "juewei_recast", "juewei_discard" }},
  card_num = 1,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip then
      if self.interaction.data == "juewei_recast" then
        return true
      else
        return not player:prohibitDiscard(to_select)
      end
    end
  end
})

return juewei_active
