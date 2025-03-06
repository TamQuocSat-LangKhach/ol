local pingduan = fk.CreateSkill{
  name = "pingduan",
}

Fk:loadTranslationTable{
  ["pingduan"] = "平端",
  [":pingduan"] = "出牌阶段限一次，你可以令一名角色依次执行：1.使用一张基本牌；2.重铸一张锦囊牌；3.令你获得其装备区一张牌。其每执行一项"..
  "便摸一张牌。",

  ["#pingduan"] = "平端：令一名角色依次执行选项，其每执行一项摸一张牌",
  ["#pingduan-use"] = "平端：你可以使用一张基本牌，摸一张牌",
  ["#pingduan-recast"] = "平端：你可以重铸一张锦囊牌，摸一张牌",
  ["#pingduan-equip"] = "平端：你可以令 %src 获得你装备区一张牌，你摸一张牌",
  ["#pingduan-prey"] = "平端：获得 %dest 装备区一张牌",

  ["$pingduan1"] = "草原儿郎，张弓善射，勇不可当。",
  ["$pingduan2"] = "策马逐雄鹰，孤当与尔等共分天下。",
}

pingduan:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#pingduan",
  can_use = function(self, player)
    return player:usedSkillTimes(pingduan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]

    local all_names = Fk:getAllCardNames("b")
    local names = table.filter(all_names, function (name)
      local card = Fk:cloneCard(name)
      return target:canUse(card, {bypass_times = true}) and not target:prohibitUse(card)
    end)
    local use = room:askToUseCard(target, {
      skill_name = pingduan.name,
      pattern = table.concat(names, ","),
      prompt = "#pingduan-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
      if not target.dead then
        target:drawCards(1, pingduan.name)
      else
        return
      end
    end

    if not target:isNude() then
      local card = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = pingduan.name,
        pattern = ".|.|.|.|.|trick",
        prompt = "#pingduan-recast",
        cancelable = true,
      })
      if #card > 0 then
        room:recastCard(card, target, pingduan.name)
        if not target.dead then
          target:drawCards(1, pingduan.name)
        else
          return
        end
      end
    end

    if player.dead or #target:getCardIds("e") == 0 then return end
    if room:askToSkillInvoke(target, {
      skill_name = pingduan.name,
      "#pingduan-equip:"..player.id,
    }) then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "e",
        skill_name = pingduan.name,
        prompt = "#pingduan-prey::"..target.id,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, pingduan.name, nil, true, player)
      if not target.dead then
        target:drawCards(1, pingduan.name)
      end
    end
  end,
})

return pingduan
