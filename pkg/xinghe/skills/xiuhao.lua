local xiuhao = fk.CreateSkill{
  name = "xiuhao",
}

Fk:loadTranslationTable{
  ["xiuhao"] = "修好",
  [":xiuhao"] = "每名角色的回合限一次，你对其他角色造成伤害，或其他角色对你造成伤害时，你可以防止此伤害，令伤害来源摸两张牌。",

  ["#xiuhao-invoke"] = "修好：你可防止 %src 受到的伤害，令 %dest 摸两张牌",

  ["$xiuhao1"] = "吴蜀合同，可御魏敌。",
  ["$xiuhao2"] = "与吴修好，共为唇齿。",
}

xiuhao:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiuhao.name) and
      target and target ~= data.to and (target == player or data.to == player) and
      player:usedSkillTimes(xiuhao.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xiuhao.name,
      prompt = "#xiuhao-invoke:"..data.to.id..":"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    if not data.from.dead then
      data.from:drawCards(2, xiuhao.name)
    end
  end,
})

return xiuhao
