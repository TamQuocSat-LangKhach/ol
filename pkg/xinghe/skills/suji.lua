local suji = fk.CreateSkill{
  name = "suji",
}

Fk:loadTranslationTable{
  ["suji"] = "肃疾",
  [":suji"] = "已受伤角色的出牌阶段开始时，你可以将一张黑色牌当【杀】使用，若其受到此【杀】伤害，你获得其一张牌。",

  ["#suji-invoke"] = "肃疾：你可以将一张黑色牌当【杀】使用，若对 %dest 造成伤害，你获得其一张牌",

  ["$suji1"] = "飞燕如风，非快不得破。",
  ["$suji2"] = "载疾风之势，摧万仞之城。",
}

suji:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(suji.name) and target.phase == Player.Play and target:isWounded()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "suji_viewas",
      prompt = "#suji-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
    })
    if success and dat then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(self).extra_data)
    local card = Fk:cloneCard("slash")
    card.skillName = suji.name
    card:addSubcards(dat.cards)
    local use = {
      from = player,
      tos = dat.targets,
      card = card,
      extraUse = true,
    }
    room:useCard(use)
    if use.damageDealt and use.damageDealt[target] and not player.dead and not target:isNude() and not target.dead then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = suji.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, suji.name)
    end
  end,
})

return suji
