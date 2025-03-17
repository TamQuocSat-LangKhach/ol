local langdao = fk.CreateSkill{
  name = "langdao",
  dynamic_desc = function(self, player)
    if #player:getTableMark("langdao_removed") == 3 then
      return "dummyskill"
    else
      local desc = {}
      for i = 1, 3, 1 do
        if not table.contains(player:getTableMark("langdao_removed"), "langdao"..i) then
          table.insert(desc, Fk:translate("langdao"..i))
        end
      end
      return "langdao_inner:"..table.concat(desc, "/")
    end
  end,
}

Fk:loadTranslationTable{
  ["langdao"] = "狼蹈",
  [":langdao"] = "当你使用【杀】指定唯一目标时，你可以与其同时选择一项，令此【杀】：伤害值+1/目标数+1/不能被响应。若未杀死角色，"..
  "你移除此次被选择的项。",

  [":langdao_inner"] = "当你使用【杀】指定唯一目标时，你可以与其同时选择一项，令此【杀】：{1}。若未杀死角色，"..
  "你移除此次被选择的项。",

  ["#langdao-invoke"] = "狼蹈：是否对 %dest 发动“狼蹈”，与其同时选择一项【杀】增益",
  ["#langdao-choice"] = "狼蹈：选择此【杀】的一种增益，若未杀死角色则移除此项",
  ["langdao1"] = "伤害值+1",
  ["langdao2"] = "目标数+1",
  ["langdao3"] = "不能被响应",
  ["#langdao-choose"] = "狼蹈：你可以为此%arg增加至多%arg2个目标",

  ["$langdao1"] = "虎踞黑山，望天下百城。",
  ["$langdao2"] = "狼顾四野，视幽冀为饵。",
}

local U = require("packages/utility/utility")

langdao:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(langdao.name) and data.card.trueName == "slash" and
      #data.use.tos == 1 and #player:getTableMark("langdao_removed") < 3
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = langdao.name,
      prompt = "#langdao-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choices = table.filter({"langdao1", "langdao2", "langdao3"}, function (str)
      return not table.contains(player:getTableMark("langdao_removed"), str)
    end)
    local result = U.askForJointChoice({player, data.to}, choices, langdao.name, "#langdao-choice", true)
    data.extra_data = data.extra_data or {}
    data.extra_data.langdao = {}
    local target_num = 0
    for _, choice in pairs(result) do
      table.insertIfNeed(data.extra_data.langdao, choice)
      if choice == "langdao1" then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif choice == "langdao2" then
        target_num = target_num + 1
      elseif choice == "langdao3" then
        data.disresponsive = true
      end
    end
    if target_num > 0 and #data:getExtraTargets() > 0 then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = target_num,
        targets = data:getExtraTargets(),
        skill_name = langdao.name,
        prompt = "#langdao-choose:::"..data.card:toLogString()..":"..target_num,
        cancelable = true,
      })
      if #tos > 0 then
        for _, p in ipairs(tos) do
          data:addTarget(p)
        end
      end
    end
  end,
})
langdao:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.langdao and not player.dead and
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        local death = e.data
        return death.damage and death.damage.card == data.card
      end, Player.HistoryPhase) == 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, str in ipairs(data.extra_data.langdao) do
      room:addTableMarkIfNeed(player, "langdao_removed", str)
    end
  end,
})

return langdao
