local luanwu = fk.CreateSkill {
  name = "ol_ex__luanwu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["ol_ex__luanwu"] = "乱武",
  [":ol_ex__luanwu"] = "限定技，出牌阶段，你可以令所有其他角色依次选择一项：1.对距离最小的另一名角色使用【杀】；2.失去1点体力。"..
  "最后，你可以视为使用一张【杀】。",

  ["#ol_ex__luanwu"] = "乱武：令所有其他角色选择：对距离最近的角色出杀，或失去1点体力",
  ["#ol_ex__luanwu-use"] = "乱武：对距离最近的一名角色使用一张【杀】，否则失去1点体力",
  ["#ol_ex__luanwu-slash"] = "乱武：你可以视为使用一张【杀】",

  ["$ol_ex__luanwu1"] = "一切都在我的掌控中！",
  ["$ol_ex__luanwu2"] = "这乱世还不够乱！",
}

luanwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol_ex__luanwu",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(luanwu.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:doIndicate(player, room:getOtherPlayers(player, false))
    for _, target in ipairs(room:getOtherPlayers(player)) do
      if not target.dead then
        local other_players = table.filter(room:getOtherPlayers(target, false), function(p)
          return not p:isRemoved()
        end)
        local luanwu_targets = table.filter(other_players, function(p2)
          return table.every(other_players, function(p1)
            return target:distanceTo(p1) >= target:distanceTo(p2)
          end)
        end)
        local use = room:askToUseCard(target, {
          skill_name = luanwu.name,
          pattern = "slash",
          prompt = "#ol_ex__luanwu-use",
          cancelable = true,
          extra_data = {
            exclusive_targets = table.map(luanwu_targets, Util.IdMapper),
            bypass_times = true,
          }
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        else
          room:loseHp(target, 1, luanwu.name)
        end
      end
    end
    if player.dead then return end
    room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = luanwu.name,
      prompt = "#ol_ex__luanwu-slash",
      extra_data = {
        extraUse = true,
      }
    })
  end,
})

return luanwu