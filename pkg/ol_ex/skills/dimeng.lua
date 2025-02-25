local U = require("packages.utility.utility")

local this = fk.CreateSkill{
  name = "ol_ex__dimeng",
}

this:addEffect('active', {
    prompt = "#ol_ex__dimeng-active",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if to_select == Self.id or #selected > 1 then return false end
    if #selected == 0 then
      return true
    else
      local x1 = to_select:getHandcardNum()
      local x2 = selected[1]:getHandcardNum()
      return (x1 > 0 or x2 > 0) and math.abs(x1 - x2) <= #Self:getCardIds({Player.Hand, Player.Equip})
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target1 = effect.tos[1]
    local target2 = effect.tos[2]
    U.swapHandCards(room, player, target1, target2, self.name)
    room:addTableMark(player, "ol_ex__dimeng_target-phase", effect.tos)
  end,
})

this:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if not player.dead and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and not player:isNude() then
      local mark = player:getTableMark("ol_ex__dimeng_target-phase")
      for _, tos in ipairs(mark) do
        if type(tos) == "table" and #tos == 2 then
          local p1 = player.room:getPlayerById(tos[1])
          local p2 = player.room:getPlayerById(tos[2])
          if p1 and p2 and not p1.dead and not p2.dead and p1:getHandcardNum() ~= p2:getHandcardNum() then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local x = 0
    local mark = player:getTableMark("ol_ex__dimeng_target-phase")
    if type(mark) ~= "table" then return false end
    for _, tos in ipairs(mark) do
      if type(tos) == "table" and #tos == 2 then
        local p1 = player.room:getPlayerById(tos[1])
        local p2 = player.room:getPlayerById(tos[2])
        if p1 and p2 and not p1.dead and not p2.dead then
          x = x + math.abs(p1:getHandcardNum() - p2:getHandcardNum())
        end
      end
    end
    if x > 0 then
      player.room:askToDiscard(player, { min_num = x, max_num = x, include_equip = true, skill_name = self.name, cancelable = false, pattern = ".", prompt = "#ol_ex__dimeng-discard:::"..x})
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__dimeng"] = "缔盟",
  ["#ol_ex__dimeng_delay"] = "缔盟",
  [":ol_ex__dimeng"] = "出牌阶段限一次，你可选择两名手牌数之差不大于你的牌数的其他角色，这两名角色交换手牌。此阶段结束时，你弃置X张牌（X为这两名角色手牌数之差）。",

  ["#ol_ex__dimeng-active"] = "你是否想要发动“缔盟”，令两名其他角色交换手牌（手牌数之差不大于你的牌数）？",
  ["#ol_ex__dimeng-discard"] = "缔盟：选择%arg张牌弃置",
  
  ["$ol_ex__dimeng1"] = "深知其奇，相与亲结。",
  ["$ol_ex__dimeng2"] = "同盟之人，言归于好。",
}

return this