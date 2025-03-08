local dongdao = fk.CreateSkill{
  name = "dongdao",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["dongdao"] = "东道",
  [":dongdao"] = "转换技，阳：农民回合结束后，你可以令地主执行一个额外回合；"..
  "阴：农民回合结束后，其可以执行一个额外回合。（仅斗地主模式生效）",

  ["#dongdao_yang-invoke"] = "东道：你可以令 %dest 执行一个额外回合",
  ["#dongdao_yin-invoke"] = "东道：你可以发动 %src 的“东道”，执行一个额外回合",

  ["$dongdao1"] = "阿瞒远道而来，老夫当尽地主之谊！",
  ["$dongdao2"] = "我乃嵩兄故交，孟德来此可无忧虑。",
}

dongdao:addEffect(fk.TurnEnd, {
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "dongdao"
    else
      return "dummyskill"
    end
  end,
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return player.room:isGameMode("1v2_mode") and player:hasSkill(dongdao.name) and target.role == "rebel"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(dongdao.name, false) == fk.SwitchYang then
      if room:askToSkillInvoke(player, {
        skill_name = dongdao.name,
        prompt = "#dongdao_yang-invoke::"..room:getLord().id,
      }) then
        event:setCostData(self, {tos = {room:getLord()}})
        return true
      end
    else
      if room:askToSkillInvoke(target, {
        skill_name = dongdao.name,
        prompt = "#dongdao_yin-invoke:"..player.id,
      }) then
        event:setCostData(self, {tos = {target}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:gainAnExtraTurn(true, dongdao.name)
  end,
})

return dongdao
