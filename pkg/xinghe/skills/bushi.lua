local bushi = fk.CreateSkill{
  name = "bushi",
}

Fk:loadTranslationTable{
  ["bushi"] = "布施",
  [":bushi"] = "当你受到1点伤害，或当一名角色受到你造成的1点伤害后，受到伤害的角色可以获得一张“米”。",

  ["#bushi-invoke"] = "布施：你可以获得 %src 的一张“米”",

  ["$bushi1"] = "布施行善，乃道义之本。",
  ["$bushi2"] = "行布施，得天道。",
}

bushi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(bushi.name) and #player:getPile("zhanglu_mi") > 0 and
      (target == player or (data.from == player and not target.dead))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(target, {
      skill_name = bushi.name,
      prompt = "#bushi-invoke:"..player.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("zhanglu_mi")
    if #cards > 1 then
      cards = room:askToChooseCard(target, {
        target = target,
        flag = { card_data = {{ "zhanglu_mi", cards }} },
        skill_name = bushi.name,
      })
    end
    room:obtainCard(target, cards, true, fk.ReasonJustMove, target, bushi.name)
  end,
})

return bushi
