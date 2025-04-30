local shisuan = fk.CreateSkill{
  name = "shisuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shisuan"] = "蓍算",
  [":shisuan"] = "锁定技，当你受到伤害后，你重铸一张牌，伤害来源选择一项：1.失去1点体力；2.交给你其装备区内一张牌；3.翻面。",

  ["#shisuan-recast"] = "蓍算：请重铸一张牌",
  ["shisuan_give"] = "交给 %src 装备区一张牌",
  ["#shisuan-give"] = "蓍算：请交给 %src 装备区一张牌",

  ["$shisuan1"] = "匹夫，我早就知道你不是好人！",
  ["$shisuan2"] = "原来卦象上说的小人就是你！",
}

shisuan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shisuan.name) and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    if data.from and not data.from.dead then
      event:setCostData(self, {tos = {data.from}})
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shisuan.name,
      prompt = "#shisuan-recast",
      cancelable = false,
    })
    room:recastCard(card, player, shisuan.name)
    if not data.from or data.from.dead then return end
    local all_choices = {"loseHp", "shisuan_give:"..player.id, "turnOver"}
    local choices = table.simpleClone(all_choices)
    if player.dead or #data.from:getCardIds("e") == 0 then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(data.from, {
      choices = choices,
      skill_name = shisuan.name,
      all_choices = all_choices,
    })
    if choice == "loseHp" then
      room:loseHp(data.from, 1, shisuan.name)
    elseif choice == "turnOver" then
      data.from:turnOver()
    else
      card = room:askToCards(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = shisuan.name,
        pattern = ".|.|.|equip",
        prompt = "#shisuan-give:"..player.id,
        cancelable = false,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, shisuan.name, nil, true, data.from)
    end
  end,
})

return shisuan
