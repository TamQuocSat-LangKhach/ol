local huanjia = fk.CreateSkill{
  name = "huanjia",
}

Fk:loadTranslationTable{
  ["huanjia"] = "缓颊",
  [":huanjia"] = "出牌阶段结束时，你可以与一名角色拼点，赢的角色可以使用一张拼点牌，若此牌：未造成伤害，你获得另一张拼点牌；造成了伤害，"..
  "你失去一个技能。",

  ["#huanjia-choose"] = "缓颊：你可以拼点，赢的角色可以使用一张拼点牌",
  ["#huanjia-use"] = "缓颊：你可以使用一张拼点牌，若未造成伤害则 %src 获得另一张，若造成伤害则其失去一个技能",
  ["#huanjia-choice"] = "缓颊：你需失去一个技能",

  ["$huanjia1"] = "我之所言，皆为君好。",
  ["$huanjia2"] = "吾言之切切，请君听之。",
}

huanjia:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huanjia.name) and player.phase == Player.Play and
      not player:isKongcheng() and
      table.find(player.room.alive_players, function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = huanjia.name,
      prompt = "#huanjia-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({to}, huanjia.name)
    local winner = pindian.results[to].winner
    if not winner or winner.dead then return end
    local ids = {}
    table.insert(ids, pindian.fromCard:getEffectiveId())
    table.insert(ids, pindian.results[to].toCard:getEffectiveId())
    ids = table.filter(ids, function(id)
      return table.contains(room.discard_pile, id) and winner:canUse(Fk:getCardById(id), { bypass_times = true })
    end)
    if #ids == 0 then return end
    local use = room:askToUseRealCard(winner, {
      pattern = ids,
      skill_name = huanjia.name,
      prompt = "#huanjia-use:" .. player.id,
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = ids,
      },
    })
    if use and not player.dead then
      if use.damageDealt then
        if #player:getSkillNameList() > 0 then
          local choice = room:askToChoice(player, {
            choices = player:getSkillNameList(),
            skill_name = huanjia.name,
            prompt = "#huanjia-choice",
          })
          room:handleAddLoseSkills(player, "-"..choice)
        end
      else
        local id = pindian.fromCard.id
        if id == use.card:getEffectiveId() then
          id = pindian.results[to].toCard.id
        end
        if table.contains(room.discard_pile, id) then
          room:obtainCard(player, id, true, fk.ReasonJustMove, player, huanjia.name)
        end
      end
    end
  end,
})

return huanjia
