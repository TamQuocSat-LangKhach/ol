local qiejian = fk.CreateSkill{
  name = "qiejian",
}

Fk:loadTranslationTable{
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去手牌后，若其没有手牌，你可以与其各摸一张牌，"..
  "然后选择一项：1.弃置你或其场上的一张牌；2.你本轮内不能对其发动此技能。",

  ["#qiejian-invoke"] = "切谏：是否与 %dest 各摸一张牌并选择一项",
  ["#qiejian-choose"] = "切谏：弃置你或 %dest 场上一张牌，或点“取消”本轮不能再对其发动“切谏”",

  ["$qiejian1"] = "东宫不稳，必使众人生异。",
  ["$qiejian2"] = "今三方鼎峙，不宜擅动储君。",
}

qiejian:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qiejian.name) then
      local targets, targetRecorded = {}, player:getTableMark("qiejian_prohibit-round")
      for _, move in ipairs(data) do
        if move.from and not table.contains(targetRecorded, move.from.id) then
          if move.from:isKongcheng() and not move.from.dead and
            not table.every(move.moveInfo, function (info)
              return info.fromArea ~= Card.PlayerHand
            end) then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).extra_data
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(qiejian.name) then return end
      if not table.contains(player:getTableMark("qiejian_prohibit-round"), p.id) and not p.dead then
        event:setCostData(self, {tos = {p}})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if room:askToSkillInvoke(player, {
      skill_name = qiejian.name,
      prompt = "#qiejian-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    player:drawCards(1, qiejian.name)
    if not to.dead then
      to:drawCards(1, qiejian.name)
    end
    if player.dead then return end
    local tos = table.filter({player, to}, function (p)
      return #p:getCardIds("he") > 0
    end)
    if #tos > 0 then
      tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = tos,
        skill_name = qiejian.name,
        prompt = "#qiejian-choose::"..to.id,
        cancelable = true,
      })
    end
    if #tos > 0 then
      local id = room:askToChooseCard(player, {
        target = tos[1],
        flag = "ej",
        skill_name = qiejian.name,
      })
      room:throwCard(id, qiejian.name, to, player)
    else
      room:addTableMarkIfNeed(player, "qiejian_prohibit-round", to.id)
    end
  end,
})

return qiejian
