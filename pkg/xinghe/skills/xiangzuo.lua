local xiangzuo = fk.CreateSkill{
  name = "xiangzuo",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiangzuo"] = "襄胙",
  [":xiangzuo"] = "限定技，当你进入濒死状态时，你可以交给一名其他角色任意张牌，若你对其发动过〖恭节〗和〖相胥〗，你回复等量体力。",

  ["#xiangzuo-invoke"] = "襄胙：你可以将任意张牌交给一名角色，若对其发动过“恭节”和“相胥”，你回复等量体力",
  ["xiangzuo_recover"] = "可回复体力",

  ["$xiangzuo1"] = "怀济沧海之心，徒拔剑而茫然。",
  ["$xiangzuo2"] = "执三尺之青锋，卫大魏之宗庙。",
}

Fk:addTargetTip{
  name = "xiangzuo",
  target_tip = function(self, player, to_select, selected, selected_cards, _, selectable, extra_data)
    if table.contains(extra_data.extra_data or {}, to_select.id) then
      return { { content = "xiangzuo_recover", type = "normal" } }
    end
  end,
}
xiangzuo:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiangzuo.name) and not player:isNude() and
      player:usedSkillTimes(xiangzuo.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 999,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xiangzuo.name,
      prompt = "#xiangzuo-invoke",
      cancelable = true,
      target_tip_name = xiangzuo.name,
      extra_data = table.map(table.filter(room:getOtherPlayers(player, false), function (p)
        return table.contains(player:getTableMark("gongjie_targets"), p.id) and
          table.contains(player:getTableMark("xiangxu_targets"), p.id)
      end), Util.IdMapper),
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = table.simpleClone(event:getCostData(self).cards)
    room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, xiangzuo.name, nil, false, player)
    if player:isWounded() and not player.dead and
      table.contains(player:getTableMark("gongjie_targets"), to.id) and
      table.contains(player:getTableMark("xiangxu_targets"), to.id) then
      room:recover({
        who = player,
        num = #cards,
        recoverBy = player,
        skillName = xiangzuo.name,
      })
    end
  end,
})

return xiangzuo
