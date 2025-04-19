local tianshu_active = fk.CreateSkill{
  name = "tianshu_active",
}

Fk:loadTranslationTable{
  ["tianshu_active"] = "天书",
}

tianshu_active:addEffect("active", {
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected < 2 then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        local area = self.tianshu28
        return #selected[1]:getCardIds(area) > 0 or #to_select:getCardIds(area) > 0
      end
    end
  end,
})

return tianshu_active
