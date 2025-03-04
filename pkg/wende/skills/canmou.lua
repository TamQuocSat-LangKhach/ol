local canmou = fk.CreateSkill{
  name = "canmou",
}

Fk:loadTranslationTable{
  ["canmou"] = "参谋",
  [":canmou"] = "当手牌数全场唯一最多的角色使用普通锦囊牌指定目标时，你可以为此锦囊牌多指定一个目标。",

  ["#canmou-choose"] = "参谋：你可以为 %src 使用的%arg多指定一个目标",

  ["$canmou1"] = "兢兢业业，竭心筹划。",
  ["$canmou2"] = "欲设此法，计谋二人。",
}

canmou:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(canmou.name) and data.card:isCommonTrick() and
      table.every(player.room:getOtherPlayers(target, false), function (p)
        return target:getHandcardNum() > p:getHandcardNum()
      end) and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets(),
      skill_name = canmou.name,
      prompt = "#canmou-choose:"..target.id.."::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

return canmou
