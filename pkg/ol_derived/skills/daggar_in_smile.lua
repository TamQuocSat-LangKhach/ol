local skill = fk.CreateSkill {
  name = "daggar_in_smile_skill",
}

Fk:loadTranslationTable{
  ["daggar_in_smile_skill"] = "笑里藏刀",
  ["#daggar_in_smile_skill"] = "选择一名角色，其摸已损失体力值的牌（至多五张），然后你对其造成伤害",
}

skill:addEffect("cardskill", {
  prompt = "#daggar_in_smile_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if target:isWounded() then
      target:drawCards(math.min(target:getLostHp(), 5), skill.name)
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return skill
