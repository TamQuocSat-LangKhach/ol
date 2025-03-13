local wuniang = fk.CreateSkill{
  name = "ol__wuniang",
}

Fk:loadTranslationTable{
  ["ol__wuniang"] = "武娘",
  [":ol__wuniang"] = "你的出牌阶段内限一次，当你使用指定唯一目标的【杀】结算后，你可以令其选择是否对你使用一张【杀】，"..
  "然后你摸一张牌并令你本阶段使用【杀】次数上限+1。",

  ["#ol__wuniang-invoke"] = "武娘：你可以令 %dest 对你使用一张【杀】，你摸一张牌并使用【杀】次数+1",
  ["#ol__wuniang-use"] = "武娘：你可以对 %src 使用一张【杀】",

  ["$ol__wuniang1"] = "虽为女子身，不输男儿郎。",
  ["$ol__wuniang2"] = "剑舞轻盈，沙场克敌。",
}

wuniang:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuniang.name) and
      data.card.trueName == "slash" and player.phase == Player.Play and
      #data.tos == 1 and not data.tos[1].dead and player:usedSkillTimes(wuniang.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = wuniang.name,
      prompt = "#ol__wuniang-invoke::"..data.tos[1].id,
    }) then
      event:setCostData(self, {tos = data.tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.tos[1]
    local use = room:askToUseCard(to, {
      skill_name = wuniang.name,
      pattern = "slash",
      prompt = "#ol__wuniang-use:"..player.id,
      extra_data = {
        exclusive_targets = {player.id},
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    end
    if not player.dead then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase")
      player:drawCards(1, wuniang.name)
    end
  end,
})

return wuniang
