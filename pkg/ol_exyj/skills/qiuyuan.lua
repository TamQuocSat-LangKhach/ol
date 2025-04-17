local qiuyuan = fk.CreateSkill{
  name = "ol_ex__qiuyuan",
}

Fk:loadTranslationTable{
  ["ol_ex__qiuyuan"] = "求援",
  [":ol_ex__qiuyuan"] = "当你成为【杀】或伤害锦囊的目标时，你可以令另一名其他角色选择一项：1.交给你一张与此牌同类型不同牌名的牌；"..
  "2.成为此牌的额外目标。",

  ["#ol_ex__qiuyuan-choose"] = "求援：令一名角色选择：交给你一张相同类别不同牌名的牌，或成为此%arg额外目标",
  ["#ol_ex__qiuyuan-give"] = "求援：交给 %dest 一张不为【%arg】的%arg2，否则成为此牌额外目标",

  ["$ol_ex__qiuyuan1"] = "我父伏完常有杀操之心，今当修书一封，秘密图之。",
  ["$ol_ex__qiuyuan2"] = "中朝能称忠义者，莫当黄门穆顺。",
}

qiuyuan:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(qiuyuan.name) and data.card.is_damage_card then
      local tos = data:getAllTargets()
      return table.find(player.room.alive_players, function (p)
        return p ~= data.from and p ~= player and not table.contains(tos, p)
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p ~= data.from and p ~= player and not table.contains(data:getAllTargets(), p)
    end)
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__qiuyuan-choose:::"..data.card:toLogString(),
      skill_name = qiuyuan.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = table.filter(to:getCardIds("h"), function(id)
      local card = Fk:getCardById(id)
      return card.type == data.card.type and card.trueName ~= data.card.trueName
    end)
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qiuyuan.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#ol_ex__qiuyuan-give::"..player.id..":"..data.card.trueName..":"..data.card:getTypeString(),
    })
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, qiuyuan.name, nil, true, to)
    else
      --本意：此额外目标视为已生成过“成为目标时fk.TargetConfirming”时机，因此直接添加到AimData.Done中
      table.insert(data.tos[AimData.Done], to)
      table.insert(data.use.tos, to)
    end
  end,
})

return qiuyuan
