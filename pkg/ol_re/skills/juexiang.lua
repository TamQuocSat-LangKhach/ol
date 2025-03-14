local juexiang = fk.CreateSkill{
  name = "ol__juexiang",
}

Fk:loadTranslationTable{
  ["ol__juexiang"] = "绝响",
  [":ol__juexiang"] = "当你死亡时，你可以令一名其他角色随机获得〖激弦〗〖烈弦〗〖柔弦〗〖和弦〗中的一个技能，然后直到其下回合开始前，"..
  "该角色不能成为除其以外的角色使用♣牌的目标。",

  ["#ol__juexiang-choose"] = "绝响：你可以向一名角色传授“清弦残谱”",
  ["@@ol__juexiang"] = "绝响",

  ["$ol__juexiang1"] = "曲终人散皆是梦，繁华落尽一场空。",
  ["$ol__juexiang2"] = "广陵一失，千古绝响。",
}

juexiang:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juexiang.name, false, true) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = juexiang.name,
      prompt = "#ol__juexiang-choose",
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
    room:setPlayerMark(to, "@@ol__juexiang", 1)
    local skills = table.filter({"ol__jixian","ol__liexian","ol__rouxian","ol__hexian"}, function (s)
      return not to:hasSkill(s, true)
    end)
    if #skills > 0 then
      room:handleAddLoseSkills(to, table.random(skills))
    end
  end,
})
juexiang:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@ol__juexiang") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ol__juexiang", 0)
  end,
})
juexiang:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and to:getMark("@@ol__juexiang") > 0 and from ~= to and card.suit == Card.Club
  end,
})

return juexiang
