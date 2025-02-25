local this = fk.CreateSkill{
  name = "ol_ex__xueyi$",
}

this:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) then
      for _, p in ipairs(player.room.alive_players) do
        if p.kingdom == "qun" then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = #table.filter(room.alive_players, function (p) return p.kingdom == "qun" end)
    if x > 0 then
      room:addPlayerMark(player, "@ol_ex__xueyi_yi", x*2)
    end
  end,
})

this:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) then
      return player.phase == Player.Play and player:getMark("@ol_ex__xueyi_yi") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@ol_ex__xueyi_yi")
    player:drawCards(1, this.name)
  end,
})

this:addEffect('maxcards', {
  correct_func = function(self, player)
    if player:hasSkill(this.name) then
      return player:getMark("@ol_ex__xueyi_yi")
    else
      return 0
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__xueyi"] = "血裔",
  [":ol_ex__xueyi"] = "主公技，①游戏开始时，你获得2X枚“裔”（X为群势力角色数）。②出牌阶段开始时，你可弃1枚“裔”，你摸一张牌。③你的手牌上限+X（X为“裔”数）",

  ["@ol_ex__xueyi_yi"] = "裔",
  
  ["$ol_ex__xueyi1"] = "高贵名门，族裔盛名。",
  ["$ol_ex__xueyi2"] = "贵裔之脉，后起之秀！",
}

return this