local chongxin = fk.CreateSkill{
  name = "chongxin",
}

Fk:loadTranslationTable{
  ["chongxin"] = "崇信",
  [":chongxin"] = "出牌阶段限一次，你可以令一名有手牌的其他角色与你各重铸一张牌。",

  ["#chongxin"] = "崇信：与一名有手牌的其他角色各重铸一张牌",
  ["#chongxin-ask"] = "崇信：请重铸一张牌",

  ["$chongxin1"] = "非诚不行，无信不立。",
  ["$chongxin2"] = "以诚待人，可得其心。",
}

chongxin:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#chongxin",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(chongxin.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chongxin.name,
      prompt = "#chongxin-ask",
      cancelable = false,
    })
    room:recastCard(card, player, chongxin.name)
    if not (target.dead or target:isNude()) then
      card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chongxin.name,
      prompt = "#chongxin-ask",
      cancelable = false,
    })
      room:recastCard(card, target, chongxin.name)
    end
  end,
})

return chongxin
