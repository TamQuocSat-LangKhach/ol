local lianji = fk.CreateSkill{
  name = "lianji",
}

Fk:loadTranslationTable{
  ["lianji"] = "连计",
  [":lianji"] = "出牌阶段限一次，你可以弃置一张手牌并指定一名其他角色，其使用牌堆中的一张随机武器牌，然后令其选择一项：1.对其攻击范围内"..
  "你指定的一名角色使用【杀】；2.你将其装备区的武器牌交给任意一名角色。",

  ["#lianji"] = "连计：弃一张手牌并选择一名角色，其使用随机一张武器，然后选择对你指定的角色使用【杀】或交出武器",
  ["#lianji-choose"] = "连计：选择令 %dest 使用【杀】的目标",
  ["#lianji-slash"] = "连计：你需对 %dest 使用【杀】，否则 %src 将你的武器牌交给任意角色",
  ["#lianji-card"] = "连计：将 %dest 的武器交给一名角色",

  ["$lianji1"] = "两计扣用，以催强势。",
  ["$lianji2"] = "容老夫细细思量。",
}

lianji:addEffect("active", {
  anim_type = "control",
  prompt = "#lianji",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lianji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, lianji.name, player, player)
    if target.dead then return end
    local cards = table.filter(room.draw_pile, function(id)
      return Fk:getCardById(id).sub_type == Card.SubtypeWeapon and
        target:canUseTo(Fk:getCardById(id), target)
    end)
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        room:moveCardTo(card, Card.Void, nil, fk.ReasonJustMove, lianji.name)
        card = room:printCard("seven_stars_sword", Card.Spade, 6)
      end
      if target:canUseTo(card, target) then
        room:useCard{
          from = target,
          tos = {target},
          card = card,
        }
      end
    end
    if target.dead or player.dead then return end
    local targets = table.filter(room:getOtherPlayers(target, false), function (p)
      return target:inMyAttackRange(p)
    end)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = lianji.name,
        prompt = "#lianji-choose::"..target.id,
        cancelable = false,
        no_indicate = true,
      })[1]
      room:doIndicate(target, {to})
      local use = room:askToUseCard(target, {
        skill_name = lianji.name,
        pattern = "slash",
        prompt = "#lianji-slash:"..player.id..":"..to.id,
        extra_data = {
          exclusive_targets = {to.id},
          bypass_times = true,
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
        if use.damageDealt then
          room:addPlayerMark(player, "moucheng", 1)
        end
        return
      end
    end
    if #target:getEquipments(Card.SubtypeWeapon) > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = lianji.name,
        prompt = "#lianji-card::"..target.id,
        cancelable = false,
      })[1]
      room:moveCardTo(target:getEquipments(Card.SubtypeWeapon), Card.PlayerHand, to, fk.ReasonGive, lianji.name, nil, true, player)
    end
  end,
})

return lianji
