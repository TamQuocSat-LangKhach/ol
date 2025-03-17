local jieyuan = fk.CreateSkill{
  name = "ol__jieyuan",
  dynamic_desc = function(self, player)
    local desc1 = table.contains(player:getTableMark("ol__fenxin"), "rebel") and "" or Fk:translate("ol__jieyuan_hp")
    local desc3 = table.contains(player:getTableMark("ol__fenxin"), "loyalist") and "" or Fk:translate("ol__jieyuan_hp")
    if table.contains(player:getTableMark("ol__fenxin"), "renegade") then
      return "ol__jieyuan_inner:"..desc1..":"..Fk:translate("card")..":"..desc3..":"..Fk:translate("card")
    else
      return "ol__jieyuan_inner:"..desc1..":"..Fk:translate("ol__jieyuan1_card")..":"..desc3..":"..Fk:translate("ol__jieyuan2_card")
    end
  end,
}

Fk:loadTranslationTable{
  ["ol__jieyuan"] = "竭缘",
  [":ol__jieyuan"] = "当你对其他角色造成伤害时，若其体力值不小于你，你可以弃置一张黑色手牌令此伤害+1；"..
  "当你受到其他角色造成的伤害时，若其体力值不小于你，你可以弃置一张红色手牌令此伤害-1。",

  [":ol__jieyuan_inner"] = "当你对其他角色造成伤害时，{1}你可以弃置一张{2}令此伤害+1；"..
  "当你受到其他角色造成的伤害时，{3}你可以弃置一张{4}令此伤害-1。",
  ["ol__jieyuan_hp"] = "若其体力值不小于你，",
  ["ol__jieyuan1_card"] = "黑色手牌",
  ["ol__jieyuan2_card"] = "红色手牌",

  ["#ol__jieyuan1-invoke"] = "竭缘：你可以弃置一张黑色手牌令对 %dest 造成的伤害+1",
  ["#ol__jieyuan2-invoke"] = "竭缘：你可以弃置一张红色手牌令你受到的伤害-1",
  ["#ol__jieyuan1_updata-invoke"] = "竭缘：你可以弃置一张牌令对 %dest 造成的伤害+1",
  ["#ol__jieyuan2_updata-invoke"] = "竭缘：你可以弃置一张牌令你受到的伤害-1",

  ["$ol__jieyuan1"] = "心竭而出，缘竭而究。",
  ["$ol__jieyuan2"] = "缘浅情浓，竭力而衰。",
}

jieyuan:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyuan.name) and data.to ~= player and not player:isNude() and
      (data.to.hp >= player.hp or table.contains(player:getTableMark("ol__fenxin"), "rebel"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local pattern, prompt
    if table.contains(player:getTableMark("ol__fenxin"), "renegade") then
      pattern = "."
      prompt = "#ol__jieyuan1_updata-invoke::"..data.to.id
    else
      pattern = ".|.|spade,club|hand"
      prompt = "#ol__jieyuan1-invoke::"..data.to.id
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = pattern == ".",
      skill_name = jieyuan.name,
      pattern = pattern,
      prompt = prompt,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {data.to}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
    player.room:throwCard(event:getCostData(self).cards, jieyuan.name, player, player)
  end,
})
jieyuan:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyuan.name) and data.from and data.from ~= player and not player:isNude() and
      (data.from.hp >= player.hp or table.contains(player:getTableMark("ol__fenxin"), "loyalist"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local pattern, prompt
    if table.contains(player:getTableMark("ol__fenxin"), "renegade") then
      pattern = "."
      prompt = "#ol__jieyuan2_updata-invoke"
    else
      pattern = ".|.|heart,diamond|hand"
      prompt = "#ol__jieyuan2-invoke"
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = pattern == ".",
      skill_name = jieyuan.name,
      pattern = pattern,
      prompt = prompt,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
    player.room:throwCard(event:getCostData(self).cards, jieyuan.name, player, player)
  end,
})

return jieyuan
