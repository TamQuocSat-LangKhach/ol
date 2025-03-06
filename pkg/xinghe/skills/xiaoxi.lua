local xiaoxi = fk.CreateSkill{
  name = "ol__xiaoxi",
}

Fk:loadTranslationTable{
  ["ol__xiaoxi"] = "骁袭",
  [":ol__xiaoxi"] = "每轮开始时，你可以视为使用一张无距离限制的【杀】。",

  ["#ol__xiaoxi-invoke"] = "骁袭：你可以视为使用一张无距离限制的【杀】",

  ["$ol__xiaoxi1"] = "先吃我一剑！",
  ["$ol__xiaoxi2"] = "这是给你的下马威！",
}

xiaoxi:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiaoxi.name) and player:canUse(Fk:cloneCard("slash"), {bypass_distances = true, bypass_times = true})
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = xiaoxi.name,
      prompt = "#ol__xiaoxi-invoke",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return xiaoxi
