local liwen = fk.CreateSkill{
  name = "liwen",
}

Fk:loadTranslationTable{
  ["liwen"] = "立文",
  [":liwen"] = "游戏开始时，你获得三枚“贤”标记；当你使用或打出牌时，若此牌与你使用或打出的上一张牌花色或类别相同，你获得一枚“贤”标记；"..
  "回合结束时，你需将任意个“贤”标记分配给等量的角色（每名角色“贤”标记上限为5个），然后有“贤”标记的角色按照标记从多到少的顺序，依次使用一张手牌，"..
  "若其不使用，移去其“贤”标记，你摸等量的牌。",

  ["@kongrong_virtuous"] = "贤",
  ["@liwen_record"] = "立文",
  ["#liwen-choose"] = "立文：你可以将“贤”标记交给其他角色各一枚（每名角色至多5枚）",
  ["#liwen-use"] = "立文：请使用一张手牌，否则你弃置所有“贤”标记，%src 摸牌",

  ["$liwen1"] = "伐竹筑学宫，大庇天下士子。",
  ["$liwen2"] = "学而不厌，诲人不倦，何有于我哉。",
}

liwen:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@liwen_record", 0)
  for _, p in ipairs(room.alive_players) do
    room:setPlayerMark(p, "@kongrong_virtuous", 0)
  end
end)

liwen:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(liwen.name) and player:getMark("@kongrong_virtuous") < 5
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@kongrong_virtuous", math.min(3, 5 - player:getMark("@kongrong_virtuous")))
  end,
})

local liwen_record = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(liwen.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString() == player:getMark("liwen_suit") or data.card.type == player:getMark("liwen_type") then
      data.extra_data = data.extra_data or {}
      data.extra_data.liwen_triggerable = true
    end
    if data.card.suit == Card.NoSuit then
      room:setPlayerMark(player, "liwen_suit", 0)
    else
      room:setPlayerMark(player, "liwen_suit", data.card:getSuitString())
    end
    room:setPlayerMark(player, "liwen_type", data.card.type)
    room:setPlayerMark(player, "@liwen_record", {data.card:getSuitString(true), data.card:getTypeString()})
  end,
}
liwen:addEffect(fk.AfterCardUseDeclared, liwen_record)
liwen:addEffect(fk.CardResponding, liwen_record)

local liwen_spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liwen.name) and
      data.extra_data and data.extra_data.liwen_triggerable and player:getMark("@kongrong_virtuous") < 5
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@kongrong_virtuous", 1)
  end,
}
liwen:addEffect(fk.CardUsing, liwen_spec)
liwen:addEffect(fk.CardResponding, liwen_spec)

liwen:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liwen.name) and
      player:getMark("@kongrong_virtuous") > 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark("@kongrong_virtuous") < 5
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getMark("@kongrong_virtuous") < 5
    end)
    local tos = room:askToChoosePlayers(player,{
      targets = targets,
      min_num = 1,
      max_num = player:getMark("@kongrong_virtuous"),
      prompt = "#liwen-choose",
      skill_name = liwen.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
    end
    for _, to in ipairs(tos) do
      room:removePlayerMark(player, "@kongrong_virtuous", 1)
      room:addPlayerMark(to, "@kongrong_virtuous", 1)
    end
    targets = {}
    for i = 5, 1, -1 do
      for _, p in ipairs(room:getAlivePlayers(false)) do
        if p:getMark("@kongrong_virtuous") == i then
          table.insert(targets, p)
        end
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        local use = nil
        if not p:isKongcheng() then
          use = room:askToUseRealCard(p, {
            pattern = p:getCardIds("h"),
            skill_name = liwen.name,
            prompt = "#liwen-use:"..player.id,
            extra_data = {
              bypass_times = true,
              extraUse = true,
            },
            cancelable = true,
            skip = true,
          })
        end
        if use then
          room:useCard(use)
        else
          local n = p:getMark("@kongrong_virtuous")
          room:setPlayerMark(p, "@kongrong_virtuous", 0)
          if not player.dead then
            player:drawCards(n, liwen.name)
          end
        end
      end
    end
  end,
})

return liwen
