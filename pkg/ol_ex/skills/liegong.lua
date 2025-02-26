local this = fk.CreateSkill { name = "ol_ex__liegong" }

this:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(this.name)) then return end
    local to = data.to
    return data.card.trueName == "slash" and (#to:getCardIds(Player.Hand) <= #player:getCardIds(Player.Hand) or to.hp >= player.hp)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, { skill_name = this.name, prompt =  "#ol_ex__liegong-invoke::"..data.to.id}) then
      room:doIndicate(player.id, {data.to.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = data.to
    if #to:getCardIds(Player.Hand) <= #player:getCardIds(Player.Hand) then
      data.disresponsive = true -- FIXME: use disreponseList. this is FK's bug
    end
    if to.hp >= player.hp then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

this:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, target)
    if skill.trueName == "slash_skill" and player:hasSkill(this.name) then
      return card and target and player:distanceTo(target) <= card.number
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__liegong"] = "烈弓",
  [":ol_ex__liegong"] = "①你对至其距离不大于此【杀】点数的角色使用【杀】无距离关系的限制。"..
  "②当你使用【杀】指定一个目标后，你可执行：1.若其手牌数不大于你，此【杀】不能被此目标抵消；"..
  "2.若其体力值不小于你，此【杀】对此目标的伤害值基数+1。",

  ["#ol_ex__liegong-invoke"] = "你是否想要对%dest发动“烈弓”？",

  ["$ol_ex__liegong1"] = "龙骨成镞，矢破苍穹！",
  ["$ol_ex__liegong2"] = "凤翎为羽，箭没坚城！",
}

return this