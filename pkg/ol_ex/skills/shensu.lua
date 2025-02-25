local this = fk.CreateSkill { name = "ol_ex__shensu" }

this:addEffect(fk.EventPhaseChanging, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(this.name) and not player:prohibitUse(Fk:cloneCard("slash")) then
      if (data.to == Player.Judge and not player.skipped_phases[Player.Draw]) or data.to == Player.Discard then
        return true
      elseif data.to == Player.Play then
        return not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if player ~= p and not player:isProhibited(p, slash) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 or max_num == 0 then return end
    if data.to == Player.Judge then
      local tos = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = max_num, prompt = "#ol_ex__shensu1-choose", skill_name = this.name, cancelable = true})
      if #tos > 0 then
        self.cost_data = {tos}
        return true
      end
    elseif data.to == Player.Play then
      local tos, id = room:askToChooseCardAndPlayers(player, { targets = targets, min_num = 1, max_num = max_num, pattern = ".|.|.|.|.|equip", prompt = "#ol_ex__shensu2-choose", skill_name = this.name, cancelable = true})
      if #tos > 0 and id then
        self.cost_data = {tos, {id}}
        return true
      end
    elseif data.to == Player.Discard then
      local tos = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = max_num, prompt = "#ol_ex__shensu3-choose", skill_name = this.name, cancelable = true})
      if #tos > 0 then
        self.cost_data = {tos}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.to == Player.Judge then
      player:skip(Player.Judge)
      player:skip(Player.Draw)
    elseif data.to == Player.Play then
      player:skip(Player.Play)
      room:throwCard(self.cost_data[2], this.name, player, player)
    elseif data.to == Player.Discard then
      player:skip(Player.Discard)
      player:turnOver()
    end

    local slash = Fk:cloneCard("slash")
    slash.skillName = this.name
    room:useCard({
      from = target.id,
      tos = table.map(self.cost_data[1], function(pid) return { pid } end),
      card = slash,
      extraUse = true,
    })
    return true
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__shensu"] = "神速",
  [":ol_ex__shensu"] = "①判定阶段开始前，你可跳过此阶段和摸牌阶段来视为使用普【杀】。②出牌阶段开始前，你可跳过此阶段并弃置一张装备牌来视为使用普【杀】。③弃牌阶段开始前，你可跳过此阶段并翻面来视为使用普【杀】。",
  
  ["#ol_ex__shensu1-choose"] = "神速：你可以跳过判定阶段和摸牌阶段，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shensu2-choose"] = "神速：你可以跳过出牌阶段并弃置一张装备牌，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shensu3-choose"] = "神速：你可以跳过弃牌阶段并翻面，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shebian-choose"] = "设变：你可以移动场上的一张装备牌",
  
  ["$ol_ex__shensu1"] = "奔逸绝尘，不留踪影！",
  ["$ol_ex__shensu2"] = "健步如飞，破敌不备！",
}

return this
