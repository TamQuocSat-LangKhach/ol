local tuisheng = fk.CreateSkill{
  name = "tuisheng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["tuisheng"] = "蜕生",
  [":tuisheng"] = "限定技，准备阶段或当你进入濒死状态时，你可以重置你本轮使用过的〖赂存〗牌名，"..
    "然后选择一项并回复1点体力：1.将所有手牌置为“赂”；2.令当前回合角色获得所有“赂”，然后你回复1点体力。",

  ["tuisheng_push"] = "将你的所有手牌置为“赂”",
  ["tuisheng_give"] = "令%dest获得所有“赂”",

  ["$tuisheng1"] = "",
  ["$tuisheng2"] = "",
}

---@param self TriggerSkill
---@param event TriggerEvent
---@param player ServerPlayer
local tuishengCost = function(self, event, _, player, _)
  local room = player.room
  local all_choices = {"tuisheng_push", "Cancel"}
  local choices = {"tuisheng_push", "Cancel"}
  local to = room.current
  if to and not to.dead and to.phase ~= Player.NotActive then
    table.insert(all_choices, 2, "tuisheng_give::" .. to.id)
    if #player:getPile("olmou__zhangrang_lu") > 0 then
      choices = all_choices
    end
  end
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = tuisheng.name,
    all_choices = all_choices
  })
  if choice ~= "Cancel" then
    local dat = {
      choice = choice
    }
    if choice ~= "tuisheng_push" then
      dat.tos = { to }
    end
    event:setCostData(self, dat)
    return true
  end
end

---@param self TriggerSkill
---@param event TriggerEvent
---@param player ServerPlayer
local tuishengUse = function(self, event, _, player, _)
  local room = player.room
  room:setPlayerMark(player, "lucun-round", 0)
  local dat = event:getCostData(self)
  if dat.choice == "tuisheng_push" then
    if not player:isKongcheng() then
      player:addToPile("olmou__zhangrang_lu", player:getCardIds(Player.Hand), true, tuisheng.name, player)
      if player.dead then return false end
    end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = tuisheng.name
      }
    end
  else
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = tuisheng.name
      }
      if player.dead then return false end
    end
    local cards = player:getPile("olmou__zhangrang_lu")
    if #cards > 0 and not room.current.dead then
      room:obtainCard(room.current, cards, true, fk.ReasonGive, player, tuisheng.name)
      if player.dead then return false end
    end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = tuisheng.name
      }
    end
  end
end

tuisheng:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and
      player:hasSkill(tuisheng.name) and player:usedSkillTimes(tuisheng.name, Player.HistoryGame) == 0
  end,
  on_cost = tuishengCost,
  on_use = tuishengUse,
})

tuisheng:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.hp < 1 and
      player:hasSkill(tuisheng.name) and player:usedSkillTimes(tuisheng.name, Player.HistoryGame) == 0
  end,
  on_cost = tuishengCost,
  on_use = tuishengUse,
})

return tuisheng
