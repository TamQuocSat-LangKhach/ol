local this = fk.CreateSkill { name = "ol_ex__shebian" }

this:addEffect(fk.TurnedOver, {
  anim_type = "control",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChooseToMoveCardInBoard(player, { prompt = "#ol_ex__shebian-choose", skill_name = this.name, cancelable = true, flag = "e"})
    if #to == 2 then
      room:askToMoveCardInBoard(player, { target_one = to[1], target_two = to[2], skill_name = this.name, flag = "e"})
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__shebian"] = "设变",
  [":ol_ex__shebian"] = "当你翻面后，你可将一名角色装备区里的一张牌置入另一名角色的装备区。",
  
  ["$ol_ex__shebian1"] = "设变力战，虏敌千万！",
  ["$ol_ex__shebian2"] = "随机应变，临机设变！",
}

return this