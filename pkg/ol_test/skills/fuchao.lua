local fuchao = fk.CreateSkill{
  name = "fuchao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fuchao"] = "覆巢",
  [":fuchao"] = "锁定技，你响应其他角色使用的牌后，你选择一项：1.弃置你与其各一张牌，然后其他角色不能响应此牌；2.令此牌对其他角色无效，然后"..
  "对你额外结算一次。",

  ["#fuchao-choice"] = "覆巢：你抵消了 %dest 使用的%arg，请选择一项",
  ["fuchao1"] = "弃置你与%dest各一张牌，其他角色不能响应此牌",
  ["fuchao2"] = "此牌对其他角色无效，对你额外结算一次",
  ["#fuchao-discard"] = "覆巢：弃置 %dest 一张牌",

  ["$fuchao1"] = "",
  ["$fuchao2"] = "",
}

local fuchao_spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuchao.name) and
      data.responseToEvent and data.responseToEvent.from ~= player and data.responseToEvent.card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use_event = nil
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      local u = e.data
      if u.from == data.responseToEvent.from and u.card == data.responseToEvent.card then
        use_event = e
        return true
      end
    end, 1)
    if use_event == nil then return end
    local use = use_event.data
    local to = use.from
    local all_choices = {"fuchao1::"..to.id, "fuchao2"}
    --[[if to.dead or to:isNude() or player:isNude() then
      table.remove(choices, 1)
    end]]--  盲猜可以空发
    local choice = room:askToChoice(player, {
      choices = all_choices,
      skill_name = fuchao.name,
      prompt = "#fuchao-choice::"..to.id..":"..use.card:toLogString(),
      all_choices = all_choices,
    })
    if choice == "fuchao2" then
      if #use.tos > 0 then
        use.nullifiedTargets = table.simpleClone(room:getOtherPlayers(player, false))
        use.additionalEffect = (use.additionalEffect or 0) + 1
      end
    else
      if not player:isNude() then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = fuchao.name,
          cancelable = false,
        })
      end
      if not player.dead and not to.dead and not to:isNude() then
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = fuchao.name,
          prompt = "#fuchao-discard::"..to.id,
        })
        room:throwCard(card, fuchao.name, to, player)
      end
      use.disresponsiveList = use.disresponsiveList or {}
      table.insertTableIfNeed(use.disresponsiveList, room:getOtherPlayers(player, false))
    end
  end,
}

fuchao:addEffect(fk.CardUseFinished, fuchao_spec)
fuchao:addEffect(fk.CardRespondFinished, fuchao_spec)

return fuchao
