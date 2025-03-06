local weimian = fk.CreateSkill{
  name = "weimian",
}

Fk:loadTranslationTable{
  ["weimian"] = "慰勉",
  [":weimian"] = "出牌阶段限一次，你可以废除至多三个装备栏，然后令一名角色选择等量项：1.恢复一个被废除的装备栏；2.回复1点体力；"..
  "3.弃置所有手牌，摸四张牌。",

  ["#weimian"] = "慰勉：废除至多三个装备栏，令一名角色执行等量效果",
  ["#weimian-abort"] = "慰勉：请选择要废除的至多三个装备栏",
  ["#weimian-choose"] = "慰勉：选择一名角色执行%arg项效果",
  ["weimian1"] = "恢复一个装备栏",
  ["weimian3"] = "弃置所有手牌，摸四张牌",
  ["#weimian-resume"] = "慰勉：选择要恢复的装备栏",

  ["$weimian1"] = "不过二三小事，夫君何须烦恼。",
  ["$weimian2"] = "宦海疾风大浪，家为避风之塘。",
}

weimian:addEffect("active", {
  anim_type = "support",
  prompt = "#weimian",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(weimian.name, Player.HistoryPhase) == 0 and
      #player:getAvailableEquipSlots() > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local choice = room:askToChoices(player, {
      choices = player:getAvailableEquipSlots(),
      min_num = 1,
      max_num = 3,
      skill_name = weimian.name,
      prompt = "#weimian-abort",
      cancelable = false,
    })
    room:abortPlayerArea(player, choice)
    if player.dead then return end
    local n = #choice
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = weimian.name,
      prompt = "#weimian-choose:::"..n,
      cancelable = false,
    })[1]
    local selected = {}
    for i = 1, n, 1 do
      if to.dead then return end
      local choices = {}
      if #to.sealedSlots > 0 and table.find(to.sealedSlots, function (slot)
        return slot ~= Player.JudgeSlot
      end) and not table.contains(selected, "weimian1") then
        table.insert(choices, "weimian1")
      end
      if to:isWounded() and not table.contains(selected, "recover") then
        table.insert(choices, "recover")
      end
      if not table.contains(selected, "weimian3") then
        --假设可以不弃手牌
        table.insert(choices, "weimian3")
      end
      table.insert(choices, "Cancel")
      if #choices == 0 then return end
      choice = room:askToChoice(to, {
        choices = choices,
        skill_name = weimian.name,
        all_choices = {"weimian1", "recover", "weimian3", "Cancel"},
      })
      if choice == "Cancel" then return end
      table.insert(selected, choice)
      if choice == "weimian1" then
        local slots = table.simpleClone(to.sealedSlots)
        table.removeOne(slots, Player.JudgeSlot)
        local weimian_resume = room:askToChoice(to, {
          choices = slots,
          skill_name = weimian.name,
          prompt = "#weimian-resume",
        })
        room:resumePlayerArea(to, {weimian_resume})
      elseif choice == "recover" then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = weimian.name,
        }
      elseif choice == "weimian3" then
        to:throwAllCards("h", weimian.name)
        if not to.dead then
          to:drawCards(4, weimian.name)
        end
      end
    end
  end,
})

return weimian
