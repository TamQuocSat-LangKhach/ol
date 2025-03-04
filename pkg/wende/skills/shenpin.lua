local shenpin = fk.CreateSkill{
  name = "shenpin",
}

Fk:loadTranslationTable{
  ["shenpin"] = "神品",
  [":shenpin"] = "当一名角色的判定牌生效前，你可以打出一张与判定牌颜色不同的牌代替之。",

  ["#shenpin-invoke"] = "神品：你可以打出%arg牌代替 %dest 的“%arg2”判定",

  ["$shenpin1"] = "考其遗法，肃若神明。",
  ["$shenpin2"] = "气韵生动，出于天成。",
}

shenpin:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shenpin.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local response = room:askToResponse(player, {
      skill_name = shenpin.name,
      pattern = ".|.|"..(data.card.color == Card.Black and "heart,diamond" or "spade,club").."|hand,equip",
      prompt = "#shenpin-invoke::"..target.id..":"..(data.card.color == Card.Black and "red" or "black")..":"..data.reason,
      cancelable = true,
    })
    if response then
      event:setCostData(self, {extra_data = response.card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(event:getCostData(self).extra_data, player, data, shenpin.name, false)
  end,
})

return shenpin
