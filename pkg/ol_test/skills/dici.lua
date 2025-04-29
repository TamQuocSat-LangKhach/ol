local dici = fk.CreateSkill{
  name = "dici",
}

Fk:loadTranslationTable{
  ["dici"] = "抵慈",
  [":dici"] = "出牌阶段限一次，你可以令一名角色交给你一张手牌，然后其回复1点体力并解除连环状态，其相邻角色进入连环状态。“抵慈”角色下次"..
  "进入连环状态后，其选择一项：1.交给你一张手牌；2.你对其造成1点雷电伤害。",

  ["#dici"] = "抵慈：令一名角色交给你一张手牌，其回复1点体力并解除连环状态，其相邻角色进入连环状态",
  ["#dici-ask"] = "抵慈：请交给 %src 一张手牌",
  ["#dici-choice"] = "抵慈：交给 %src 一张手牌，否则其对你造成1点雷电伤害",
  ["@@dici"] = "抵慈",

  ["$dici1"] = "",
  ["$dici2"] = "",
}

dici:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@dici", player.id)
  end
end)

dici:addEffect("active", {
  anim_type = "control",
  prompt = "#dici",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(dici.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = dici.name,
      prompt = "#dici-ask:"..player.id,
      cancelable = false,
    })
    room:obtainCard(player, cards, false, fk.ReasonGive, target, dici.name)
    if target.dead then return end
    if target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = dici.name,
      }
      if target.dead then return end
    end
    if target.chained then
      target:setChainState(false)
      if target.dead then return end
    end
    local tos = table.filter({target:getNextAlive(), target:getLastAlive()}, function (p)
      return not p.chained
    end)
    if #tos > 0 then
      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead and not p.chained then
          p:setChainState(true)
        end
      end
    end
    if not target.dead and not player.dead then
      room:addTableMarkIfNeed(target, "@@dici", player.id)
    end
  end,
})
dici:addEffect(fk.ChainStateChanged, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target.chained and table.contains(target:getTableMark("@@dici"), player.id) and
      not player.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(target, "@@dici", player.id)
    if target:isKongcheng() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = dici.name,
      }
    else
      local cards = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = dici.name,
        prompt = "#dici-choice:"..player.id,
        cancelable = true,
      })
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonGive, target, dici.name)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = dici.name,
        }
      end
    end
  end,
})

return dici
