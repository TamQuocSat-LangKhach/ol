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
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = suji.name,
      prompt = "#suji-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      card_filter = {
        n = 1,
        pattern = ".|.|spade,club",
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
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
