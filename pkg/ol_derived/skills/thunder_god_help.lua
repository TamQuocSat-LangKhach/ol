local skill = fk.CreateSkill {
  name = "thunder_god_help_skill",
}

skill:addEffect("cardskill", {
  prompt = "#thunder_god_help_skill",
  can_use = Util.GlobalCanUse,
  on_use = function (self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, true)
  end,
  mod_target_filter = Util.TrueFunc,
  on_action = function(self, room, use, finished)
    if finished and not use.from.dead then
      local n = 0
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event then
        use_event:searchEvents(GameEvent.Damage, 1, function (e)
          local damage = e.data
          if damage.skillName == "lightning_skill" and not damage.prevented and not damage.chain and
            e:findParent(GameEvent.UseCard, true) == use_event then
            n = n + 1
          end
        end)
        if n > 0 then
          use.from:drawCards(n, skill.name)
        end
      end
    end
  end,
  on_effect = function(self, room, effect)
    local judge = {
      who = effect.to,
      reason = "lightning",
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    if judge:matchPattern() and not effect.to.dead then
      room:damage{
        to = effect.to,
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = "lightning_skill",
        card = effect.card,
      }
    end
  end,
})

return skill
