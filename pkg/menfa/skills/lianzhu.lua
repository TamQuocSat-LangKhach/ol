local lianzhu = fk.CreateSkill{
  name = "lianzhuw",
  tags = { Skill.Switch },
  attached_skill_name = "lianzhuw&",
}

Fk:loadTranslationTable{
  ["lianzhuw"] = "联诛",
  [":lianzhuw"] = "转换技，每名角色出牌阶段限一次，阳：其可以与你各重铸一张牌，若颜色相同，你的手牌上限+1；"..
  "阴：你选择一名在你或其攻击范围内的角色，其可以与你各对目标使用一张【杀】，若颜色不同，你的手牌上限-1。",

  ["#lianzhuw-yang"] = "联诛：你可以依次重铸两张牌，若颜色相同，你手牌上限+1",
  ["#lianzhuw-yin"] = "联诛：选择一名攻击范围内的角色，你可以依次对其使用两张【杀】，若颜色不同，你手牌上限-1",
  ["#lianzhuw1-card"] = "联诛：你可以重铸一张牌，若为%arg，你手牌上限+1",
  ["#lianzhuw2-card"] = "联诛：你可以重铸一张牌",
  ["#lianzhuw1-choose"] = "联诛：选择一名你攻击范围内的角色",
  ["#lianzhuw2-choose"] = "联诛：选择一名你或 %src 攻击范围内的角色",
  ["#lianzhuw1-slash"] = "联诛：你可以对 %dest 使用一张【杀】，若不为%arg，你手牌上限-1",
  ["#lianzhuw-slash"] = "联诛：你可以对 %dest 使用一张【杀】",

  ["$lianzhuw1"] = "奸宦作乱，当联兵伐之。",
  ["$lianzhuw2"] = "尽诛贼常侍，正在此时。",
}

lianzhu:addEffect("active", {
  anim_type = "switch",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#lianzhuw-"..player:getSwitchSkillState(lianzhu.name, false, true)
  end,
  card_num = function(self, player)
    if player:getSwitchSkillState(lianzhu.name, false) == fk.SwitchYang then
      return 1
    else
      return 0
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(lianzhu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if player:getSwitchSkillState(lianzhu.name, false) == fk.SwitchYang then
      return #selected == 0
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:getSwitchSkillState(lianzhu.name, true) == fk.SwitchYang then
      local color = Fk:getCardById(effect.cards[1]):getColorString()
      room:recastCard(effect.cards, player, lianzhu.name)
      if player.dead or player:isNude() then return end
      local prompt = "#lianzhuw1-card:::"..color
      if color == "nocolor" then
        prompt = "#lianzhuw2-card"
      end
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = lianzhu.name,
        prompt = prompt,
        cancelable = true,
      })
      if #card > 0 then
        if color ~= "nocolor" then
          local color2 = Fk:getCardById(card[1]):getColorString()
          if color2 ~= "nocolor" and color2 == color then
            room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
          end
        end
        room:recastCard(card, player, lianzhu.name)
        if player.dead then return end
      end
    else
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return player:inMyAttackRange(p)
      end)
      if #targets == 0 then return end
      local target = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = lianzhu.name,
        prompt = "#lianzhuw1-choose",
        cancelable = false,
      })[1]
      local use1 = room:askToUseCard(player, {
        skill_name = lianzhu.name,
        pattern = "slash",
        prompt = "#lianzhuw-slash::"..target.id,
        extra_data = {
          must_targets = {target.id},
          bypass_distances = true,
          bypass_times = true,
        }
      })
      if use1 then
        use1.extraUse = true
        local color = use1.card:getColorString()
        room:useCard(use1)
        if not player.dead and not target.dead then
          local prompt = "#lianzhuw1-slash::"..target.id..":"..color
          if color == "nocolor" then
            prompt = "#lianzhuw-slash::"..target.id
          end
          local use2 = room:askToUseCard(player, {
            skill_name = lianzhu.name,
            pattern = "slash",
            prompt = prompt,
            extra_data = {
              must_targets = {target.id},
              bypass_times = true,
            }
          })
          if use2 then
            use2.extraUse = true
            if color ~= "nocolor" then
              local color2 = use2.card:getColorString()
              if color2 ~= "nocolor" and color2 ~= color and player:getMaxCards() > 0 then
                room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
              end
            end
            room:useCard(use2)
          end
        end
      end
    end
  end,
})

return lianzhu
