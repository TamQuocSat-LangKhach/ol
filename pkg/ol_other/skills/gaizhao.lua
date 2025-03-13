local gaizhao = fk.CreateSkill{
  name = "qin__gaizhao",
}

Fk:loadTranslationTable{
  ["qin__gaizhao"] = "改诏",
  [":qin__gaizhao"] = "当你成为【杀】或普通锦囊牌的目标时，你可以将此牌的目标转移给此牌目标以外的一名其他秦势力角色。",

  ["#qin__gaizhao-choose"] = "改诏：你可以将此%arg的目标转移给一名角色",

  ["$qin__gaizhao"] = "我的话才是诏书所言。",
}

gaizhao:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gaizhao.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(data:getExtraTargets({bypass_distances = true}), function (p)
        return p.kingdom == "qin"
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({bypass_distances = true}), function (p)
      return p.kingdom == "qin"
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = gaizhao.name,
      prompt = "#qin__gaizhao-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

return gaizhao
