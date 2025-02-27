local liegong = fk.CreateSkill {
  name = "ol_ex__liegong",
}

Fk:loadTranslationTable{
  ["ol_ex__liegong"] = "烈弓",
  [":ol_ex__liegong"] = "你对至其距离不大于此【杀】点数的角色使用【杀】无距离限制。当你使用【杀】指定一个目标后：若其手牌数不大于你，"..
  "你可以令此【杀】不能被其抵消；若其体力值不小于你，你可以令此【杀】对其伤害值基数+1。",

  ["#ol_ex__liegong-invoke"] = "烈弓：是否对 %dest 发动“烈弓”？",

  ["$ol_ex__liegong1"] = "龙骨成镞，矢破苍穹！",
  ["$ol_ex__liegong2"] = "凤翎为羽，箭没坚城！",
}

liegong:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liegong.name) and
      data.card.trueName == "slash" and
      (data.to:getHandcardNum() <= player:getHandcardNum() or data.to.hp >= player.hp)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = liegong.name,
      prompt = "#ol_ex__liegong-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.to:getHandcardNum() <= player:getHandcardNum() then
      table.insertIfNeed(data.use.disresponsiveList, data.to)
    end
    if data.to.hp >= player.hp then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

liegong:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, target)
    return card and card.trueName == "slash" and player:hasSkill(liegong.name) and
      player:distanceTo(target) <= card.number
  end,
})

return liegong