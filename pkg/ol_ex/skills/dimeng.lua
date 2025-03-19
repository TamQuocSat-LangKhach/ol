
local dimeng = fk.CreateSkill{
  name = "ol_ex__dimeng",
}

Fk:loadTranslationTable {
  ["ol_ex__dimeng"] = "缔盟",
  [":ol_ex__dimeng"] = "出牌阶段限一次，你可以选择两名手牌数之差不大于你的牌数的其他角色，这两名角色交换手牌。此阶段结束时，你弃置X张牌"..
  "（X为这两名角色手牌数之差）。",

  ["#ol_ex__dimeng"] = "缔盟：令两名其他角色交换手牌（手牌数之差不大于你的牌数）",

  ["$ol_ex__dimeng1"] = "深知其奇，相与亲结。",
  ["$ol_ex__dimeng2"] = "同盟之人，言归于好。",
}

dimeng:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_ex__dimeng",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(dimeng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if to_select == player or #selected > 1 then return false end
    if #selected == 0 then
      return true
    else
      local x1 = to_select:getHandcardNum()
      local x2 = selected[1]:getHandcardNum()
      return (x1 > 0 or x2 > 0) and math.abs(x1 - x2) <= #player:getCardIds("he")
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "ol_ex__dimeng_target-phase", table.map(effect.tos, Util.IdMapper))
    local target1 = effect.tos[1]
    local target2 = effect.tos[2]
    room:swapAllCards(player, {target1, target2}, dimeng.name)
  end,
})

dimeng:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and player:usedSkillTimes(dimeng.name, Player.HistoryPhase) > 0 and not player:isNude() then
      for _, info in ipairs(player:getTableMark("ol_ex__dimeng_target-phase")) do
        local to1, to2 = player.room:getPlayerById(info[1]), player.room:getPlayerById(info[2])
        if not to1.dead and not to2.dead and to1:getHandcardNum() ~= to2:getHandcardNum() then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    for _, info in ipairs(player:getTableMark("ol_ex__dimeng_target-phase")) do
      local to1, to2 = room:getPlayerById(info[1]), room:getPlayerById(info[2])
      if not to1.dead and not to2.dead and to1:getHandcardNum() ~= to2:getHandcardNum() then
        x = x + math.abs(to1:getHandcardNum() - to2:getHandcardNum())
      end
    end
    if x > 0 then
      room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = dimeng.name,
        cancelable = false,
      })
    end
  end,
})

return dimeng
