local this = fk.CreateSkill{
  name = "ol_ex__jiezi",
}

this:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) and player ~= target and target and target.skipped_phases[Player.Draw] and
        player:usedSkillTimes(this.name, Player.HistoryTurn) < 1 then
      return data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish
    end
  end,
  on_cost = function(self, event, target, player, data)
    local result = player.room:askToChoosePlayers(player, {targets = player.room.alive_players, min_num = 1, max_num = 1,
      prompt = "#ol_ex__jiezi-choose", skill_name = this.name, cancelable = true
    })
    if #result == 1 then
      self.cost_data = result[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:getMark("@@ol_ex__jiezi_zi") == 0 and table.every(player.room.alive_players, function (p)
        return #p:getCardIds(Player.Hand) >= #to:getCardIds(Player.Hand)
      end) then
      room:addPlayerMark(to, "@@ol_ex__jiezi_zi")
    else
      to:drawCards(1, this.name)
    end
  end,
})

this:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:getMark("@@ol_ex__jiezi_zi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ol_ex__jiezi_zi", 0)
    player:gainAnExtraPhase(Player.Draw)
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__jiezi"] = "截辎",
  ["#ol_ex__jiezi_delay"] = "截辎",
  [":ol_ex__jiezi"] = "每回合限一次，其他角色的出牌阶段、弃牌阶段或结束阶段开始前，若其于此回合内跳过过摸牌阶段，"..
  "你可选择一名角色，若其手牌数为全场最少且没有“辎”，其获得1枚“辎”；否则其摸一张牌。"..
  "当有“辎”的角色的摸牌阶段结束时，其弃所有“辎”，获得一个额外摸牌阶段。",

  ["@@ol_ex__jiezi_zi"] = "辎",
  ["#ol_ex__jiezi-choose"] = "截辎：选择一名角色，令其获得“辎”标记或摸一张牌",
  
  ["$ol_ex__jiezi1"] = "剪径截辎，馈泽同袍。",
  ["$ol_ex__jiezi2"] = "截敌粮草，以资袍泽。",
}

return this