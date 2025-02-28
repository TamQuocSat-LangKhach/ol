local ranji = fk.CreateSkill{
  name = "ranji",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ranji"] = "燃己",
  [":ranji"] = "限定技，结束阶段，若你本回合使用过牌的阶段数：不小于体力值，你可以获得〖困奋〗；不大于体力值，你可以获得〖诈降〗。若如此做，"..
  "你将手牌数或体力值调整至体力上限，然后你不能回复体力，直到你杀死角色。",

  ["#ranji1-invoke"] = "燃己：是否获得〖困奋〗？",
  ["#ranji2-invoke"] = "燃己：是否获得〖诈降〗？",
  ["#ranji3-invoke"] = "燃己：是否获得〖困奋〗和〖诈降〗？",
  ["ranji-draw"] = "将手牌摸至手牌上限",
  ["ranji-recover"] = "回复体力至体力上限",
  ["@@ranji"] = "燃己",

  ["$ranji1"] = "此身为薪，炬成灰亦昭大汉长明！",
  ["$ranji2"] = "维之一腔骨血，可驱驰来北马否？",
}

ranji:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ranji.name) and player.phase == Player.Finish and
      player:usedSkillTimes(ranji.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local phase_ids = {}
    room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
      table.insert(phase_ids, {e.id, e.end_id})
    end, Player.HistoryTurn)
    local record = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player then
        for _, phase_id in ipairs(phase_ids) do
          if #phase_id == 2 and e.id > phase_id[1] and (e.id < phase_id[2] or phase_id[2] == -1) then
            table.insertIfNeed(record, phase_id[1])
          end
        end
      end
    end, Player.HistoryTurn)
    local prompt = 0
    if #record == player.hp then
      prompt = 3
    elseif #record > player.hp then
      prompt = 1
    elseif #record < player.hp then
      prompt = 2
    end
    if room:askToSkillInvoke(player, {
      skill_name = ranji.name,
      prompt = "#ranji"..prompt.."-invoke",
    }) then
      event:setCostData(self, {choice = prompt})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == 1 then
      room:handleAddLoseSkills(player, "kunfenEx")
    elseif event:getCostData(self).choice == 2 then
      room:handleAddLoseSkills(player, "ol_ex__zhaxiang")
    elseif event:getCostData(self).choice == 3 then
      room:handleAddLoseSkills(player, "kunfenEx|ol_ex__zhaxiang")
    end
    local choices = {}
    if player:getHandcardNum() < player.maxHp then
      table.insert(choices, "ranji-draw")
    end
    if player:isWounded() then
      table.insert(choices, "ranji-recover")
    end
    if #choices > 0 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = ranji.name,
      })
      if choice == "ranji-draw" then
        player:drawCards(player.maxHp - player:getHandcardNum(), ranji.name)
      else
        room:recover{
          who = player,
          num = player:getLostHp(),
          recoverBy = player,
          skillName = ranji.name,
        }
      end
    end
    if not player.dead then
      room:setPlayerMark(player, "@@ranji", 1)
    end
  end,
})
ranji:addEffect(fk.Death, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("@@ranji") > 0 and data.killer == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ranji", 0)
  end,
})
ranji:addEffect(fk.PreHpRecover, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@ranji") > 0
  end,
  on_use = function (self, event, target, player, data)
    data:preventRecover()
  end,
})

return ranji
