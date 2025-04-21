local kuangjuan = fk.CreateSkill {
  name = "kuangjuan",
}

Fk:loadTranslationTable{
  ["kuangjuan"] = "狂狷",
  [":kuangjuan"] = "出牌阶段限X次（X为你的体力上限），你可以将手牌数调整至与一名其他角色相同，然后摸你弃置牌数的牌。"..
  "你本回合使用以此法摸的牌无次数限制。",

  ["#kuangjuan"] = "狂狷：选择一名角色，将手牌调整至与其相同",
  ["@@kuangjuan-inhand-turn"] = "狂狷",
}

kuangjuan:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#kuangjuan",
  times = function(self, player)
    return player.phase == Player.Play and player.maxHp - player:usedSkillTimes(kuangjuan.name, Player.HistoryPhase) or -1
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kuangjuan.name, Player.HistoryPhase) < player.maxHp
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0 and player:getHandcardNum() ~= to_select:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = player:getHandcardNum() - target:getHandcardNum()
    if n > 0 then
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = kuangjuan.name,
        cancelable = false,
      })
    elseif n < 0 then
      player:drawCards(-n, kuangjuan.name, nil, "@@kuangjuan-inhand-turn")
    end
  end,
})

kuangjuan:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@kuangjuan-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
})

kuangjuan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and card:getMark("@@kuangjuan-inhand-turn") > 0
  end,
})

return kuangjuan
