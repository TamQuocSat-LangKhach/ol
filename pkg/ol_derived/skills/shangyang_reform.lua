local skill = fk.CreateSkill {
  name = "shangyang_reform_skill",
}

Fk:loadTranslationTable{
  ["shangyang_reform_skill"] = "商鞅变法",
  ["#shangyang_reform_skill"] = "选择一名角色，对其造成随机1~2点伤害，若其进入濒死状态且你判定为♠，除其以外的角色不能对其使用【桃】",
}

skill:addEffect("cardskill", {
  prompt = "#shangyang_reform_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    room:damage{
      from = player,
      to = target,
      card = effect.card,
      damage = math.random(2),
      skillName = skill.name,
    }
  end,
})
skill:addEffect(fk.EnterDying, {
  mute = true,
  is_delay_effect = true,
  global = true,
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.card and data.damage.card.name == "shangyang_reform" and
      data.damage.from == player and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = skill.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.extra_data = data.extra_data or {}
      data.extra_data.shangyangReform = true
    end
  end,
})
skill:addEffect("prohibit", {
  global = true,
  prohibit_use = function(self, player, card)
    if card and card.name == "peach" and not player.dying then
      if RoomInstance and RoomInstance.logic:getCurrentEvent().event == GameEvent.Dying then
        local data = RoomInstance.logic:getCurrentEvent().data
        return data and data.extra_data and data.extra_data.shangyangReform
      end
    end
  end,
})

return skill
