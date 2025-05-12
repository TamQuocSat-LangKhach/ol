local zhefu = fk.CreateSkill{
  name = "zhefu",
}

Fk:loadTranslationTable{
  ["zhefu"] = "哲妇",
  [":zhefu"] = "当你于回合外使用或打出一张牌后，你可以令一名有手牌的其他角色选择：弃置一张同名牌，或受到你的1点伤害。",

  ["#zhefu-choose"] = "哲妇：选择一名角色，其弃置一张【%arg】或受到你的1点伤害",
  ["#zhefu-discard"] = "哲妇：弃置一张【%arg】，否则 %dest 对你造成1点伤害",

  ["$zhefu1"] = "非我善妒，实乃汝之过也！",
  ["$zhefu2"] = "履行不端者，当有此罚。",
}

local spec = {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhefu.name) and player.room.current ~= player and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhefu.name,
      prompt = "#zhefu-choose:::"..data.card.trueName,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if #room:askToDiscard(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zhefu.name,
      pattern = data.card.trueName,
      prompt = "#zhefu-discard::"..player.id..":"..data.card.trueName,
      cancelable = true,
    }) == 0 then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = zhefu.name,
      }
    end
  end,
}

zhefu:addEffect(fk.CardUseFinished, spec)
zhefu:addEffect(fk.CardRespondFinished, spec)

return zhefu
