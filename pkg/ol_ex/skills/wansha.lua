local wansha = fk.CreateSkill {
  name = "ol_ex__wansha",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ol_ex__wansha"] = "完杀",
  [":ol_ex__wansha"] = "锁定技，你的回合内：只有你和处于濒死状态的角色可以使用【桃】；濒死流程中，除其以外的其他角色非锁定技无效。",

  ["$ol_ex__wansha1"] = "有谁敢试试？",
  ["$ol_ex__wansha2"] = "斩草务尽，以绝后患。",
}

wansha:addEffect("prohibit" ,{
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return Fk:currentRoom().current == p and p:hasSkill(wansha.name) and p ~= player
      end)
    end
  end,
})

wansha:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if table.find(Fk:currentRoom().players, function(p)
      return p.dying
    end) and
    table.find(Fk:currentRoom().alive_players, function(p)
      return Fk:currentRoom().current == p and p:hasSkill(wansha.name) and p ~= from
    end) and
    not from.dying then
      return table.contains(from.player_skills, skill) and skill:isPlayerSkill(from) and
        not skill:hasTag(Skill.Compulsory)
    end
  end,
})

wansha:addEffect(fk.EnterDying, {
  anim_type = "offensive",
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(wansha.name) and player.room.current == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, wansha.name)
    player:broadcastSkillInvoke(wansha.name)
  end,
})

return wansha