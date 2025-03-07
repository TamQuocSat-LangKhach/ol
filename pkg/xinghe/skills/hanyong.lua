local hanyong = fk.CreateSkill{
  name = "hanyong",
}

Fk:loadTranslationTable{
  ["hanyong"] = "悍勇",
  [":hanyong"] = "当你使用【南蛮入侵】或【万箭齐发】时，若你的体力值小于游戏轮数，你可以令此牌造成的伤害+1。",

  ["$hanyong1"] = "犯我者，杀！",
  ["$hanyong2"] = "藤甲军从无对手，不服来战！",
}

hanyong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hanyong.name) and
      (data.card.name == "savage_assault" or data.card.name == "archery_attack") and
      player.hp < player.room:getBanner("RoundCount")
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return hanyong
