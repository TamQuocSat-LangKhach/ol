local skill = fk.CreateSkill {
  name = "trans__indulgence_skill",
}

Fk:loadTranslationTable {
  ["trans__indulgence_skill"] = "乐不思蜀"
}

skill:addEffect("cardskill", {
  prompt = "#indulgence_skill",
  can_use = Util.CanUse,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = effect.to
    local judge = {
      who = to,
      reason = "indulgence",
      pattern = ".|.|heart",
    }
    room:judge(judge)
    if judge:matchPattern() then
      to:skip(Player.Play)
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse,
    }
  end,
})

return skill