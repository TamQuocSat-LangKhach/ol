local haizhong = fk.CreateSkill{
  name = "qin__haizhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__haizhong"] = "害忠",
  [":qin__haizhong"] = "锁定技，每回合限十四次，非秦势力角色回复体力后，其需选择一项：1.弃置一张红色牌，2.受到X点伤害"..
  "（X为其拥有的“害”标记数，至少为1）。然后其获得一个“害”标记。",

  ["@qin__haizhong"] = "害",
  ["#qin__haizhong-invoke"] = "害忠：你需弃置一张红色牌，否则 %src 对你造成%arg点伤害",

  ["$qin__haizhong"] = "违逆我的，可都没有好下场。",
}

haizhong:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if not table.find(room.alive_players, function (p)
    return p:hasSkill(haizhong.name, true)
  end) then
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@qin__haizhong", 0)
    end
  end
end)

haizhong:addEffect(fk.HpRecover, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(haizhong.name) and target.kingdom ~= "qin" and
      player:usedSkillTimes(haizhong.name, Player.HistoryTurn) < 15 and
      not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(target:getMark("@qin__haizhong"), 1)
    if #room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = haizhong.name,
      pattern = ".|.|heart,diamond",
      prompt = "#qin__haizhong-invoke:"..player.id.."::"..n,
      cancelable = true,
    }) == 0 then
      room:damage{
        from = player,
        to = target,
        damage = n,
        skillName = haizhong.name,
      }
    end
    if not target.dead then
      room:addPlayerMark(target, "@qin__haizhong", 1)
    end
  end,
})

return haizhong
