local shanzhuan = fk.CreateSkill{
  name = "shanzhuan",
}

Fk:loadTranslationTable{
  ["shanzhuan"] = "擅专",
  [":shanzhuan"] = "当你对一名其他角色造成伤害后，若其判定区没有牌，你可以将其一张牌置于其判定区，若此牌不是延时锦囊牌，则红色牌视为【乐不思蜀】，"..
  "黑色牌视为【兵粮寸断】。结束阶段，若你本回合未造成伤害，你可以摸一张牌。",

  ["#shanzhuan-invoke"] = "擅专：你可以将 %dest 一张牌置于其判定区，红色视为【乐不思蜀】，黑色视为【兵粮寸断】",

  ["$shanzhuan1"] = "打入冷宫，禁足绝食。",
  ["$shanzhuan2"] = "我言既出，谁敢不从？",
}

shanzhuan:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanzhuan.name) and
      data.to ~= player and not data.to.dead and not data.to:isNude() and
      not table.contains(data.to.sealedSlots, Player.JudgeSlot) and #data.to:getCardIds("j") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shanzhuan.name,
      prompt = "#shanzhuan-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = shanzhuan.name,
    })
    if Fk:getCardById(id, true).sub_type == Card.SubtypeDelayedTrick then
      room:moveCardTo(Fk:getCardById(id, true), Player.Judge, data.to, fk.ReasonJustMove, shanzhuan.name)
    else
      local card = Fk:cloneCard("indulgence")
      if Fk:getCardById(id, true).color == Card.Black then
        card = Fk:cloneCard("supply_shortage")
      end
      card:addSubcard(id)
      data.to:addVirtualEquip(card)
      room:moveCardTo(card, Player.Judge, data.to, fk.ReasonJustMove, shanzhuan.name)  --无视合法性检测
    end
  end,
})
shanzhuan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanzhuan.name) and player.phase == Player.Finish and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end) == 0
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, shanzhuan.name)
  end,
})

return shanzhuan
