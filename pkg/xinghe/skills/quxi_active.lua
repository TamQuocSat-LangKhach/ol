local quxi_active = fk.CreateSkill{
  name = "quxi_active",
}

Fk:loadTranslationTable{
  ["quxi_active"] = "驱徙",
}

quxi_active:addEffect("active", {
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected < 2 and to_select ~= player then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return to_select:getHandcardNum() ~= selected[1]:getHandcardNum()
      end
    end
  end,
})

return quxi_active
