local this = fk.CreateSkill{
  name = "ol_ex__jianchu",
  anim_type = "offensive",
}

this:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(this.name)) then return end
    local to = data.to
    return data.card.trueName == "slash" and not to:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = this.name, prompt = "#ol_ex__jianchu-invoke:"..data.to.id}) then
      self.cost_data = {tos = {data.to}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    if to:isNude() then return end
    local cid = room:askToChooseCard(player, { target = to, flag = "he", skill_name = this.name })
    room:throwCard({cid}, this.name, to, player)
    local card = Fk:getCardById(cid)
    if card.type == Card.TypeBasic then
      if not to.dead then
        local cardlist = Card:getIdList(data.card)
        if #cardlist > 0 and table.every(cardlist, function(id) return room:getCardArea(id) == Card.Processing end) then
          room:obtainCard(to.id, data.card, true)
        end
      end
    else
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase")
      data.disresponsive = true
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__jianchu"] = "鞬出",
  [":ol_ex__jianchu"] = "当你使用【杀】指定一个目标后，你可弃置其一张牌，若此牌：为基本牌，其获得此【杀】；不为基本牌，此【杀】不能被此目标抵消，你于此阶段内使用【杀】的次数上限+1。",

  ["#ol_ex__jianchu-invoke"] = "鞬出：可以弃置 %src 一张牌",

  ["$ol_ex__jianchu1"] = "你这身躯，怎么能快过我？",
  ["$ol_ex__jianchu2"] = "这些怎么能挡住我的威力！",
}

return this