local jianxuan = fk.CreateSkill{
  name = "jianxuan",
}

Fk:loadTranslationTable{
  ["jianxuan"] = "谏旋",
  [":jianxuan"] = "当你受到伤害后，你可以令一名角色摸一张牌，若其手牌数与〖刚述〗中的任意项相同，其重复此流程。",

  ["#jianxuan-choose"] = "谏旋：你可以令一名角色摸一张牌",

  ["$jianxuan1"] = "司马氏卧虎藏龙，大兄安能小觑。",
  ["$jianxuan2"] = "兄长以兽为猎，殊不知己亦为猎乎？",
}

local function gangshuTimesCheck(player, card)
  local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
  for _, skill in ipairs(status_skills) do
    if skill:bypassTimesCheck(player, card.skill, Player.HistoryPhase, card) then return true end
  end
  return false
end

jianxuan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = jianxuan.name,
      prompt = "#jianxuan-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local n = 0
    local card = Fk:cloneCard("slash")
    repeat
      to:drawCards(1, jianxuan.name)
      if to.dead or player.dead or not player:hasSkill("gangshu", true) then break end
      n = to:getHandcardNum()
    until n ~= player:getAttackRange() and n ~= player:getMark("gangshu2_fix") + 2 and
      (gangshuTimesCheck(player, card) or
      n ~= card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil))
  end,
})

return jianxuan
