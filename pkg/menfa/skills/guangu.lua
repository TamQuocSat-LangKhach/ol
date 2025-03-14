local guangu = fk.CreateSkill{
  name = "guangu",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["guangu"] = "观骨",
  [":guangu"] = "转换技，出牌阶段限一次，阳：你可以观看牌堆顶至多四张牌；阴：你可以观看一名角色至多四张手牌。然后你可以使用其中一张牌。",

  ["#guangu-yang"] = "观骨：你可以观看牌堆顶至多四张牌，然后使用其中一张牌",
  ["#guangu-yin"] = "观骨：你可以观看一名角色至多四张手牌，然后使用其中一张牌",
  ["#guangu-choice"] = "观骨：选择你要观看的牌数",
  ["@guangu-phase"] = "观骨",
  ["#guangu-use"] = "观骨：你可以使用其中一张牌",

  ["$guangu1"] = "此才拔萃，然观其形骨，恐早夭。",
  ["$guangu2"] = "绯衣者，汝所拔乎？",
}

guangu:addEffect("active", {
  anim_type = "switch",
  prompt = function(self, player)
    return "#guangu-"..player:getSwitchSkillState(guangu.name, false, true)
  end,
  card_num = 0,
  target_num = function(self, player)
    if player:getSwitchSkillState(guangu.name, false) == fk.SwitchYang then
      return 0
    else
      return 1
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(guangu.name, Player.HistoryPhase) == 0 and #Fk:currentRoom().draw_pile > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if player:getSwitchSkillState(guangu.name, false) == fk.SwitchYang then
      return false
    else
      return #selected == 0 and not to_select:isKongcheng()
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local status = player:getSwitchSkillState(guangu.name, true, true)
    local ids = {}
    local target
    if status == "yang" then
      local x = #room.draw_pile
      if x == 0 then return false end
      local data = {}
      for i = 1, math.min(4, x), 1 do
        table.insert(data, i)
      end
      local result = room:askToCustomDialog(player, {
        skill_name = guangu.name,
        qml_path = "packages/ol/qml/Guangu.qml",
        extra_data = data,
      })
      ids = room:getNCards(tonumber(result) or 1)
    else
      target = effect.tos[1]
      ids = room:askToChooseCards(player, {
        target = target,
        min = 1,
        max = 4,
        flag = "h",
        skill_name = guangu.name,
      })
    end
    room:setPlayerMark(player, "@guangu-phase", #ids)
    room:askToUseRealCard(player, {
      pattern = ids,
      skill_name = guangu.name,
      prompt = "#guangu-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = target ~= player and ids,
      }
    })
  end,
})

return guangu
