local lisi = fk.CreateSkill{
  name = "lisi",
}

Fk:loadTranslationTable{
  ["lisi"] = "离思",
  [":lisi"] = "当你于回合外使用的牌结算后，你可将之交给一名手牌数不大于你的其他角色。",

  ["#lisi-choose"] = "离思：你可以将%arg交给一名手牌数不大于你的其他角色",

  ["$lisi1"] = "骨肉至亲，化为他人。",
  ["$lisi2"] = "梦想魂归，见所思兮。",
}

lisi:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lisi.name) and player.room.current ~= player and
      player.room:getCardArea(data.card) == Card.Processing and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getHandcardNum() <= player:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getHandcardNum() <= player:getHandcardNum()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = lisi.name,
      prompt = "#lisi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(event:getCostData(self).tos[1], data.card, true, fk.ReasonGive, player, lisi.name)
  end,
})

return lisi
