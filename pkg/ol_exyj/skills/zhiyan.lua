local zhiyan = fk.CreateSkill{
  name = "ol_ex__zhiyan",
}

Fk:loadTranslationTable{
  ["ol_ex__zhiyan"] = "直言",
  [":ol_ex__zhiyan"] = "你或你上家的结束阶段，你可以令一名角色摸一张牌并展示之，若此牌：为装备牌，其使用此牌并回复1点体力；"..
  "不为装备牌且其体力值不等于你，其失去1点体力。",

  ["#ol_ex__zhiyan-choose"] = "直言：你可以令一名角色摸一张牌并展示之",

  ["$ol_ex__zhiyan1"] = "尔降虏，何敢与吾君齐马首乎！",
  ["$ol_ex__zhiyan2"] = "当闭反开，当开反闭，匹夫何故反复？",
}

zhiyan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and (target == player or target:getNextAlive() == player) and player:hasSkill(zhiyan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__zhiyan-choose",
      skill_name = zhiyan.name,
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
    local ids = to:drawCards(1, zhiyan.name)
    if #ids == 0 then return false end
    local id = ids[1]
    if not table.contains(to:getCardIds("h"), id) then return false end
    local card = Fk:getCardById(id)
    to:showCards(card)
    if to.dead then return false end
    room:delay(1000)
    if card.type == Card.TypeEquip then
      if to:canUseTo(card, to) then
        room:useCard({
          from = to,
          tos = {to},
          card = card,
        })
        if to:isWounded() and not to.dead then
          room:recover{
            who = to,
            num = 1,
            recoverBy = player,
            skillName = zhiyan.name
          }
        end
      end
    elseif to.hp ~= player.hp then
      room:loseHp(to, 1, zhiyan.name)
    end
  end,
})

return zhiyan