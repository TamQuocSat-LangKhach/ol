local chenggong = fk.CreateSkill{
  name = "guandu__chenggong",
}

Fk:loadTranslationTable{
  ["guandu__chenggong"] = "逞功",
  [":guandu__chenggong"] = "当一名角色使用牌指定目标后，若目标数大于1，你可以令其摸一张牌。",

  ["#guandu__chenggong-invoke"] = "逞功：是否令 %dest 摸一张牌？",

  ["$guandu__chenggong1"] = "吾与主公患难之交也！",
  ["$guandu__chenggong2"] = "我豫州人才济济，元皓之辈，不堪大用。",
}

chenggong:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenggong.name) and data.firstTarget and
      #data.use.tos > 1 and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chenggong.name,
      prompt = "#guandu__chenggong-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, chenggong.name)
  end,
})

return chenggong
