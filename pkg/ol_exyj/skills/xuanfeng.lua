local xuanfeng = fk.CreateSkill{
  name = "ol_ex__xuanfeng",
}

Fk:loadTranslationTable{
  ["ol_ex__xuanfeng"] = "旋风",
  [":ol_ex__xuanfeng"] = "当你失去装备区里的牌后，或一次性失去至少两张牌后，你可以依次弃置至多两名其他角色共计至多两张牌。",

  ["#xuanfeng-choose"] = "旋风：你可以弃置一名角色的一张牌",

  ["$ol_ex__xuanfeng1"] = "短兵相接，让敌人丢盔弃甲！",
  ["$ol_ex__xuanfeng2"] = "攻敌不备，看他们闻风而逃！",
}

xuanfeng:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xuanfeng.name) then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              n = n + 1
            elseif info.fromArea == Card.PlayerEquip then
              n = 2
            end
          end
        end
      end
      if n > 1 then
        return table.find(player.room:getOtherPlayers(player, false), function(p)
          return not p:isNude()
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xuanfeng-choose",
      skill_name = xuanfeng.name,
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
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = xuanfeng.name,
    })
    room:throwCard(card, xuanfeng.name, to, player)
    if player.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xuanfeng-choose",
      skill_name = xuanfeng.name,
      cancelable = true,
    })
    if #to > 0 then
      to = to[1]
      card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = xuanfeng.name,
      })
      room:throwCard(card, xuanfeng.name, to, player)
    end
  end,
})

return xuanfeng
