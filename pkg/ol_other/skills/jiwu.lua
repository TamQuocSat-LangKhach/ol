local jiwu = fk.CreateSkill{
  name = "jiwu",
}

Fk:loadTranslationTable{
  ["jiwu"] = "极武",
  [":jiwu"] = "出牌阶段，你可以弃置一张牌，然后本回合你拥有以下其中一个技能：〖强袭〗〖铁骑〗〖旋风〗〖完杀〗。",

  ["#jiwu"] = "极武：弃置一张牌，本回合获得一项技能",

  ["$jiwu1"] = "我！是不可战胜的！",
  ["$jiwu2"] = "今天！就让你们感受一下真正的绝望！",
  ["$qiangxi_hulao3__godlvbu1"] = "这么想死，那我就成全你！",
  ["$qiangxi_hulao3__godlvbu2"] = "项上人头，待我来取！",
  ["$ex__tieji_hulao3__godlvbu1"] = "哈哈哈！破绽百出！",
  ["$ex__tieji_hulao3__godlvbu2"] = "我要让这虎牢关下，血流成河！",
  ["$xuanfeng_hulao3__godlvbu1"] = "千钧之势，力贯苍穹！",
  ["$xuanfeng_hulao3__godlvbu2"] = "风扫六合，威震八荒！",
  ["$wansha_hulao3__godlvbu1"] = "蝼蚁！怎容偷生！",
  ["$wansha_hulao3__godlvbu2"] = "沉沦吧！在这无边的恐惧！",
}

jiwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#jiwu",
  card_num = 1,
  target_num = 0,
  interaction = function(self, player)
    local jiwu_skills = table.filter({"qiangxi", "ex__tieji", "xuanfeng", "wansha"}, function (skill_name)
      return not player:hasSkill(skill_name, true)
    end)
    if #jiwu_skills == 0 then return end
    return UI.ComboBox { choices = jiwu_skills }
  end,
  can_use = function(self, player)
    local jiwu_skills = {"qiangxi", "ex__tieji", "xuanfeng", "wansha"}
    return not table.every(jiwu_skills, function (skill_name)
      return player:hasSkill(skill_name, true)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local skill_name = self.interaction.data
    room:throwCard(effect.cards, jiwu.name, player, player)
    if player.dead then return end
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event ~= nil then
      room:handleAddLoseSkills(player, skill_name)
      turn_event:addCleaner(function()
        room:handleAddLoseSkills(player, "-"..skill_name)
      end)
    end
  end,
})

return jiwu
