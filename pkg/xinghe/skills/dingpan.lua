local dingpan = fk.CreateSkill{
  name = "dingpan",
}

Fk:loadTranslationTable{
  ["dingpan"] = "定叛",
  [":dingpan"] = "出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；"..
  "2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。",

  ["#dingpan"] = "定叛：令一名装备区里有牌的角色摸一张牌，然后其选择弃置装备或收回装备并受到你造成的伤害",
  ["dingpan_discard"] = "%src弃置你装备区里的一张牌",
  ["dingpan_damage"] = "收回所有装备，%src对你造成1点伤害",

  ["$dingpan1"] = "从孙者生，从刘者死！",
  ["$dingpan2"] = "多行不义必自毙！",
}

dingpan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#dingpan",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and
    #table.filter(Fk:currentRoom().alive_players, function (p)
      return p.role == "rebel"
    end) - player:usedSkillTimes(dingpan.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(dingpan.name, Player.HistoryPhase) <
      #table.filter(Fk:currentRoom().alive_players, function (p)
        return p.role == "rebel"
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #to_select:getCardIds("e") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:drawCards(1, dingpan.name)
    if target.dead then return end
    local choices = {"dingpan_damage:"..player.id}
    if #target:getCardIds("e") > 0 and not player.dead then
      table.insert(choices, 1, "dingpan_discard:"..player.id)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = dingpan.name,
      prompt = "#qqqqqq-choose",
    })
    if choice:startsWith("dingpan_discard") then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "e",
        skill_name = dingpan.name,
      })
      room:throwCard(id, dingpan.name, target, player)
    else
      room:moveCardTo(target:getCardIds("e"), Card.PlayerHand, target, fk.ReasonJustMove, dingpan.name, nil, true, target)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = dingpan.name,
        }
      end
    end
  end,
})

return dingpan
