local qieting = fk.CreateSkill{
  name = "ol_ex__qieting",
}

Fk:loadTranslationTable{
  ["ol_ex__qieting"] = "窃听",
  [":ol_ex__qieting"] = "其他角色的回合结束后，若其于此回合内未对其以外的角色造成过伤害或未对其以外的角色使用过牌，你可以选择："..
  "1.将其装备区的一张牌置入你的装备区；2.摸一张牌。若其于此回合内未对其以外的角色使用过牌，你可以执行另一项。",

  ["#ol_ex__qieting-invoke"] = "窃听：可以移动装备或摸牌",
  ["ol_ex__qieting_move"] = "将%dest一张装备移动给你",

  ["$ol_ex__qieting1"] = "好你个刘玄德，敢坏我儿大事。",
  ["$ol_ex__qieting2"] = "两个大男人窃窃私语，定没有好事。",
}

qieting:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qieting.name) and target ~= player then
      local room = player.room
      return #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        return damage.from == target and damage.to ~= target
      end, Player.HistoryTurn) == 0 or
        #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          if use.from == target and table.find(use.tos, function(p)
            return p ~= target
          end) then
            return true
          end
        return false
      end, Player.HistoryTurn) == 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    local all_choices = {"ol_ex__qieting_move::"..target.id, "draw1", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if not target:canMoveCardsInBoardTo(player, "e") then
      table.remove(choices, 1)
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      all_choices = all_choices,
      prompt = "#ol_ex__qieting-invoke",
      skill_name = qieting.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"ol_ex__qieting_move::"..target.id, "draw1", "Cancel"}
    if event:getCostData(self).choice == "draw1" then
      player:drawCards(1, qieting.name)
      if player.dead or target.dead or not target:canMoveCardsInBoardTo(player, "e") then return false end
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == target and table.find(use.tos, function(p)
          return p ~= target
        end) then
          return true
        end
        return false
      end, Player.HistoryTurn) == 0 then
        if room:askToChoice(player, {
          choices = {"ol_ex__qieting_move::"..target.id, "Cancel"},
          skill_name = qieting.name,
          prompt = "#ol_ex__qieting-invoke",
          all_choices = all_choices,
        }) ~= "Cancel" then
          room:askToMoveCardInBoard(player, {
            target_one = target,
            target_two = player,
            skill_name = qieting.name,
            flag = "e",
            move_from = target,
          })
        end
      end
    else
      room:askToMoveCardInBoard(player, {
        target_one = target,
        target_two = player,
        skill_name = qieting.name,
        flag = "e",
        move_from = target,
      })
      if player.dead then return false end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == target and table.find(use.tos, function(p)
          return p ~= target
        end) then
          return true
        end
        return false
      end, Player.HistoryTurn) == 0 then
        if room:askToChoice(player, {
          choices = {"draw1", "Cancel"},
          skill_name = qieting.name,
          prompt = "#ol_ex__qieting-invoke",
          all_choices = all_choices,
        }) == "draw1" then
          player:drawCards(1, qieting.name)
        end
      end
    end
  end,
})

return qieting