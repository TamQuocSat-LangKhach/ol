local tanque = fk.CreateSkill{
  name = "tanque",
}

Fk:loadTranslationTable{
  ["tanque"] = "弹雀",
  [":tanque"] = "每回合限一次，当你使用牌结算结束后，你可以对一名体力值为X的角色造成1点伤害（X为此牌点数与你上一张使用牌点数之差，不能为0）。",

  ["#tanque-choose"] = "弹雀：你可以对一名体力值为%arg的角色造成1点伤害",

  ["$tanque1"] = "",
  ["$tanque2"] = "",
}

tanque.zhongliu_type = Player.HistoryTurn

tanque:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tanque.name) and data.card.number > 0 and
      player:usedSkillTimes(tanque.name, Player.HistoryTurn) == 0 then
      local n = 0
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use ~= data and use.from == player then
          n = use.card.number ~= 0 and math.abs(use.card.number - data.card.number) or 0
          return true
        end
      end, 0)
      if n ~= 0 and
        table.find(player.room.alive_players, function (p)
          return p.hp == n
        end) then
        event:setCostData(self, {choice = n})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    local targets = table.filter(room.alive_players, function (p)
      return p.hp == n
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = tanque.name,
      prompt = "#tanque-choose:::"..n,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = tanque.name,
    }
  end,
})

return tanque
