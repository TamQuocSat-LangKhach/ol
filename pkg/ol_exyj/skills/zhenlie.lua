local zhenlie = fk.CreateSkill{
  name = "ol_ex__zhenlie",
}

Fk:loadTranslationTable{
  ["ol_ex__zhenlie"] = "贞烈",
  [":ol_ex__zhenlie"] = "当你成为【杀】或普通锦囊牌的目标后，若使用者不为你，你可以失去1点体力，令此牌对你无效，"..
  "你选择：1.获得使用者的一张牌；2.于当前回合（你的回合除外）的结束阶段发动〖秘计〗。",

  ["#ol_ex__zhenlie-invoke"] = "贞烈：是否失去1点体力，令 %src 使用的%arg对你无效？",
  ["ol_ex__zhenlie_prey"] = "获得%dest一张牌",
  ["ol_ex__zhenlie_miji"] = "于结束阶段发动〖秘计〗",
  ["@@ol_ex__zhenlie-turn"] = "贞烈",
}

zhenlie:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenlie.name) and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhenlie.name,
      prompt = "#ol_ex__zhenlie-invoke:"..data.from.."::".. data.card:toLogString()})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, zhenlie.name)
    if player.dead then return false end
    table.insertIfNeed(data.use.nullifiedTargets, player)
    local choices = {}
    local to = data.from
    if not (to.dead or to:isNude()) then
      table.insert(choices, "ol_ex__zhenlie_prey::"..data.from.id)
    end
    if player:isWounded() and player:hasSkill("ol_ex__miji", true) then
      table.insert(choices, "ol_ex__zhenlie_miji")
    end
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
      choices = choices,
      all_choices = {"ol_ex__zhenlie_prey::"..data.from.id, "ol_ex__zhenlie_miji"},
      skill_name = zhenlie.name,
      cancelable = false,
    })
    if choice:startsWith("ol_ex__zhenlie_prey") then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = zhenlie.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, zhenlie.name)
    elseif choice == "ol_ex__zhenlie_miji" then
      room:setPlayerMark(player, "@@ol_ex__zhenlie-turn", 1)
    end
  end,
})

return zhenlie