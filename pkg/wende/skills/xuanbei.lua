local xuanbei = fk.CreateSkill{
  name = "xuanbei",
}

Fk:loadTranslationTable{
  ["xuanbei"] = "选备",
  [":xuanbei"] = "出牌阶段限一次，你可以选择一名其他角色区域内的一张牌，令其将此牌当无距离限制的【杀】对你使用，若此【杀】未对你造成伤害，"..
  "你摸一张牌，否则你摸两张牌。",

  ["#xuanbei"] = "选备：选择一名角色，将其区域内一张牌当【杀】对你使用",

  ["$xuanbei1"] = "博选良家，以充后宫。",
  ["$xuanbei2"] = "非良家，不可选也。",
}

xuanbei:addEffect("active", {
  anim_type = "control",
  prompt = "#xuanbei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xuanbei.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "hej",
      skill_name = xuanbei.name,
    })
    local card = Fk:cloneCard("slash")
    card:addSubcard(id)
    local num = 1
    if target:canUseTo(card, player, {bypass_distances = true, bypass_times = true}) then
      local use = {
        from = target,
        tos = {player},
        card = card,
        skillName = xuanbei.name,
        extraUse = true,
      }
      room:useCard(use)
      if use.damageDealt and use.damageDealt[player] then
        num = 2
      end
    end
    if not player.dead then
      player:drawCards(num, xuanbei.name)
    end
  end,
})

return xuanbei
