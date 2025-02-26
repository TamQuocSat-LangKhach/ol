local jianchu = fk.CreateSkill{
  name = "ol_ex__jianchu",
}

Fk:loadTranslationTable {
  ["ol_ex__jianchu"] = "鞬出",
  [":ol_ex__jianchu"] = "当你使用【杀】指定一个目标后，你可弃置其一张牌，若此牌：为基本牌，其获得此【杀】；不为基本牌，此【杀】不能被其抵消，"..
  "你于此阶段内使用【杀】的次数上限+1。",

  ["#ol_ex__jianchu-invoke"] = "鞬出：可以弃置 %src 一张牌",

  ["$ol_ex__jianchu1"] = "你这身躯，怎么能快过我？",
  ["$ol_ex__jianchu2"] = "这些怎么能挡住我的威力！",
}

jianchu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianchu.name) and data.card.trueName == "slash" and
      not data.to:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = jianchu.name,
      prompt = "#ol_ex__jianchu-invoke:"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    if to:isNude() then return end
    local cid = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = jianchu.name,
    })
    room:throwCard(cid, jianchu.name, to, player)
    local card = Fk:getCardById(cid)
    if card.type == Card.TypeBasic then
      if not to.dead and room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(to, data.card, true, fk.ReasonJustMove, to)
      end
    else
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase")
      data.disresponsive = true
    end
  end,
})

return jianchu