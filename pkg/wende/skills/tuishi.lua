local tuishi = fk.CreateSkill{
  name = "tuishi",
  tags = { Skill.Hidden },
}

Fk:loadTranslationTable{
  ["tuishi"] = "推弑",
  [":tuishi"] = "隐匿技，当你于其他角色的回合内登场后，此回合结束阶段，你可以令其选择一项：1.对其攻击范围内你选择的一名角色使用【杀】；"..
  "2.受到1点伤害。",

  ["#tuishi-choose"] = "推弑：你可以选择一名角色，若 %dest 未对其使用【杀】，你对 %dest 造成1点伤害",
  ["@@tuishi-turn"] = "推弑",
  ["#tuishi-slash"] = "推弑：你需对 %dest 使用【杀】，否则 %src 对你造成1点伤害",

  ["$tuishi1"] = "此僚怀异，召汝讨贼。",
  ["$tuishi2"] = "推令既出，焉敢不从？",
}

tuishi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(tuishi.name) and player:getMark("@@tuishi-turn") > 0 and
      target.phase == Player.Finish and not target.dead and
      table.find(player.room.alive_players, function (p)
        return target:inMyAttackRange(p)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return target:inMyAttackRange(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = tuishi.name,
      prompt = "#tuishi-choose::"..target.id,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local use = room:askToUseCard(target, {
      skill_name = tuishi.name,
      pattern = "slash",
      prompt = "#tuishi-use:"..player.id..":"..to.id,
      extra_data = {
        exclusive_targets = {to.id},
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      room:damage {
        from = player,
        to = target,
        damage = 1,
        skillName = tuishi.name,
      }
    end
  end,
})
local U = require "packages/utility/utility"
tuishi:addEffect(U.GeneralAppeared, {
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(tuishi.name, true) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local to = turn_event.data.who
      if to ~= player and not to.dead then
        return true
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tuishi-turn", 1)
  end,
})

return tuishi
