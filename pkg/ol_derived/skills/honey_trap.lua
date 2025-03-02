local skill = fk.CreateSkill {
  name = "honey_trap_skill",
}

Fk:loadTranslationTable{
  ["honey_trap_skill"] = "美人计",
  ["#honey_trap_skill"] = "选择一名男性角色，所有女性角色获得其一张手牌并交给你一张手牌，你与目标手牌数少的一方对对方造成伤害",
  ["#honey_trap-ask"] = "美人计：请将一张手牌交给 %src",
}

skill:addEffect("cardskill", {
  prompt = "#honey_trap_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player and to_select:isMale() and not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    local female = table.filter(room:getAlivePlayers(), function(p)
      return p:isFemale()
    end)
    if #female > 0 then
      for _, p in ipairs(female) do
        if target:isKongcheng() or target.dead then break end
        local id = room:askToChooseCard(p, {
          target = target,
          flag = "h",
          skill_name = skill.name,
        })
        room:obtainCard(p, id, false, fk.ReasonPrey, p, skill.name)
        if not player.dead and not p:isKongcheng() and p ~= player then
          local card = room:askToCards(p, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            skill_name = skill.name,
            prompt = "#honey_trap-ask:"..player.id,
            cancelable = false,
          })
          room:obtainCard(player, card, false, fk.ReasonGive, p, skill.name)
        end
      end
    end
    local from, to = player, target
    if player:getHandcardNum() == target:getHandcardNum() then
      return
    elseif player:getHandcardNum() > target:getHandcardNum() then
      from, to = target, player
    end
    if not to.dead then
      room:damage{
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return skill
