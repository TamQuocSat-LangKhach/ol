local jici = fk.CreateSkill{
  name = "jici",
}

Fk:loadTranslationTable{
  ["jici"] = "激词",
  [":jici"] = "当你的拼点牌亮出后，若点数不大于X，你可以令点数+X并视为此阶段未发动过〖鼓舌〗。（X为你“饶舌”标记的数量）。",

  ["$jici1"] = "谅尔等腐草之荧光，如何比得上天空之皓月？",
  ["$jici2"] = "你……诸葛村夫，你敢！",
}

jici:addEffect(fk.PindianCardsDisplayed, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jici.name) then
      if player == data.from then
        return data.fromCard.number <= player:getMark("@raoshe")
      elseif data.results[player] then
        return data.results[player].toCard.number <= player:getMark("@raoshe")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changePindianNumber(data, player, player:getMark("@raoshe"), jici.name)
    if player.phase == Player.Play then
      player:setSkillUseHistory("gushe", 0, Player.HistoryPhase)
    end
  end,
})

return jici
