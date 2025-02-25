local this = fk.CreateSkill {
  name = "ol_ex__luanwu"
}

this:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol_ex__luanwu-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(this.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = room:getOtherPlayers(player)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, target in ipairs(targets) do
      if not target.dead then
        if target:isRemoved() then
          room:loseHp(target, 1, this.name)
        else
          local other_players = table.filter(room.alive_players, function (p)
            return p ~= target and not p:isRemoved()
          end)
          local luanwu_targets = table.map(table.filter(other_players, function(p2)
            return table.every(other_players, function(p1)
              return target:distanceTo(p1) >= target:distanceTo(p2)
            end)
          end), Util.IdMapper)
          local use = room:askToUseCard(target, { pattern = "slash", prompt = "#ol_ex__luanwu-use", cancelable = true, extra_data = { exclusive_targets = luanwu_targets, bypass_times = true} })
          if use then
            use.extraUse = true
            room:useCard(use)
          else
            room:loseHp(target, 1, this.name)
          end
        end
      end
    end
    if player.dead then return end
    local slash = Fk:cloneCard("slash")
    if player:prohibitUse(slash) then return end
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local slash_targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if not player:isProhibited(p, slash) then
        table.insert(slash_targets, p.id)
      end
    end
    if #slash_targets == 0 or max_num == 0 then return end
    local tos = room:askToChoosePlayers(player, { targets = slash_targets, min_num = 1, max_num = max_num, prompt = "#ol_ex__luanwu-choose", skill_name = this.name, no_indicate = true})
    if #tos > 0 then
      room:useVirtualCard("slash", nil, player, table.map(tos, Util.Id2PlayerMapper), this.name, true)
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__luanwu"] = "乱武",
  [":ol_ex__luanwu"] = "限定技，出牌阶段，你可选择所有其他角色，这些角色各需对包括距离最小的另一名角色在内的角色使用【杀】，否则失去1点体力。最后你可视为使用普【杀】。",

  ["#ol_ex__luanwu-active"] = "你是否想要发动“乱武”，令所有其他角色选择：对距离最近的角色出杀，或失去1点体力？",
  ["#ol_ex__luanwu-use"] = "乱武：对距离最近的一名角色使用一张【杀】，否则失去1点体力",
  ["#ol_ex__luanwu-choose"] = "乱武：可以视为使用一张【杀】，选择此【杀】的目标",
  
  ["$ol_ex__luanwu1"] = "一切都在我的掌控中！",
  ["$ol_ex__luanwu2"] = "这乱世还不够乱！",
}

return this