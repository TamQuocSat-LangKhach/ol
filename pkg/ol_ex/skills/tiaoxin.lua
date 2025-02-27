local tiaoxin = fk.CreateSkill {
  name = "ol_ex__tiaoxin",
}

Fk:loadTranslationTable {
  ["ol_ex__tiaoxin"] = "挑衅",
  [":ol_ex__tiaoxin"] = "出牌阶段限一次，你可以选择一名攻击范围内含有你的角色，然后除非该角色对你使用一张【杀】且你受到此【杀】的伤害，"..
  "否则你弃置其一张牌，然后本阶段本技能限两次。",

  ["#ol_ex__tiaoxin"] = "挑衅：令一名角色对你使用一张【杀】且造成伤害，否则你弃置其一张牌",
  ["#ol_ex__tiaoxin-use"] = "挑衅：对 %src 使用一张【杀】，否则其弃置你一张牌",

  ["$ol_ex__tiaoxin1"] = "会闻用师，观衅而动。",
  ["$ol_ex__tiaoxin2"] = "宜乘其衅会，以挑敌将。",
}

tiaoxin:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_ex__tiaoxin",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(tiaoxin.name, Player.HistoryPhase) < (1 + player:getMark("ol_ex__tiaoxin_extra-phase"))
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:inMyAttackRange(player)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local use = room:askToUseCard(target, {
      skill_name = tiaoxin.name,
      pattern = "slash",
      prompt = "#ol_ex__tiaoxin-use:"..player.id,
      extra_data = {
        exclusive_targets = {player.id},
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    end
    if not (use and use.damageDealt and use.damageDealt[player]) then
      room:setPlayerMark(player, "ol_ex__tiaoxin_extra-phase", 1)
      if not target:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          skill_name = tiaoxin.name,
          flag = "he",
        })
        room:throwCard(card, tiaoxin.name, target, player)
      end
    end
  end,
})

return tiaoxin