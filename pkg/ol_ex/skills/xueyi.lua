local xueyi = fk.CreateSkill{
  name = "ol_ex__xueyi",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable {
  ["ol_ex__xueyi"] = "血裔",
  [":ol_ex__xueyi"] = "主公技，游戏开始时，你获得2X枚“裔”（X为群势力角色数）。出牌阶段开始时，你可以弃1枚“裔”，摸一张牌。"..
  "你的手牌上限+X（X为“裔”数）",

  ["@ol_ex__xueyi_yi"] = "裔",

  ["$ol_ex__xueyi1"] = "高贵名门，族裔盛名。",
  ["$ol_ex__xueyi2"] = "贵裔之脉，后起之秀！",
}

xueyi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xueyi.name) and
      table.find(player.room.alive_players, function (p)
        return p.kingdom == "qun"
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = #table.filter(room.alive_players, function (p)
      return p.kingdom == "qun"
    end)
    room:addPlayerMark(player, "@ol_ex__xueyi_yi", x * 2)
  end,
})

xueyi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xueyi.name) and player.phase == Player.Play and
      player:getMark("@ol_ex__xueyi_yi") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@ol_ex__xueyi_yi")
    player:drawCards(1, xueyi.name)
  end,
})

xueyi:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(xueyi.name) then
      return player:getMark("@ol_ex__xueyi_yi")
    end
  end,
})

return xueyi