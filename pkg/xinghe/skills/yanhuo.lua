local yanhuo = fk.CreateSkill{
  name = "ol__yanhuo",
}

Fk:loadTranslationTable{
  ["ol__yanhuo"] = "延祸",
  [":ol__yanhuo"] = "当你死亡时，你可以弃置杀死你的角色至多X张牌（X为你的牌数）。",

  ["#ol__yanhuo-invoke"] = "延祸：你可以弃置 %dest 至多%arg张牌",
  ["#ol__yanhuo-discard"] = "延祸：弃置 %dest 至多%arg张牌",

  ["$ol__yanhuo1"] = "是谁，泄露了我的计划？",
  ["$ol__yanhuo2"] = "战斗还没结束呢！",
}

yanhuo:addEffect(fk.Death, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yanhuo.name, false, true) and
      not player:isNude() and data.killer and not data.killer.dead and not data.killer:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yanhuo.name,
      prompt = "#ol__yanhuo-invoke::"..data.killer.id..":"..#player:getCardIds("he"),
    }) then
      event:setCostData(self, {tos = {data.killer}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #player:getCardIds("he")
    local cards = room:askToChooseCards(player, {
      target = data.killer,
      min = 1,
      max = n,
      flag = "he",
      skill_name = yanhuo.name,
      prompt = "#ol__yanhuo-discard::"..data.killer.id..":"..n,
    })
    room:throwCard(cards, yanhuo.name, data.killer, player)
  end,
})

return yanhuo
