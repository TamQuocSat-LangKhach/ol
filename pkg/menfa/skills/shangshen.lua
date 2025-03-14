local shangshen = fk.CreateSkill{
  name = "shangshen",
}

Fk:loadTranslationTable{
  ["shangshen"] = "伤神",
  [":shangshen"] = "当每回合首次有角色受到属性伤害后，你可以进行一次【闪电】判定并令其将手牌摸至四张。",

  ["#shangshen-invoke"] = "伤神：你可以进行一次【闪电】判定并令 %dest 将手牌摸至四张",

  ["$shangshen1"] = "识字数万，此痛无字可言。",
  ["$shangshen2"] = "吾妻已逝，吾心悲怆。",
}

shangshen:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shangshen.name) and not target.dead and data.damageType ~= fk.NormalDamage and
      player:usedSkillTimes(shangshen.name, Player.HistoryTurn) == 0 then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        return damage.damageType ~= fk.NormalDamage
      end, Player.HistoryTurn)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shangshen.name,
      prompt = "#shangshen-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("fenchai") == 0 and player:compareGenderWith(target, true) then
      room:setPlayerMark(player, "fenchai", target.id)
    end
    local judge = {
      who = player,
      reason = "lightning",
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    if judge:matchPattern() then
      room:damage{
        to = player,
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = shangshen.name,
      }
    end
    if target.dead then return false end
    local n = 4 - target:getHandcardNum()
    if n > 0 then
      target:drawCards(n, shangshen.name)
    end
  end,
})

return shangshen
