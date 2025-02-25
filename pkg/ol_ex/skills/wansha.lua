local this = fk.CreateSkill {
  name = "ol_ex__wansha"
}

this:addEffect(fk.EnterDying, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(this.name) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, this.name)
    player:broadcastSkillInvoke(this.name)
  end,
})

this:addEffect("prohibit" ,{
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasSkill(this.name) and p ~= player
      end)
    end
  end,
})

this:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if table.contains(from.player_skills, skill) and not from.dying and skill.frequency ~= Skill.Compulsory
    and skill.frequency ~= Skill.Wake and skill:isPlayerSkill(from) then
      return table.find(Fk:currentRoom().players, function(p)
        return p.dying
      end) and table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasSkill(this.name) and p ~= from
      end)
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__wansha"] = "完杀",
  [":ol_ex__wansha"] = "锁定技，①除进行濒死流程的角色以外的其他角色于你的回合内不能使用【桃】。②在一名角色于你的回合内进行的濒死流程中，除其以外的其他角色的不带“锁定技”标签的技能无效。",

  ["$ol_ex__wansha1"] = "有谁敢试试？",
  ["$ol_ex__wansha2"] = "斩草务尽，以绝后患。",
}

return this