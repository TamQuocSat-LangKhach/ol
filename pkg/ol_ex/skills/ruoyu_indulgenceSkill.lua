local orig_indulgence_skill = Fk.skills["indulgence_skill"]

local this = fk.CreateSkill {
  name = "trans__indulgence_skill",
}

this:addEffect("active", {
  mod_target_filter = orig_indulgence_skill.modTargetFilter,
  target_filter = orig_indulgence_skill.targetFilter,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = effect.to
    local judge = {
      who = to,
      reason = "indulgence",
      pattern = ".|.|heart",
    }
    room:judge(judge)
    local result = judge.card
    if result.suit == Card.Heart then
      to:skip(Player.Play)
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse
    }
  end,
})

Fk:loadTranslationTable {
  ["trans__indulgence_skill"] = "乐不思蜀"
}

return this