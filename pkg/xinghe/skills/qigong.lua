local qigong = fk.CreateSkill{
  name = "qigong",
}

Fk:loadTranslationTable{
  ["qigong"] = "齐攻",
  [":qigong"] = "当你使用的仅指定唯一目标的【杀】被【闪】抵消后，你可以令一名角色对此目标再使用一张无距离限制的【杀】，此【杀】不可被响应。",

  ["#qigong-choose"] = "齐攻：你可以令一名角色对 %dest 使用【杀】（无距离限制且不可被响应）",
  ["#qigong-use"] = "齐攻：你可以对 %dest 使用一张【杀】（无距离限制且不可被响应）",

  ["$qigong1"] = "打虎亲兄弟！",
  ["$qigong2"] = "兄弟齐心，其利断金！",
}

qigong:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qigong.name) and data.card.trueName == "slash" and
      data:isOnlyTarget(data.to)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(data.to, false),
      skill_name = qigong.name,
      prompt = "#qigong-choose::"..data.to.id,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local use = room:askToUseCard(to, {
      skill_name = qigong.name,
      pattern = "slash",
      prompt = "#qigong-use::"..data.to.id,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        exclusive_targets = {data.to.id},
      }
    })
    if use then
      use.extraUse = true
      use.disresponsiveList = {data.to}
      room:useCard(use)
    end
  end,
})

return qigong
