local shuzi = fk.CreateSkill{
  name = "shuzi",
}

Fk:loadTranslationTable{
  ["shuzi"] = "束辎",
  [":shuzi"] = "出牌阶段限一次，你可以交给一名角色两张牌，然后其交给你一张手牌，若此牌牌名与你交给其的牌中有牌名相同，你可以选择一项："..
  "1.对其造成1点伤害；2.将场上一张牌移动至其场上对应的区域。",

  ["#shuzi"] = "束辎：交给一名角色两张牌，然后其交给你一张手牌，若其中有牌名相同，你可以对其执行选项",
  ["#shuzi-give"] = "束辎：请交给 %src 一张手牌，若与其交给你的牌牌名相同，其可以对你执行选项",
  ["#shuzi-choice"] = "束辎：你可以对 %dest 执行一项",
  ["shuzi_damage"] = "对其造成1点伤害",
  ["shuzi_move"] = "将场上一张牌移动至其场上",
  ["#shuzi-move"] = "束辎：你可以选择一名角色，将其场上一张牌移至 %dest 场上",

  ["$shuzi1"] = "本初啊，冀州虽大，却也没有余粮！",
  ["$shuzi2"] = "不是韩某小气，是实在没有一粒米了。",
}

shuzi:addEffect("active", {
  anim_type = "control",
  prompt = "#shuzi",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shuzi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local names = table.map(effect.cards, function (id)
      return Fk:getCardById(id).trueName
    end)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, shuzi.name, nil, false, player)
    if player.dead or target.dead or target:isKongcheng() then return end
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = shuzi.name,
      prompt = "#shuzi-give:"..player.id,
      cancelable = false,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, shuzi.name, nil, false, target)
    if player.dead or target.dead then return end
    if table.contains(names, Fk:getCardById(card[1]).trueName) then
      local choices = {"shuzi_damage", "Cancel"}
      if table.find(room:getOtherPlayers(target), function (p)
        return p:canMoveCardsInBoardTo(target)
      end) then
        table.insert(choices, 2, "shuzi_move")
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = shuzi.name,
        prompt = "#shuzi-choice::"..target.id,
        all_choices = {"shuzi_damage", "shuzi_move", "Cancel"},
      })
      if choice == "shuzi_damage" then
        room:doIndicate(player, {target})
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = shuzi.name,
        }
      elseif choice == "shuzi_move" then
        local targets = table.filter(room:getOtherPlayers(target), function (p)
          return p:canMoveCardsInBoardTo(target)
        end)
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = shuzi.name,
          prompt = "#shuzi-move::"..target.id,
          cancelable = true,
        })
        if #to > 0 then
          room:askToMoveCardInBoard(player, {
            target_one = to,
            target_two = target,
            skill_name = shuzi.name,
            move_from = to,
          })
        end
      end
    end
  end,
})

return shuzi
