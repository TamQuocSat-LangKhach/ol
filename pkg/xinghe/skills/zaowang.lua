local zaowang = fk.CreateSkill{
  name = "zaowang",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zaowang"] = "造王",
  [":zaowang"] = "限定技，出牌阶段，你可以令一名角色增加1点体力上限、回复1点体力并摸三张牌，若其为："..
  "忠臣，当主公死亡时与主公交换身份牌；反贼，当其被主公或忠臣杀死时，主公方获胜。",

  ["#zaowang"] = "造王：令一名角色加1点体力上限、回复1点体力并摸三张牌，根据其身份改变胜利条件！",
  ["@@zaowang"] = "造王",

  ["$zaowang1"] = "大魏当兴，吾主可王。",
  ["$zaowang2"] = "身加九锡，当君不让。",
}

zaowang:addEffect("active", {
  anim_type = "control",
  prompt = "#zaowang",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zaowang.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(target, "@@zaowang", 1)
    local banner = room:getBanner(zaowang.name) or {}
    if target.role == "loyalist" or target.role == "rebel" then
      banner[target.role] = banner[target.role] or {}
      table.insertIfNeed(banner[target.role], target.id)
    end
    room:setBanner(zaowang.name, banner)
    room:changeMaxHp(target, 1)
    if target.dead then return end
    if target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = zaowang.name,
      }
      if target.dead then return end
    end
    target:drawCards(3, zaowang.name)
  end,
})
zaowang:addEffect(fk.GameOverJudge, {
  can_refresh = function(self, event, target, player, data)
    local banner = player.room:getBanner(zaowang.name) or {}
    if table.contains(banner["loyalist"] or {}, player.id) then
      return not player.dead and target.role == "lord"
    elseif table.contains(banner["rebel"] or {}, player.id) then
      return target == player and data.killer and
        (data.killer.role == "lord" or data.killer.role == "loyalist")
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local banner = room:getBanner(zaowang.name) or {}
    if table.contains(banner["loyalist"] or {}, player.id) then
      room:setPlayerMark(player, "@@zaowang", 0)
      player.role, target.role = target.role, player.role
      room:setPlayerProperty(player, "role_shown", true)
      room:setPlayerProperty(target, "role_shown", true)
      room:broadcastProperty(player, "role")
      room:broadcastProperty(target, "role")
    elseif table.contains(banner["rebel"] or {}, player.id) then
      room:gameOver("lord+loyalist")
    end
  end,
})

return zaowang
