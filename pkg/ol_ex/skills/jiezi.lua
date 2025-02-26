local jiezi = fk.CreateSkill{
  name = "ol_ex__jiezi",
}

Fk:loadTranslationTable{
  ["ol_ex__jiezi"] = "截辎",
  ["#ol_ex__jiezi_delay"] = "截辎",
  [":ol_ex__jiezi"] = "每回合限一次，当其他角色跳过摸牌阶段后，你可以选择一名角色，若其手牌数为全场最少且没有“辎”，其获得1枚“辎”；否则其摸一张牌。"..
  "当有“辎”的角色的摸牌阶段结束时，其弃所有“辎”，获得一个额外摸牌阶段。",

  ["@@ol_ex__jiezi_zi"] = "辎",
  ["#ol_ex__jiezi-choose"] = "截辎：选择一名角色，令其获得“辎”标记或摸一张牌",

  ["$ol_ex__jiezi1"] = "剪径截辎，馈泽同袍。",
  ["$ol_ex__jiezi2"] = "截敌粮草，以资袍泽。",
}

jiezi:addEffect(fk.EventPhaseSkipped, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiezi.name) and target ~= player and data.phase == Player.Draw and
      player:usedEffectTimes(jiezi.name, Player.HistoryTurn) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__jiezi-choose",
      skill_name = jiezi.name,
      cancelable = true,
    })
    if #to == 1 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:getMark("@@ol_ex__jiezi_zi") == 0 and
      table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() >= to:getHandcardNum()
      end) then
      room:addPlayerMark(to, "@@ol_ex__jiezi_zi")
    else
      to:drawCards(1, jiezi.name)
    end
  end,
})

jiezi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:getMark("@@ol_ex__jiezi_zi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ol_ex__jiezi_zi", 0)
    player:gainAnExtraPhase(Player.Draw)
  end,
})

return jiezi