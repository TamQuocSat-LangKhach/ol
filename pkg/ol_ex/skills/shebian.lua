local shebian = fk.CreateSkill {
  name = "shebian",
}

Fk:loadTranslationTable{
  ["shebian"] = "设变",
  [":shebian"] = "当你翻面后，你可以移动场上一张装备牌。",

  ["#shebian-choose"] = "设变：你可以移动场上一张装备牌",

  ["$shebian1"] = "设变力战，虏敌千万！",
  ["$shebian2"] = "随机应变，临机设变！",
}

shebian:addEffect(fk.TurnedOver, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shebian.name) and
      #player.room:canMoveCardInBoard("e") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChooseToMoveCardInBoard(player, {
      prompt = "#shebian-choose",
      skill_name = shebian.name,
      cancelable = true,
      flag = "e",
    })
    if #tos == 2 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToMoveCardInBoard(player, {
      target_one = event:getCostData(self).tos[1],
      target_two = event:getCostData(self).tos[2],
      skill_name = shebian.name,
      flag = "e",
    })
  end,
})

return shebian