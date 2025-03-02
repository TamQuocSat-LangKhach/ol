local weikui = fk.CreateSkill{
  name = "weikui",
}

Fk:loadTranslationTable{
  ["weikui"] = "伪溃",
  [":weikui"] = "出牌阶段限一次，你可以失去1点体力并选择一名有手牌的其他角色观看其手牌：若其手牌中有【闪】，则视为你对其使用一张"..
  "不计入次数限制的【杀】，且本回合你计算与其的距离视为1；若其手牌中没有【闪】，你弃置其中一张牌。",

  ["#weikui"] = "伪溃：失去1点体力观看一名角色手牌，根据有无【闪】视为对其使用【杀】或弃置其牌",
  ["#weikui-discard"] = "伪溃：弃置 %dest 一张手牌",

  ["$weikui1"] = "骑兵列队，准备突围。",
  ["$weikui2"] = "休整片刻，且随我杀出一条血路。",
}

local U = require "packages/utility/utility"

weikui:addEffect("active", {
  anim_type = "offensive",
  prompt = "#weikui",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(weikui.name, Player.HistoryPhase) == 0 and player.hp > 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:loseHp(player, 1, weikui.name)
    if player.dead or target.dead or target:isKongcheng() then return end
    if table.find(target:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "jink"
    end) then
      U.viewCards(player, target:getCardIds("h"), weikui.name, "#ViewCardsFrom:"..target.id)
      room:addTableMark(player, "weikui-turn", target.id)
      room:useVirtualCard("slash", nil, player, target, weikui.name, true)
    else
      local card = room:askToChooseCard(player, {
        target = target,
        flag = { card_data = { { "$Hand", target:getCardIds("h") } } },
        skill_name = weikui.name,
        prompt = "#weikui-discard::"..target.id,
      })
      room:throwCard(card, weikui.name, target, player)
    end
  end,
})
weikui:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("weikui-turn"), to.id) then
      return 1
    end
  end,
})

return weikui
