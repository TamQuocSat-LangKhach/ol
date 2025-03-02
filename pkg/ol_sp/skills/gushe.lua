local gushe = fk.CreateSkill{
  name = "gushe",
}

Fk:loadTranslationTable{
  ["gushe"] = "鼓舌",
  [":gushe"] = "出牌阶段限一次，你可以用一张手牌与至多三名角色同时拼点，然后依次结算拼点结果，没赢的角色选择一项：1.弃置一张牌；2.令你摸一张牌。"..
  "若拼点没赢的角色是你，你需先获得一个“饶舌”标记（你有7个饶舌标记时，你死亡）。",

  ["@raoshe"] = "饶舌",
  ["#gushe"] = "鼓舌：你可以与至多三名角色同时拼点",
  ["#gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %dest 摸一张牌",

  ["$gushe1"] = "公既知天命，识时务，为何要兴无名之师，犯我疆界？",
  ["$gushe2"] = "你若倒戈卸甲，以礼来降，仍不失封侯之位，国安民乐，岂不美哉？",
}

gushe:addEffect("active", {
  anim_type = "control",
  prompt = "#gushe",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(gushe.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 3 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local pindian = player:pindian(effect.tos, gushe.name)
    for _, target in ipairs(effect.tos) do
      local losers = {}
      if pindian.results[target].winner then
        if pindian.results[target].winner == player then
          table.insert(losers, target)
        else
          table.insert(losers, player)
        end
      else
        table.insert(losers, player)
        table.insert(losers, target)
      end
      for _, p in ipairs(losers) do
        if p == player and not player.dead then
          room:addPlayerMark(player, "@raoshe", 1)
          if player:getMark("@raoshe") >= 7 then
            room:killPlayer({
              who = player,
            })
          end
        end
        if p:isNude() or p.dead or
          #room:askToDiscard(p, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = gushe.name,
            prompt = "#gushe-discard::"..player.id,
            cancelable = player.dead,
          }) == 0 then
          if not player.dead then
            player:drawCards(1, gushe.name)
          end
        end
      end
    end
  end,
})

return gushe
