local skill = fk.CreateSkill {
  name = "sharing_risk_skill",
}

skill:addEffect("cardskill", {
  prompt = "#sharing_risk_skill",
  can_use = Util.GlobalCanUse,
  on_use = function (self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, true)
  end,
  mod_target_filter = Util.TrueFunc,
  about_to_effect = function(self, room, effect)
    if effect.to.chained then
      return true
    end
  end,
  on_effect = function(self, room, effect)
    if not effect.to.chained and not effect.to.dead then
      effect.to:setChainState(true)
    end
  end,
})

skill:addAI(nil, "__card_skill")
skill:addAI(nil, "default_card_skill")

return skill
