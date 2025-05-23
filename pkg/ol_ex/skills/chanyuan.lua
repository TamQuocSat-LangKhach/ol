local chanyuan = fk.CreateSkill {
  name = "ol_ex__chanyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__chanyuan"] = "缠怨",
  [":ol_ex__chanyuan"] = "锁定技，你不能质疑〖蛊惑〗；若你的体力值小于等于1，你的其他技能失效。",

  ["@@ol_ex__chanyuan"] = "缠怨",

  ["$ol_ex__chanyuan1"] = "此咒甚重，怨念缠身。",
  ["$ol_ex__chanyuan2"] = "不信吾法，无福之缘。",
}

chanyuan:addAcquireEffect(function (self, player, is_start)
  if player.hp <= 1 then
    player.room:setPlayerMark(player, "@@ol_ex__chanyuan", 1)
  end
end)
chanyuan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@ol_ex__chanyuan", 0)
end)

chanyuan:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:hasSkill(self, true, true) and from.hp <= 1 and skill:isPlayerSkill(from)
  end
})

chanyuan:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(chanyuan.name) or player:isFakeSkill("ol_ex__chanyuan") then return end
      return player.hp <= 1 and data.num < 0 and (player.hp - data.num) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "ol_ex__chanyuan", "negative")
    player:broadcastSkillInvoke("ol_ex__chanyuan")
  end,
})

return chanyuan
