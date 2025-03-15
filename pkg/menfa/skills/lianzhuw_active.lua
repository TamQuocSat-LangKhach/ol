local lianzhuw_active = fk.CreateSkill{
  name = "lianzhuw&",
}

Fk:loadTranslationTable{
  ["lianzhuw&"] = "联诛",
  [":lianzhuw&"] = "出牌阶段限一次，若吴匡的〖联诛〗为：阳：你可以与其各重铸一张牌，若颜色相同，其手牌上限+1；"..
  "阴：其选择一名在你或其攻击范围内的角色，你可以与吴匡各对目标使用一张【杀】，若颜色不同，其手牌上限-1。",

  ["#lianzhuw_active-yang"] = "联诛：你可以与 %src 各重铸一张牌",
  ["#lianzhuw_active-yin"] = "联诛：%src 选择一名在你或其攻击范围内的角色，你与其依次可以对目标使用一张【杀】",
}

lianzhuw_active:addEffect("active", {
  mute = true,
  prompt = function (self, player, selected_cards, selected_targets)
    local p = table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill("lianzhuw") and p ~= player
    end)
    if p then
      return "#lianzhuw_active-"..p:getSwitchSkillState("lianzhuw", false, true)..":"..p.id
    end
  end,
  card_num = function(self, player)
    local p = table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill("lianzhuw") and p ~= player
    end)
    if p then
      if p:getSwitchSkillState("lianzhuw", false) == fk.SwitchYang then
        return 1
      else
        return 0
      end
    end
    return 0
  end,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(lianzhuw_active.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p:hasSkill("lianzhuw") and p ~= player
      end)
  end,
  card_filter = function(self, player, to_select, selected)
    local p = table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill("lianzhuw") and p ~= player
    end)
    if p then
      if p:getSwitchSkillState("lianzhuw", false) == fk.SwitchYang then
        return #selected == 0
      else
        return false
      end
    end
    return false
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local src = table.find(room.alive_players, function (p)
      return p:hasSkill("lianzhuw") and p ~= player
    end)
    if not src then return end
    room:doIndicate(player.id, {src.id})
    room:setPlayerMark(src, MarkEnum.SwithSkillPreName.."lianzhuw", src:getSwitchSkillState("lianzhuw", true))
    src:addSkillUseHistory("lianzhuw")
    src:broadcastSkillInvoke("lianzhuw")
    room:notifySkillInvoked(src, "lianzhuw", "switch")

    if src:getSwitchSkillState("lianzhuw", true) == fk.SwitchYang then
      local color = Fk:getCardById(effect.cards[1]):getColorString()
      room:recastCard(effect.cards, player, "lianzhuw")
      local prompt = "#lianzhuw1-card:::"..color
      if color == "nocolor" then
        prompt = "#lianzhuw2-card"
      end
      local card = room:askToCards(src, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = "lianzhuw",
        prompt = prompt,
        cancelable = true,
      })
      if #card > 0 then
        if color ~= "nocolor" then
          local color2 = Fk:getCardById(card[1]):getColorString()
          if color2 ~= "nocolor" and color2 == color then
            room:addPlayerMark(src, MarkEnum.AddMaxCards, 1)
          end
        end
        room:recastCard(card, src, "lianzhuw")
        if src.dead then return end
      end
    else
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return (player:inMyAttackRange(p) or src:inMyAttackRange(p)) and p ~= src
      end)
      if #targets == 0 then return end
      local target = room:askToChoosePlayers(src, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = "lianzhuw",
        prompt = "#lianzhuw2-choose:"..player.id,
        cancelable = false,
      })[1]
      local use1 = room:askToUseCard(player, {
        skill_name = "lianzhuw",
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
        room:useCard(use1)
      end
      if not src.dead and not target.dead then
        local color = "nocolor"
        local prompt = "#lianzhuw-slash::"..target.id
        if use1 then
          color = use1.card:getColorString()
          prompt = "#lianzhuw1-slash::"..target.id..":"..color
          if color == "nocolor" then
            prompt = "#lianzhuw-slash::"..target.id
          end
        end
        local use2 = room:askToUseCard(src, {
          skill_name = "lianzhuw",
          pattern = "slash",
          prompt = prompt,
          extra_data = {
            must_targets = {target.id},
            bypass_times = true,
          }
        })
        if use2 then
          if color ~= "nocolor" then
            local color2 = use2.card:getColorString()
            if color2 ~= "nocolor" and color2 ~= color and src:getMaxCards() > 0 then
              room:addPlayerMark(src, MarkEnum.MinusMaxCards, 1)
            end
          end
          room:useCard(use2)
        end
      end
    end
  end,
})

return lianzhuw_active
