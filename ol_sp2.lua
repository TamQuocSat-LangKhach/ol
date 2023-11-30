local extension = Package("ol_sp2")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_sp2"] = "OL专属2",
  ["jin"] = "晋",
}

local caoshuang = General(extension, "caoshuang", "wei", 4)
local tuogu = fk.CreateTriggerSkill{
  name = "tuogu",
  anim_type = "special",
  events ={fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = {}
    local skills = table.map(Fk.generals[target.general].skills, function(s) return s.name end)
    for _, skill in ipairs(skills) do
      if target:hasSkill(skill, true, true) and Fk.skills[skill].frequency ~= Skill.Limited and Fk.skills[skill].frequency ~= Skill.Wake and
        string.sub(skill, #skill, #skill) ~= "$" and not player:hasSkill(skill, true) then  --TODO: 隐匿技
        table.insertIfNeed(self.cost_data, skill)
      end
    end
    return #self.cost_data > 0 and player.room:askForSkillInvoke(player, self.name, nil, "#tuogu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local choice = room:askForChoice(target, self.cost_data, self.name, "#tuogu-choice:"..player.id)
    local mark = player:getMark(self.name)
    if mark ~= 0 then
      room:handleAddLoseSkills(player, choice.."|-"..mark, nil, true, true)
    else
      room:handleAddLoseSkills(player, choice, nil, true, true)
    end
    room:setPlayerMark(player, self.name, choice)
  end,
}
local shanzhuan = fk.CreateTriggerSkill{
  name = "shanzhuan",
  anim_type = "control",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.Damage then
        return data.to ~= player and not data.to.dead and not data.to:isNude() and #data.to.player_cards[Player.Judge] == 0
      else
        return player.phase == Player.Finish and player:getMark("shanzhuan-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if event == fk.Damage then
      prompt = "#shanzhuan-invoke::"..data.to.id
    else
      prompt = "#shanzhuan-draw"
    end
    return player.room:askForSkillInvoke(player, self.name, data, prompt)
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.Damage then
      local room = player.room
      local id = room:askForCardChosen(player, data.to, "he", self.name)
      if Fk:getCardById(id, true).sub_type == Card.SubtypeDelayedTrick then
        room:moveCardTo(Fk:getCardById(id, true), Player.Judge, data.to, fk.ReasonJustMove, self.name)
      else
        local card = Fk:cloneCard("indulgence")
        if Fk:getCardById(id, true).color == Card.Black then
          card = Fk:cloneCard("supply_shortage")
        end
        card:addSubcard(id)
        data.to:addVirtualEquip(card)
        room:moveCardTo(card, Player.Judge, data.to, fk.ReasonJustMove, self.name)  --无视合法性检测
      end
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "shanzhuan-turn", 1)
  end,
}
caoshuang:addSkill(tuogu)
caoshuang:addSkill(shanzhuan)
Fk:loadTranslationTable{
  ["caoshuang"] = "曹爽",
  ["tuogu"] = "托孤",
  [":tuogu"] = "当一名角色死亡时，你可以令其选择其武将牌上的一个技能（限定技、觉醒技、主公技、隐匿技除外），你失去上次以此法获得的技能，然后获得此技能。",
  ["shanzhuan"] = "擅专",
  [":shanzhuan"] = "当你对一名其他角色造成伤害后，若其判定区没有牌，你可以将其一张牌置于其判定区，若此牌不是延时锦囊牌，则红色牌视为【乐不思蜀】，"..
  "黑色牌视为【兵粮寸断】。结束阶段，若你本回合未造成伤害，你可以摸一张牌。",
  ["#tuogu-invoke"] = "托孤：你可以令 %dest 选择其一个技能令你获得",
  ["#tuogu-choice"] = "托孤：选择令 %src 获得的一个技能",
  ["#shanzhuan-invoke"] = "擅专：你可以将 %dest 一张牌置于其判定区，红色视为【乐不思蜀】，黑色视为【兵粮寸断】",
  ["#shanzhuan-draw"] = "擅专：你可以摸一张牌",

  ["$tuogu1"] = "君托以六尺之孤，爽，当寄百里之命。",
  ["$tuogu2"] = "先帝以大事托我，任重而道远。	",
  ["$shanzhuan1"] = "打入冷宫，禁足绝食。",
  ["$shanzhuan2"] = "我言既出，谁敢不从？",
  ["~caoshuang"] = "悔不该降了司马懿。",
}

local zhangliao = General(extension, "sp__zhangliao", "qun", 4)
local mubing = fk.CreateTriggerSkill{
  name = "mubing",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = room:getNCards(player:usedSkillTimes("diaoling", Player.HistoryGame) > 0 and 4 or 3)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
    })
    if player.dead or player:isKongcheng() then
      room:moveCards({
        ids = card_ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
      return
    end
    local cards = room:askForDiscard(player, 1, 999, false, self.name, true, ".", "#mubing-discard")
    if player.dead or #cards == 0 then
      room:moveCards({
        ids = card_ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
      return
    end
    for _, p in ipairs(room.players) do
      room:fillAG(p, card_ids)
    end
    local n = 0
    for _, id in ipairs(cards) do
      n = n + Fk:getCardById(id).number
    end
    while true do
      local sum = 0
      table.forEach(get, function(id)
        sum = sum + Fk:getCardById(id).number
      end)
      for i = #card_ids, 1, -1 do
        local id = card_ids[i]
        if sum + Fk:getCardById(id).number > n then
          room:takeAG(player, id, room.players)
          table.insert(throw, id)
          table.removeOne(card_ids, id)
        end
      end
      if #card_ids == 0 then break end
      local card_id = room:askForAG(player, card_ids, false, self.name)
      --if card_id == nil then break end
      room:takeAG(player, card_id, room.players)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
      if #card_ids == 0 then break end
    end
    table.forEach(room.players, function(p)
      room:closeAG(p)
    end)
    if #get > 0 then
      if player:usedSkillTimes("diaoling", Player.HistoryGame) == 0 and player:hasSkill("diaoling", true) then
        for _, id in ipairs(get) do
          local card = Fk:getCardById(id)
          if card.is_damage_card or card.sub_type == Card.SubtypeWeapon then
            room:addPlayerMark(player, "@mubing", 1)
          end
        end
      end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonPrey)
      if player:usedSkillTimes("diaoling", Player.HistoryGame) > 0 then
        for _, id in ipairs(get) do
          if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
            room:setCardMark(Fk:getCardById(id), "mubing", 1)
          end
        end
        while table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("mubing") > 0 end) do
          if not room:askForUseActiveSkill(player, "mubing_active", "#mubing-give", true) then
            for _, id in ipairs(player:getCardIds("h")) do
              room:setCardMark(Fk:getCardById(id), "mubing", 0)
            end
          end
        end
      end
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
  end,
}
local mubing_active = fk.CreateActiveSkill{
  name = "mubing_active",
  mute = true,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Fk:getCardById(to_select):getMark("mubing") > 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    for _, id in ipairs(effect.cards) do
      room:setCardMark(Fk:getCardById(id), "mubing", 0)
    end
    if effect.tos[1] ~= effect.from then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(effect.cards)
      room:obtainCard(target, dummy, false, fk.ReasonGive)
    end
  end,
}
local ziqu = fk.CreateTriggerSkill{
  name = "ziqu",
  anim_type = "control",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return player:getMark(self.name) == 0 or not table.contains(player:getMark(self.name), data.to.id)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ziqu-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insert(mark, data.to.id)
    room:setPlayerMark(player, self.name, mark)
    room:doIndicate(player.id, {data.to.id})
    if not data.to:isNude() then
      local ids = table.filter(data.to:getCardIds("he"), function(id)
        return table.every(data.to:getCardIds("he"), function(id2)
          return Fk:getCardById(id).number >= Fk:getCardById(id2).number end) end)
      local card = room:askForCard(data.to, 1, 1, true, self.name, false, ".|.|.|.|.|.|"..table.concat(ids, ","), "#ziqu-give:"..player.id)
      if #card > 0 then
        card = card[1]
      else
        card = table.random(ids)
      end
      room:obtainCard(player.id, card, true, fk.ReasonGive)
    end
    return true
  end
}
local diaoling = fk.CreateTriggerSkill{
  name = "diaoling",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mubing") > 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@mubing", 0)
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "draw2" then
      player:drawCards(2, self.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
  end,
}
Fk:addSkill(mubing_active)
zhangliao:addSkill(mubing)
zhangliao:addSkill(ziqu)
zhangliao:addSkill(diaoling)
Fk:loadTranslationTable{
  ["sp__zhangliao"] = "张辽",
  ["mubing"] = "募兵",
  [":mubing"] = "出牌阶段开始时，你可以亮出牌堆顶三张牌，然后你可以弃置任意张手牌，获得任意张亮出的牌，你弃置牌点数之和不能小于获得牌点数之和。",
  ["ziqu"] = "资取",
  [":ziqu"] = "每名角色限一次，当你对其他角色造成伤害时，你可以防止此伤害，令其交给你一张点数最大的牌。",
  ["diaoling"] = "调令",
  [":diaoling"] = "觉醒技，准备阶段，若你发动〖募兵〗累计获得了至少六张【杀】、伤害锦囊牌和武器牌，你回复1点体力或摸两张牌，并修改〖募兵〗："..
  "多亮出一张牌，且获得的牌可以任意交给其他角色。",
  ["#mubing-discard"] = "募兵：你可以弃置任意张手牌，获得点数之和不大于你弃牌点数之和的牌",
  ["@mubing"] = "募兵",
  ["#mubing-give"] = "募兵：将这些牌分配给任意角色，点“取消”自己保留",
  ["mubing_active"] = "募兵",
  ["#ziqu-invoke"] = "资取：是否防止对 %dest 造成的伤害，改为令其交给你一张点数最大的牌？",
  ["#ziqu-give"] = "资取：你需要交给 %src 一张点数最大的牌",

  ["$mubing1"] = "兵者，不唯在精，亦在广。",
	["$mubing2"] = "男儿当从军，功名马上取。",
  ["$ziqu1"] = "留财不留命，留命不留财。",
  ["$ziqu2"] = "兵马已动，尔等速将粮草缴来。",
  ["$diaoling1"] = "邻军告急，当遣将急援。",
  ["$diaoling2"] = "兵甲已足，当汇集三军。",
  ["~sp__zhangliao"] = "孤军难鸣，进退维谷。",
}

local zhangling = General(extension, "zhangling", "qun", 3)
local huqi = fk.CreateTriggerSkill{
  name = "huqi",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.NotActive and data.from and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:useVirtualCard("slash", nil, player, data.from, self.name, false)
    end
  end,
}
local huqi_distance = fk.CreateDistanceSkill{
  name = "#huqi_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      return -1
    end
  end,
}
local shoufu = fk.CreateActiveSkill{
  name = "shoufu",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:drawCards(1)
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p:getPile("zhangling_lu") == 0 then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|hand|.|.", "#shoufu-cost", self.name, false)
    room:getPlayerById(to[1]):addToPile("zhangling_lu", id, true, self.name)
  end,
}
local shoufu_prohibit = fk.CreateProhibitSkill{
  name = "#shoufu_prohibit",
  prohibit_use = function(self, player, card)
    if #player:getPile("zhangling_lu") > 0 then
      return card.type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type
    end
  end,
  prohibit_response = function(self, player, card)
    if #player:getPile("zhangling_lu") > 0 then
      return card.type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type
    end
  end,
}
local shoufu_record = fk.CreateTriggerSkill{
  name = "#shoufu_record",

  refresh_events = {fk.Damaged, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if #player:getPile("zhangling_lu") > 0 then
      if event == fk.Damaged then
        return target == player
      else
        if player.phase == Player.Discard then
          local n = 0
          for _, move in ipairs(data) do
            if move.from == player.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if Fk:getCardById(info.cardId).type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type then
                  n = n + 1
                end
              end
            end
          end
          if n > 0 then
            player.room:addPlayerMark(player, "shoufu", n)
          end
          if player:getMark("shoufu") > 1 then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "shoufu", 0)
    room:moveCards({
      from = player.id,
      ids = player:getPile("zhangling_lu"),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "shoufu",
      specialName = "zhangling_lu",
    })
  end,
}
huqi:addRelatedSkill(huqi_distance)
shoufu:addRelatedSkill(shoufu_prohibit)
shoufu:addRelatedSkill(shoufu_record)
zhangling:addSkill(huqi)
zhangling:addSkill(shoufu)
Fk:loadTranslationTable{
  ["zhangling"] = "张陵",
  ["huqi"] = "虎骑",
  [":huqi"] = "锁定技，你计算与其他角色的距离-1；当你于回合外受到伤害后，你进行判定，若结果为红色，视为你对伤害来源使用一张【杀】（无距离限制）。",
  ["shoufu"] = "授符",
  [":shoufu"] = "出牌阶段限一次，你可摸一张牌，然后将一张手牌置于一名没有“箓”的角色的武将牌上，称为“箓”；其不能使用和打出与“箓”同类型的牌。"..
  "该角色受到伤害后，或于弃牌阶段弃置至少两张与“箓”同类型的牌后，将“箓”置入弃牌堆。",
  ["zhangling_lu"] = "箓",
  ["#shoufu-cost"] = "授符：选择角色并将一张手牌置为其“箓”，其不能使用打出“箓”同类型的牌",

  ["$huqi1"] = "骑虎云游，探求道法。",
  ["$huqi2"] = "求仙长生，感悟万象。",
  ["$shoufu1"] = "得授符法，驱鬼灭害。",
  ["$shoufu2"] = "吾得法器，必斩万恶！",
  ["~zhangling"] = "羽化登仙，遗世独立……",
}

local longfeng = General(extension, "wolongfengchu", "shu", 4)
local youlong = fk.CreateViewAsSkill{
  name = "youlong",
  switch_skill_name = "youlong",
  anim_type = "switch",
  pattern = ".",
  interaction = function()
    local names = {}
    local mark = Self:getMark("@$youlong")
    local isYang = Self:getSwitchSkillState("youlong") == fk.SwitchYang
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if ((card.type == Card.TypeBasic and not isYang) or
        (card:isCommonTrick() and isYang)) and
        not card.is_derived and
        ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local mark = player:getMark("@$youlong")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    room:setPlayerMark(player, "@$youlong", mark)
    local state = player:getSwitchSkillState(self.name, false, true)
    room:setPlayerMark(player, "youlong_" .. state .. "-round", 1)

    -- FIXME: 傻逼神典韦
    local all_choices = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
    local subtypes = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#youlong-choice", false, all_choices)
    room:abortPlayerArea(player, {choice})
  end,
  enabled_at_play = function(self, player)
    local state = player:getSwitchSkillState(self.name, false, true)
    return player:getMark("youlong_" .. state .. "-round") == 0 and #player:getAvailableEquipSlots() > 0
  end,
  enabled_at_response = function(self, player, response)
    local state = player:getSwitchSkillState(self.name, false, true)
    return (not response) and player:getMark("youlong_" .. state .. "-round") == 0 and #player:getAvailableEquipSlots() > 0
  end,
}
local luanfeng = fk.CreateTriggerSkill{
  name = "luanfeng",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.maxHp >= player.maxHp and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover {
      who = target,
      num = 3 - target.hp,
      recoverBy = player,
      skillName = self.name,
    }

    local slots = table.simpleClone(target.sealedSlots)
    table.removeOne(slots, Player.JudgeSlot)
    local x = #slots
    if x > 0 then
      room:resumePlayerArea(target, slots)
    end
    local n = target:getHandcardNum()
    if n < 6 - x then
      target:drawCards(6 - x - n, self.name)
    end

    if target == player then
      room:setPlayerMark(player, "@$youlong", 0)
    end
  end,
}
longfeng:addSkill(youlong)
longfeng:addSkill(luanfeng)
Fk:loadTranslationTable{
  ['wolongfengchu'] = '卧龙凤雏',
  ['youlong'] = '游龙',
  [':youlong'] = '转换技，每轮各限一次，你可以废除一个装备栏并视为使用一张未以此法使用过的' ..
    '{阳：普通锦囊牌；阴：基本牌。}',
  ['luanfeng' ] = '鸾凤',
  [':luanfeng'] = '限定技，当一名角色处于濒死状态时，若其体力上限不小于你，' ..
    '你可令其将体力回复至3点，恢复其被废除的装备栏，令其手牌补至6-X张' ..
    '（X为以此法恢复的装备栏数量）。若该角色为你，重置你“游龙”使用过的牌名。',

  ['@$youlong'] = '游龙',
  ['#youlong-choice'] = '游龙: 请选择废除一个装备栏',
  ['$youlong1'] = '赤壁献策，再谱春秋！',
  ['$youlong2'] = '卧龙出山，谋定万古！',
  ['$luanfeng1'] = '凤栖枯木，浴火涅槃！',
  ['$luanfeng2'] = '青鸾归宇，雏凤还巢！',
  ['~wolongfengchu'] = '铁链，东风，也难困这魏军……',
}

local panshu = General(extension, "ol__panshu", "wu", 3, 3, General.Female)
local weiyi = fk.CreateTriggerSkill{
  name = "weiyi",
  anim_type = "control",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and target:getMark(self.name) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if target.hp == player.hp and target:isWounded() then
      prompt = "#weiyi1-invoke::"
    elseif target.hp >= player.hp then
      prompt = "#weiyi2-invoke::"
    elseif target.hp <= player.hp and target:isWounded() then
      prompt = "#weiyi3-invoke::"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(target, self.name, 1)
    local choices = {}
    if target.hp >= player.hp then
      table.insert(choices, "loseHp")
    end
    if target.hp <= player.hp and target:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name, "#weiyi-choice::"..target.id)
    if choice == "loseHp" then
      room:loseHp(target, 1, self.name)
    else
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local jinzhi_active = fk.CreateActiveSkill{
  name = "jinzhi_active",
  card_num = function()
    return Self:usedSkillTimes("jinzhi", Player.HistoryRound) + 1
  end,
  target_num = 0,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      return true
    else
      return #selected <= Self:usedSkillTimes("jinzhi", Player.HistoryRound) + 1 and
        Fk:getCardById(to_select).color == Fk:getCardById(selected[1]).color
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, "jinzhi", player, player)
  end,
}
local jinzhi = fk.CreateViewAsSkill{
  name = "jinzhi",
  anim_type = "special",
  pattern = "^nullification|.|.|.|.|basic",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    player.room:askForUseActiveSkill(player, "jinzhi_active", "#jinzhi-discard:::"..player:usedSkillTimes(self.name, Player.HistoryRound), false)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    local black = #table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id).color == Card.Black end)
    local red = #table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id).color == Card.Red end)
    return math.max(black, red) > player:usedSkillTimes(self.name, Player.HistoryRound)
  end,
  enabled_at_response = function(self, player, response)
    local black = #table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id).color == Card.Black end)
    local red = #table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id).color == Card.Red end)
    return math.max(black, red) > player:usedSkillTimes(self.name, Player.HistoryRound)
  end,
}
Fk:addSkill(jinzhi_active)
panshu:addSkill(weiyi)
panshu:addSkill(jinzhi)
Fk:loadTranslationTable{
  ["ol__panshu"] = "潘淑",
  ["weiyi"] = "威仪",
  [":weiyi"] = "每名角色限一次，当一名角色受到伤害后，若其体力值：1.不小于你，你可以令其失去1点体力；2.不大于你，你可以令其回复1点体力。",
  ["jinzhi"] = "锦织",
  [":jinzhi"] = "当你需要使用或打出基本牌时，你可以：弃置X张颜色相同的牌（为你本轮发动本技能的次数），然后摸一张牌，视为你使用或打出此基本牌。",
  ["#weiyi1-invoke"] = "威仪：你可以令 %dest 失去1点体力或回复1点体力",
  ["#weiyi2-invoke"] = "威仪：你可以令 %dest 失去1点体力",
  ["#weiyi3-invoke"] = "威仪：你可以令 %dest 回复1点体力",
  ["#weiyi-choice"] = "威仪：选择令 %dest 执行的一项",
  ["#jinzhi-discard"] = "锦织：弃置%arg张颜色相同的牌，摸一张牌，视为使用此基本牌",
  ["jinzhi_active"] = "锦织",

  ["$weiyi1"] = "无威仪者，不可奉社稷。",
  ["$weiyi2"] = "有威仪者，进止雍容。",
  ["$jinzhi1"] = "织锦为旗，以扬威仪。",
  ["$jinzhi2"] = "坐而织锦，立则为仪。",
  ["~ol__panshu"] = "本为织女，幸蒙帝垂怜……",
}

local huangzu = General(extension, "ol__huangzu", "qun", 4)
local wangong = fk.CreateTriggerSkill{
  name = "wangong",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@@wangong") > 0 and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeBasic then
      room:setPlayerMark(player, "@@wangong", 1)
    else
      room:setPlayerMark(player, "@@wangong", 0)
    end
  end,
}
local wangong_targetmod = fk.CreateTargetModSkill{
  name = "#wangong_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@wangong") > 0 and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@@wangong") > 0 then
      return 999
    end
  end,
}
wangong:addRelatedSkill(wangong_targetmod)
huangzu:addSkill(wangong)
Fk:loadTranslationTable{
  ["ol__huangzu"] = "黄祖",
  ["wangong"] = "挽弓",
  [":wangong"] = "锁定技，若你使用的上一张牌是基本牌，你使用【杀】无距离和次数限制且造成的伤害+1。",
  ["@@wangong"] = "挽弓",

  ["$wangong1"] = "强弓挽之，以射长箭！",
  ["$wangong2"] = "挽弓如月，克定江夏！",
  ["~ol__huangzu"] = "命也……势也……",
}
-- 黄承彦 2021.7.15

local huangchengyan = General(extension, "ol__huangchengyan", "qun", 3)
local function doGuanxu(player, target, skill_name)
  local room = player.room
  local cids = target:getCardIds(Player.Hand)
  local cards = room:getNCards(5)
  local to_ex = U.askForExchange(player, "Top", "$Hand", cards, cids, "#guanxu-exchange", 1)
  if #to_ex == 0 then return end
  local index = 0
  local cardA = table.find(cards, function (id)
    index = index + 1
    return table.contains(to_ex, id)
  end)
  local cardB = table.find(to_ex, function (id)
    return id ~= cardA
  end)
  room:moveCards({
    ids = cards,
    toArea = Card.Processing,
    skillName = skill_name,
    moveReason = fk.ReasonExchange,
    proposer = player.id,
    moveVisible = false
  }, {
    ids = {cardB},
    from = target.id,
    toArea = Card.Processing,
    skillName = skill_name,
    moveReason = fk.ReasonExchange,
    proposer = player.id,
    moveVisible = false
  })
  local moveInfos = {}
  if room:getCardArea(cardA) == Card.Processing then
    if target.dead then
      table.insert(moveInfos, {
        ids = {cardA},
        fromArea = Card.Processing,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = skill_name
      })
    else
      table.insert(moveInfos, {
        ids = {cardA},
        fromArea = Card.Processing,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = skill_name,
        moveVisible = false
      })
    end
  end
  table.remove(cards, index)
  table.insert(cards, index, cardB)
  cards = table.reverse(cards)
  cards = table.filter(cards, function (id)
    return room:getCardArea(id) == Card.Processing
  end)
  if #cards > 0 then
    table.insert(moveInfos, {
      ids = cards,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = skill_name,
      moveVisible = false
    })
  end
  if #moveInfos > 0 then
    room:moveCards(table.unpack(moveInfos))
  end
  if player.dead or target.dead then return end
  cids = target:getCardIds(Player.Hand)
  local check = {{}, {}, {}, {}}
  for _, id in ipairs(cids) do
    local suit = Fk:getCardById(id).suit
    if suit < 5 then
      table.insert(check[suit], id)
    end
  end
  local ids = table.find(check, function (cids)
    return #cids > 2
  end)
  if ids == nil then return false end
  cids = room:askForPoxi(player, "guanxu_discard", {
    { "$Hand", cids }
  }, nil, false)
  if #cids ~= 3 then
    cids = table.slice(ids, 1, 4)
  end
  room:throwCard(cids, skill_name, target, player)
end
Fk:addPoxiMethod{
  name = "guanxu_discard",
  card_filter = function(to_select, selected, data)
    if #selected > 2 then return false end
    local suit = Fk:getCardById(to_select).suit
    if suit == Card.NoSuit then return false end
    return #selected == 0 or suit == Fk:getCardById(selected[1]).suit
  end,
  feasible = function(selected)
    return #selected == 3
  end,
  prompt = function ()
    return "观虚：选择三张花色相同的卡牌弃置"
  end
}
local guanxu = fk.CreateActiveSkill{
  name = "guanxu",
  anim_type = "control",
  prompt = "#guanxu-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    doGuanxu(room:getPlayerById(effect.from), room:getPlayerById(effect.tos[1]), self.name)
  end,
}
local yashi = fk.CreateTriggerSkill{
  name = "yashi",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_cost = function(self, event, target, player, data)
    local choices = {"yashi_guanxu", "Cancel"}
    if data.from and not data.from.dead then
      table.insert(choices, 1, "yashi_invalidity::" .. data.from.id)
    end
    local room = player.room
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "yashi_guanxu" then
      local targets = table.map(table.filter(room.alive_players, function (p)
        return p ~= player and not p:isKongcheng()
      end), Util.IdMapper)
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#guanxu-active", self.name, true)
      if #targets > 0 then
        self.cost_data = {choice, targets[1]}
        return true
      end
    elseif choice ~= "Cancel" then
      room:doIndicate(player.id, {data.from.id})
      self.cost_data = {choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] == "yashi_guanxu" then
      doGuanxu(player, room:getPlayerById(self.cost_data[2]), self.name)
    else
      room:setPlayerMark(data.from, "@@yashi", 1)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yashi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yashi", 0)
  end,
}
local yashi_invalidity = fk.CreateInvaliditySkill {
  name = "#yashi_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@yashi") > 0 and
      (skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Wake) and
      not (skill:isEquipmentSkill() or skill.name:endsWith("&"))
  end
}
yashi:addRelatedSkill(yashi_invalidity)
huangchengyan:addSkill(guanxu)
huangchengyan:addSkill(yashi)

Fk:loadTranslationTable{
  ["ol__huangchengyan"] = "黄承彦",
  ["guanxu"] = "观虚",
  [":guanxu"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以用其中一张牌交换牌堆顶的五张牌中的一张。"..
  "若如此做，你弃置其手牌中三张相同花色的牌。",
  ["yashi"] = "雅士",
  [":yashi"] = "当你受到伤害后，你可以选择一项：1.令伤害来源的非锁定技无效直到其下个回合开始；2.对一名其他角色发动一次〖观虚〗。",

  ["#guanxu-active"] = "发动 观虚，观看一名其他角色的手牌",
  ["#guanxu-exchange"] = "观虚：选择要交换的至多1张卡牌",
  ["guanxu_discard"] = "观虚",

  ["yashi_guanxu"] = "对一名其他角色发动一次〖观虚〗",
  ["yashi_invalidity"] = "令%dest的非锁定技失效直到其下个回合开始",

  ["@@yashi"] = "雅士",

  ["$guanxu1"] = "不识此阵者，必为所迷。",
  ["$guanxu2"] = "虚实相生，变化无穷。",
  ["$yashi1"] = "德行贞绝者，谓其雅士。",
  ["$yashi2"] = "鸿儒雅士，闻见多矣。",
  ["~ol__huangchengyan"] = "皆为虚妄……",
}

local gaogan = General(extension, "gaogan", "qun", 4)
local juguan = fk.CreateViewAsSkill{
  name = "juguan",
  anim_type = "offensive",
  pattern = "slash,duel",
  interaction = UI.ComboBox {choices = {"slash", "duel"}},
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
}
local juguan_record = fk.CreateTriggerSkill{
  name = "#juguan_record",

  refresh_events = {fk.Damage, fk.Damaged, fk.EventPhaseChanging, fk.DrawNCards},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, true) then
      if event == fk.Damage then
        return data.card and table.contains(data.card.skillNames, "juguan")
      elseif event == fk.Damaged then
        return data.from and player:getMark("@@juguan") ~= 0 and table.contains(player:getMark("@@juguan"), data.from.id)
      elseif event == fk.EventPhaseChanging then
        return data.from == Player.RoundStart and player:getMark("@@juguan") ~= 0
      else
        return player:getMark("juguan") > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      local mark = player:getMark("@@juguan")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.to.id)  --记录多次叠加，虽然没想到怎样才会叠加
      room:setPlayerMark(player, "@@juguan", mark)
    elseif event == fk.Damaged then
      local mark = player:getMark("@@juguan")
      table.removeOne(mark, data.from.id)
      if #mark == 0 then
        room:setPlayerMark(player, "@@juguan", 0)
      else
        room:setPlayerMark(player, "@@juguan", mark)
      end
    elseif event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "@@juguan", 0)
      room:addPlayerMark(player, "juguan", 1)
    else
      data.n = data.n + 2 * player:getMark("juguan")
      room:setPlayerMark(player, "juguan", 0)
    end
  end,
}
juguan:addRelatedSkill(juguan_record)
gaogan:addSkill(juguan)
Fk:loadTranslationTable{
  ["gaogan"] = "高干",
  ["juguan"] = "拒关",
  [":juguan"] = "出牌阶段限一次，你可将一张手牌当【杀】或【决斗】使用。若受到此牌伤害的角色未在你的下回合开始前对你造成过伤害，你的下个摸牌阶段摸牌数+2。",
  ["@@juguan"] = "拒关",

  ["$juguan1"] = "吾欲自立，举兵拒关。",
  ["$juguan2"] = "自立门户，拒关不开。",
  ["~gaogan"] = "天不助我！",
}

local duxi = General(extension, "duxi", "wei", 3)
local quxi_active = fk.CreateActiveSkill{
  name = "#quxi_active",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      return #target1.player_cards[Player.Hand] ~= #target2.player_cards[Player.Hand]
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    local from, to
    if #target1.player_cards[Player.Hand] < #target2.player_cards[Player.Hand] then
      from = target1
      to = target2
    else
      from = target2
      to = target1
    end
    local card = room:askForCardChosen(from, to, "he", "quxi")
    room:obtainCard(from.id, card, true, fk.ReasonPrey)
    room:addPlayerMark(from, "@@duxi_feng", 1)
    room:addPlayerMark(to, "@@duxi_qian", 1)
  end,
}
local quxi = fk.CreateTriggerSkill{
  name = "quxi",
  anim_type = "control",
  frequency = Skill.Limited,
  events = {fk.EventPhaseEnd, fk.RoundStart, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return target == player and player:hasSkill(self) and player.phase == Player.Play and
        not table.every(player.room:getOtherPlayers(player), function(p)
          return #p.player_cards[Player.Hand] == #player.room:getOtherPlayers(player)[1].player_cards[Player.Hand]
        end) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
    else
      return not player.dead and player:usedSkillTimes(self.name, Player.HistoryGame) > 0 and
        (event == fk.RoundStart or (event == fk.Death and (target:getMark("@@duxi_feng") > 0 or target:getMark("@@duxi_qian") > 0)))
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      return room:askForUseActiveSkill(player, "#quxi_active", "#quxi-invoke", true)
    elseif event == fk.RoundStart then
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("@@duxi_feng") > 0 or p:getMark("@@duxi_qian") > 0 then
          table.insert(targets, p.id)
        end
      end
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#quxi1-choose", self.name, true)
        if #to > 0 then
          self.cost_data = to[1]
          return true
        end
      end
    elseif event == fk.Death then
      if room:askForSkillInvoke(player, self.name, nil, "#quxi2-choose::"..target.id) then
        self.cost_data = target.id
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      player:skip(Player.Discard)
      if player.faceup then
        player:turnOver()
      end
      return
    end
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"Cancel"}
    for _, mark in ipairs({"@@duxi_feng", "@@duxi_qian"}) do
      if to:getMark(mark) > 0 then
        table.insert(choices, mark)
      end
    end
    while true do
      local choice = room:askForChoice(player, choices, self.name, "#quxi-choice")
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      local targets = table.map(room:getOtherPlayers(to), Util.IdMapper)
      local dest
      if #targets > 1 then
        dest = room:askForChoosePlayers(player, targets, 1, 1, "#quxi-move:::"..choice, self.name, false)
        if #dest > 0 then
          dest = dest[1]
        else
          dest = table.random(targets)
        end
      else
        dest = targets[1]
      end
      dest = room:getPlayerById(dest)
      room:setPlayerMark(to, choice, 0)
      room:setPlayerMark(dest, choice, 1)
    end
  end,

  refresh_events = {fk.DrawNCards},
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@@duxi_feng") > 0 or player:getMark("@@duxi_qian") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    if player:getMark("@@duxi_feng") > 0 then
      data.n = data.n + 1
    else
      data.n = data.n - 1
    end
  end,
}
local bixiong = fk.CreateTriggerSkill{
  name = "bixiong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) == 0 then
      room:setPlayerMark(player, "@bixiong", 0)
    else
      local mark = {}
      local suits = {"spade", "heart", "club", "diamond"}
      local icons = {"♠", "♥", "♣", "♦"}
      for i = 1, 4, 1 do
        if table.contains(player:getMark(self.name), suits[i]) then
          table.insert(mark, icons[i])
        end
      end
      room:setPlayerMark(player, "@bixiong", table.concat(mark))
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return player:hasSkill(self) and player.phase == Player.Discard
    else
      return target == player and player:getMark("@bixiong") ~= 0 and data.from == Player.RoundStart
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          local mark = {}
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insertIfNeed(mark, Fk:getCardById(info.cardId):getSuitString())
            end
          end
          if #mark == 0 then mark = 0 end
          player.room:setPlayerMark(player, self.name, mark)
        end
      end
    else
      player.room:setPlayerMark(player, "@bixiong", 0)
      player.room:setPlayerMark(player, "bixiong", 0)
    end
  end,
}
local bixiong_prohibit = fk.CreateProhibitSkill{
  name = "#bixiong_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("bixiong") ~= 0 and from ~= to and table.contains(to:getMark("bixiong"), card:getSuitString())
  end,
}
Fk:addSkill(quxi_active)
bixiong:addRelatedSkill(bixiong_prohibit)
duxi:addSkill(quxi)
duxi:addSkill(bixiong)
Fk:loadTranslationTable{
  ["duxi"] = "杜袭",
  ["quxi"] = "驱徙",
  [":quxi"] = "限定技，出牌阶段结束时，你可以跳过弃牌阶段并翻至背面，选择两名手牌数不同的其他角色，其中手牌少的角色获得另一名角色一张牌并获得「丰」，"..
  "另一名角色获得「歉」。<br>有「丰」的角色摸牌阶段摸牌数+1，有「歉」的角色摸牌阶段摸牌数-1。<br>当有「丰」或「歉」的角色死亡时或每轮开始时，"..
  "你可以转移「丰」「歉」。",
  ["bixiong"] = "避凶",
  [":bixiong"] = "锁定技，若你于弃牌阶段弃置了手牌，直到你的下回合开始，其他角色不能使用与这些牌花色相同的牌指定你为目标。",
  ["#quxi-invoke"] = "驱徙：选择两名手牌数不同的其他角色，手牌少的角色获得多的角色一张牌并获得「丰」，手牌多的角色获得「歉」",
  ["#quxi_active"] = "驱徙",
  ["@@duxi_feng"] = "丰",
  ["@@duxi_qian"] = "歉",
  ["#quxi1-choose"] = "驱徙：你可以移动「丰」、「歉」",
  ["#quxi2-choose"] = "驱徙：你可以移动 %dest 的「丰」、「歉」",
  ["#quxi-choice"] = "驱徙：请选择要移动的标记",
  ["#quxi-move"] = "驱徙：请选择获得「%arg」的角色",
  ["@bixiong"] = "避凶",

  ["$quxi1"] = "不自改悔，终须驱徙。",
  ["$quxi2"] = "奈何驱徙，不使存活。",
  ["$bixiong1"] = "避凶而从吉，以趋荆州。",
  ["$bixiong2"] = "逢凶化吉，遇难成祥。",
  ["~duxi"] = "避凶不及，难……也……",
}

local lvkuanglvxiang = General(extension, "ol__lvkuanglvxiang", "qun", 4)
local qigong = fk.CreateTriggerSkill{
  name = "qigong",
  anim_type = "offensive",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and #data.tos == 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(room:getPlayerById(data.to)), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#qigong-invoke::"..data.to, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = room:askForUseCard(room:getPlayerById(self.cost_data), "slash", "slash", "#qigong-use::"..data.to, true,
      {must_targets = {data.to}, bypass_distances = true, bypass_times = true})
    if use then
      use.disresponsiveList = {data.to}
      room:useCard(use)
    end
  end,
}
local liehou = fk.CreateActiveSkill{
  name = "liehou",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and Self:inMyAttackRange(target) and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#liehou-give:"..player.id)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and p ~= target end), Util.IdMapper)
    if #targets == 0 or player:isKongcheng() then return end
    local to, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|hand", "#liehou-choose", self.name, false)
    if #to > 0 then
      room:obtainCard(to[1], id, false, fk.ReasonGive)
    end
  end
}
lvkuanglvxiang:addSkill(qigong)
lvkuanglvxiang:addSkill(liehou)
Fk:loadTranslationTable{
  ["ol__lvkuanglvxiang"] = "吕旷吕翔",
  ["qigong"] = "齐攻",
  [":qigong"] = "当你使用的仅指定单一目标的【杀】被【闪】抵消后，你可以令一名角色对此目标再使用一张无距离限制的【杀】，此【杀】不可被响应。",
  ["liehou"] = "列侯",
  [":liehou"] = "出牌阶段限一次，你可以令你攻击范围内一名有手牌的角色交给你一张手牌，若如此做，你将一张手牌交给你攻击范围内的另一名其他角色。",
  ["#qigong-invoke"] = "齐攻：你可以令一名角色对 %dest 使用【杀】（无距离限制且不可被响应）",
  ["#qigong-use"] = "齐攻：你可以对 %dest 使用一张【杀】（无距离限制且不可被响应）",
  ["#liehou-give"] = "列侯：你需交给 %src 一张手牌",
  ["#liehou-choose"] = "列侯：将一张手牌交给攻击范围内另一名角色",

  ["$qigong1"] = "打虎亲兄弟！",
  ["$qigong2"] = "兄弟齐心，其利断金！",
  ["$liehou1"] = "识时务者为俊杰。",
  ["$liehou2"] = "丞相有令，尔敢不从？",
  ["~ol__lvkuanglvxiang"] = "此处可是新野……",
}

local ol__dengzhi = General(extension, "ol__dengzhi", "shu", 3)
local xiuhao = fk.CreateTriggerSkill{
  name = "xiuhao",
  anim_type = "control",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and player:hasSkill(self) and target and data.to and target ~= data.to and (target == player or data.to == player)
  end,
  on_cost = function (self, event, target, player, data)
    local victim = (target == player) and data.to or player
    local from = (target == player) and player or target
    return player.room:askForSkillInvoke(player, self.name, nil, "#xiuhao-invoke:"..victim.id..":"..from.id)
  end,
  on_use = function(self, event, target, player, data)
    local from = (target == player) and player or target
    from:drawCards(2, self.name)
    return true
  end,
}
ol__dengzhi:addSkill(xiuhao)
local sujian = fk.CreateTriggerSkill{
  name = "sujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.simpleClone(player:getCardIds("h"))
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      local move = e.data[1]
      if move and player.id == move.to and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          table.removeOne(ids, info.cardId)
        end
      end return false
    end, Player.HistoryTurn)
    if #ids > 0 then
      for _, id in ipairs(ids) do room:setCardMark(Fk:getCardById(id), "@@sujian", 1) end
      local choice = room:askForChoice(player, {"sujian_give","sujian_throw"}, self.name)
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#sujian-choose", self.name, false) -- TODO:改为分配
      for _, id in ipairs(ids) do room:setCardMark(Fk:getCardById(id), "@@sujian", 0) end
      local to = room:getPlayerById(tos[1])
      if choice == "sujian_give" then
        local dummy = Fk:cloneCard("slash")
        dummy:addSubcards(ids)
        room:obtainCard(to, dummy, false, fk.ReasonGive)
      else
        room:throwCard(ids, self.name, player, player)
        if not to:isNude() then
          local throw = room:askForCardsChosen(player, to, 0, #ids, "he", self.name)
          if #throw > 0 then
            room:throwCard(throw, self.name, to, player)
          end
        end
      end
    end
    return true
  end,
}
ol__dengzhi:addSkill(sujian)
Fk:loadTranslationTable{
  ["ol__dengzhi"] = "邓芝",
  ["xiuhao"] = "修好",
  [":xiuhao"] = "每名角色的回合限一次，你对其他角色造成伤害，或其他角色对你造成伤害时，你可防止此伤害，令伤害来源摸两张牌。",
  ["#xiuhao-invoke"] = "修好：你可防止 %src 受到的伤害，令 %dest 摸两张牌",
  ["sujian"] = "素俭",
  [":sujian"] = "锁定技，弃牌阶段，你改为：将所有非本回合获得的手牌交给一名其他角色，或弃置非本回合获得的手牌，并弃置一名其他角色至多等量的牌。",
  ["sujian_give"] = "将所有非本回合获得的手牌交给一名其他角色",
  ["sujian_throw"] = "弃置非本回合获得的手牌，并弃置一名其他角色至多等量的牌",
  ["#sujian-choose"] = "素俭：选择一名其他角色",
  ["@@sujian"] = "素俭",

  ["$xiuhao1"] = "吴蜀合同，可御魏敌。",
  ["$xiuhao2"] = "与吴修好，共为唇齿。",
  ["$sujian1"] = "不苟素俭，不置私产。",
  ["$sujian2"] = "高风亮节，摆袖却金。",
  ["~ol__dengzhi"] = "修好未成，蜀汉恐危。",
}

local bianfuren = General(extension, "ol__bianfuren", "wei", 3, 3, General.Female)
local ol__wanwei = fk.CreateTriggerSkill{
  name = "ol__wanwei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local names = {}
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if (move.moveReason == fk.ReasonPrey or move.moveReason == fk.ReasonDiscard) and move.proposer ~= player.id then
            table.insertIfNeed(names, Fk:getCardById(info.cardId).name)
          end
        end
      end
    end
    if #names > 0 then
      self.cost_data = names
      local prompt
      if #names == 1 then
        prompt = "#ol__wanwei1-invoke:::"..names[1]
      else
        prompt = "#ol__wanwei2-invoke"
      end
      return player.room:askForSkillInvoke(player, self.name, nil, prompt)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = self.cost_data
    local card
    if #names == 1 then
      card = room:getCardsFromPileByRule(names[1])
    else
      local choice = room:askForChoice(player, names, self.name, "#ol__wanwei-choice")
      card = room:getCardsFromPileByRule(choice)
    end
    if #card == 0 then
      player:drawCards(1, self.name)
    else
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local ol__yuejian = fk.CreateTriggerSkill{
  name = "ol__yuejian",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and not player:isKongcheng() and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id) and player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ol__yuejian-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.suit == Card.NoSuit then
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    else
      local cards = player.player_cards[Player.Hand]
      player:showCards(cards)
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).suit == data.card.suit then
          return
        end
      end
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
  end,
}
bianfuren:addSkill(ol__wanwei)
bianfuren:addSkill(ol__yuejian)
Fk:loadTranslationTable{
  ["ol__bianfuren"] = "卞夫人",
  ["ol__wanwei"] = "挽危",
  [":ol__wanwei"] = "每回合限一次，当你的牌被其他角色弃置或获得后，你可以从牌堆获得一张同名牌（无同名牌则改为摸一张牌）。",
  ["ol__yuejian"] = "约俭",
  [":ol__yuejian"] = "每回合限两次，当其他角色对你使用的牌结算完毕置入弃牌堆时，你可以展示所有手牌，若花色与此牌均不同，你获得之。",
  ["#ol__wanwei1-invoke"] = "挽危：你可以从牌堆获得一张【%arg】（若没有则摸一张牌）",
  ["#ol__wanwei2-invoke"] = "挽危：你可以从牌堆获得其中一张牌的同名牌（若没有则摸一张牌）",
  ["#ol__wanwei-choice"] = "挽危：选择你要从牌堆获得的牌（若没有则摸一张牌）",
  ["#ol__yuejian-invoke"] = "约俭：你可以展示所有手牌，若花色均与%arg不同，你获得之",

  ["$ol__wanwei1"] = "梁、沛之间，非子廉无有今日。",
  ["$ol__wanwei2"] = "正使祸至，共死何苦！",
  ["$ol__yuejian1"] = "无文绣珠玉，器皆黑漆。",
  ["$ol__yuejian2"] = "性情约俭，不尚华丽。",
  ["~ol__bianfuren"] = "心肝涂地，惊愕断绝……",
}

local zuofen = General(extension, "zuofen", "jin", 3, 3, General.Female)
local zhaosong = fk.CreateTriggerSkill{
  name = "zhaosong",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Draw and not target:isKongcheng() and
      target:getMark("@@zuofen_lei") == 0 and target:getMark("@@zuofen_fu") == 0 and target:getMark("@@zuofen_song") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhaosong-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local ids = room:askForCard(target, 1, 1, false, self.name, false, ".", "#zhaosong-give:"..player.id)
    room:obtainCard(player.id, ids[1], false, fk.ReasonGive)
    local card = Fk:getCardById(ids[1])
    local mark
    if card.type == Card.TypeTrick then
      mark = "@@zuofen_lei"
    elseif card.type == Card.TypeEquip then
      mark = "@@zuofen_fu"
    elseif card.type == Card.TypeBasic then
      mark = "@@zuofen_song"
    end
    room:addPlayerMark(target, mark, 1)
  end,
}
local zhaosong_trigger = fk.CreateTriggerSkill{
  name = "#zhaosong_trigger",
  mute = true,
  events = {fk.EnterDying, fk.EventPhaseStart, fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EnterDying then
        return player:getMark("@@zuofen_lei") > 0
      elseif event == fk.EventPhaseStart then
        return player:getMark("@@zuofen_fu") > 0 and player.phase == Player.Play and
          not table.every(player.room:getAlivePlayers(), function(p) return p:isAllNude() end)
      else
        return player:getMark("@@zuofen_song") > 0 and data.card.trueName == "slash" and #data.targetGroup == 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      return room:askForSkillInvoke(player, self.name, nil, "#zhaosong1-invoke")
    elseif event == fk.EventPhaseStart then
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
        return not p:isAllNude() end), Util.IdMapper), 1, 1, "#zhaosong2-invoke", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
        not player:isProhibited(p, data.card) end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 2, "#zhaosong3-invoke", self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      player:broadcastSkillInvoke("zhaosong", 1)
      room:notifySkillInvoked(player, self.name, "support")
      room:removePlayerMark(player, "@@zuofen_lei", 1)
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      player:drawCards(1, self.name)
    elseif event == fk.EventPhaseStart then
      player:broadcastSkillInvoke("zhaosong", 2)
      room:notifySkillInvoked(player, self.name, "control")
      room:removePlayerMark(player, "@@zuofen_fu", 1)
      local to = room:getPlayerById(self.cost_data)
      local cards = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
      room:throwCard(cards, self.name, to, player)
    else
      player:broadcastSkillInvoke("zhaosong", 3)
      room:notifySkillInvoked(player, self.name, "offensive")
      room:removePlayerMark(player, "@@zuofen_song", 1)
      for _, id in ipairs(self.cost_data) do
        TargetGroup:pushTargets(data.targetGroup, id)
      end
    end
  end,
}
local lisi = fk.CreateTriggerSkill{
  name = "lisi",
  anim_type = "support",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.NotActive and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Hand] <= #player.player_cards[Player.Hand] end), Util.IdMapper)
    if #targets == 0 then return end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#lisi-invoke:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(self.cost_data, data.card, true, fk.ReasonGive)
  end,
}
zhaosong:addRelatedSkill(zhaosong_trigger)
zuofen:addSkill(zhaosong)
zuofen:addSkill(lisi)
Fk:loadTranslationTable{
  ["zuofen"] = "左棻",
  ["zhaosong"] = "诏颂",
  [":zhaosong"] = "一名其他角色于其摸牌阶段结束时，若其没有标记，你可令其正面向上交给你一张手牌，然后根据此牌的类型，令该角色获得对应的标记："..
  "锦囊牌，“诔”标记；装备牌，“赋”标记；基本牌，“颂”标记。拥有标记的角色：<br>"..
  "进入濒死状态时，可弃置“诔”，回复体力至1点，摸一张牌；<br>"..
  "出牌阶段开始时，可弃置“赋”，弃置一名角色区域内的至多两张牌；<br>"..
  "使用【杀】仅指定一个目标时，可弃置“颂”，为此【杀】额外选择至多两个目标。",
  ["lisi"] = "离思",
  [":lisi"] = "当你于回合外使用的牌结算后，你可将之交给一名手牌数不大于你的其他角色。",
  ["#zhaosong-invoke"] = "诏颂：你可以令 %dest 交给你一张手牌，根据牌的类别其获得效果",
  ["#zhaosong-give"] = "诏颂：交给 %src 一张手牌，根据类别你获得效果<br>"..
  "锦囊-进入濒死状态回复体力并摸牌；装备-弃置一名角色两张牌；基本-使用【杀】可额外指定两个目标",
  ["@@zuofen_lei"] = "诔",
  ["@@zuofen_fu"] = "赋",
  ["@@zuofen_song"] = "颂",
  ["#zhaosong_trigger"] = "诏颂",
  ["#zhaosong1-invoke"] = "诏颂：你可以弃置“诔”，回复体力至1点并摸一张牌",
  ["#zhaosong2-invoke"] = "诏颂：你可以弃置“赋”，弃置一名角色区域内至多两张牌",
  ["#zhaosong3-invoke"] = "诏颂：你可以弃置“颂”，额外选择至多两个目标",
  ["#lisi-invoke"] = "离思：你可以将%arg交给一名手牌数不大于你的其他角色",

  ["$zhaosong1"] = "领诏者，可上而颂之。",
  ["$zhaosong2"] = "今为诏，以上告下也。",
  ["$lisi1"] = "骨肉至亲，化为他人。",
  ["$lisi2"] = "梦想魂归，见所思兮。",
  ["~zuofen"] = "惨怆愁悲……",
}

local fengfangnv = General(extension, "ol__fengfangnv", "qun", 3, 3, General.Female)
local zhuangshu_select = fk.CreateActiveSkill{
  name = "zhuangshu_select",
  expand_pile = "zhuangshu",
  can_use = Util.FalseFunc,
  target_num = 0,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("zhuangshu_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
}
Fk:addSkill(zhuangshu_select)
local zhuangshu = fk.CreateTriggerSkill{
  name = "zhuangshu",
  events = {fk.GameStart, fk.TurnStart},
  anim_type = "support",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.GameStart then
      return player:hasEmptyEquipSlot(Card.SubtypeTreasure) and table.find(player.room.void, function (id)
        local card_name = Fk:getCardById(id).name
        return card_name == "jade_comb" or card_name == "rhino_comb" or card_name == "golden_comb"
      end)
    elseif event == fk.TurnStart then
      return not target.dead and not player:isNude() and target:hasEmptyEquipSlot(Card.SubtypeTreasure)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local combs = table.filter(room.void, function (id)
        local card_name = Fk:getCardById(id).name
        return card_name == "jade_comb" or card_name == "rhino_comb" or card_name == "golden_comb"
      end)
      if #combs == 0 then return false end
      player.special_cards["zhuangshu"] = table.simpleClone(combs)
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      room:setPlayerMark(player, "zhuangshu_cards", combs)
      local success, dat = room:askForUseActiveSkill(player, "zhuangshu_select", "#zhuangshu-choose", true, Util.DummyTable, true)
      room:setPlayerMark(player, "zhuangshu_cards", 0)
      player.special_cards["zhuangshu"] = {}
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })

      if success then
        self.cost_data = dat.cards
        return true
      end
    elseif event == fk.TurnStart then
      local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#zhuangshu-cost::" .. target.id, true)
      if #card > 0 then
        room:doIndicate(player.id, {target.id})
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, math.random(2))
    if event == fk.GameStart then
      room:setCardMark(Fk:getCardById(self.cost_data[1]), MarkEnum.DestructOutEquip, 1)
      room:moveCards({
        fromArea = Card.Void,
        ids = self.cost_data,
        to = player.id,
        toArea = Card.PlayerEquip,
        moveReason = fk.ReasonPut,
        proposer = player.id,
        skillName = self.name,
      })
    elseif event == fk.TurnStart then
      local card_type = Fk:getCardById(self.cost_data[1]):getTypeString()
      room:throwCard(self.cost_data, self.name, player, player)
      if target.dead or (not target:hasEmptyEquipSlot(Card.SubtypeTreasure)) then return false end
      local card_types = {"basic", "trick", "equip"}
      local comb_names = {"jade_comb", "rhino_comb", "golden_comb"}
      local comb_name = comb_names[table.indexOf(card_types, card_type)]
      local comb_id = table.find(room.void, function (id)
        return Fk:getCardById(id).name == comb_name
      end)
      if not comb_id then
        for _, p in ipairs(room:getOtherPlayers(target)) do
          local new = table.find(p:getCardIds("e"), function (id)
            return Fk:getCardById(id).name == comb_name
          end)
          if new then
            comb_id = new
            break
          end
        end
      end
      if comb_id then
        room:setCardMark(Fk:getCardById(comb_id), MarkEnum.DestructOutEquip, 1)
        U.moveCardIntoEquip(room, target, comb_id, self.name, true, player)
      end
    end
  end,
}
local chuiti_viewas = fk.CreateViewAsSkill{
  name = "chuiti_viewas",
  expand_pile = "chuiti",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("chuiti_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
Fk:addSkill(chuiti_viewas)
local chuiticheck = function (player, move_from)
  if move_from == nil then return false end
  if player.id == move_from then return true end
  local target = player.room:getPlayerById(move_from)
  local treasure_id = target:getEquipment(Card.SubtypeTreasure)
  return treasure_id ~= nil and table.contains({"jade_comb", "rhino_comb", "golden_comb"}, Fk:getCardById(treasure_id).name)
end
local chuiti = fk.CreateTriggerSkill{
  name = "chuiti",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then return false end
    local ids = {}
    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard and chuiticheck(player, move.from) then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
            local card = Fk:getCardById(info.cardId)
            if not player:prohibitUse(card) and player:canUse(card) then
              table.insert(ids, info.cardId)
            end
          end
        end
      end
    end
    ids = U.moveCardsHoldingAreaCheck(room, ids)
    if #ids > 0 then
      self.cost_data = ids
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = self.cost_data
    player.special_cards["chuiti"] = table.simpleClone(ids)
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
    room:setPlayerMark(player, "chuiti_cards", ids)
    local success, dat = room:askForUseActiveSkill(player, "chuiti_viewas", "#chuiti-invoke", true, Util.DummyTable, true)
    room:setPlayerMark(player, "chuiti_cards", 0)
    player.special_cards["chuiti"] = {}
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk.skills["chuiti_viewas"]:viewAs(self.cost_data.cards)
    player.room:useCard{
      from = player.id,
      tos = table.map(self.cost_data.targets, function(id) return {id} end),
      card = card,
    }
  end,
}
fengfangnv:addSkill(zhuangshu)
fengfangnv:addSkill(chuiti)
Fk:loadTranslationTable{
  ["ol__fengfangnv"] = "冯方女",
  ["zhuangshu"] = "妆梳",
  [":zhuangshu"] = "游戏开始时，你可以将一张“宝梳”置入你的装备区。一名角色的回合开始时，你可以弃置一张牌，将一张“宝梳”置入其宝物区"..
  "（牌的类别决定“宝梳”种类：基本牌-【琼梳】、锦囊牌-【犀梳】、装备牌-【金梳】，若场上已有则改为移至其装备区）。"..
  "当“宝梳”进入非装备区时，销毁之。",
  ["chuiti"] = "垂涕",
  [":chuiti"] = "每回合限一次，当你或装备区有“宝梳”的角色的一张牌因弃置而置入弃牌堆后，若你能使用此牌，你可以使用之（有次数限制）。",

  ["#zhuangshu-choose"] = "是否使用 妆梳，选择一张“宝梳”置入你的装备区",
  ["zhuangshu_select"] = "妆梳",
  ["#zhuangshu-cost"] = "是否使用妆梳，弃置一张牌，将对应种类的“宝梳”置入%dest的装备区<br>"..
    "基本牌-【琼梳】、锦囊牌-【犀梳】、装备牌-【金梳】",
  ["#chuiti-invoke"] = "是否使用 垂涕，使用其中被弃置的牌",
  ["chuiti_viewas"] = "垂涕",

  ["$zhuangshu1"] = "殿前妆梳，风姿绝世。",
  ["$zhuangshu2"] = "顾影徘徊，丰容靓饰。",
  ["$zhuangshu3"] = "鬓怯琼梳，朱颜消瘦。",
  ["$zhuangshu4"] = "犀梳斜插，醉倚阑干。",
  ["$zhuangshu5"] = "金梳富贵，蒙君宠幸。",
  ["$chuiti1"] = "悲愁垂涕，三日不食。",
  ["$chuiti2"] = "宜数涕泣，示忧愁也。",
  ["~ol__fengfangnv"] = "毒妇妒我……",
}

local yangyi = General(extension, "ol__yangyi", "shu", 3)
local juanxia_viewas = fk.CreateViewAsSkill{
  name = "juanxia_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and card.skill.target_num == 1 then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "juanxia"
    return card
  end,
}
local juanxia_active = fk.CreateActiveSkill{
  name = "juanxia_active",
  interaction = function()
    local names = {}
    local mark = Self:getMark("juanxia-phase")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.name ~= mark[1] then
        if card:isCommonTrick() and card.skill.target_num == 1 and not card.is_derived and
          card.skill:targetFilter(mark[2], {}, {}, card) and
          not Self:isProhibited(Fk:currentRoom():getPlayerById(mark[2]), card) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
}
local juanxia = fk.CreateTriggerSkill{
  name = "juanxia",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "juanxia_viewas", "#juanxia-choose", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1
    local card = Fk.skills["juanxia_viewas"]:viewAs(self.cost_data.cards)
    room:useCard{
      from = player.id,
      tos = table.map(self.cost_data.targets, function(id) return {id} end),
      card = card,
    }
    local to = room:getPlayerById(self.cost_data.targets[1])
    if to.dead or player.dead then return end
    room:setPlayerMark(player, "juanxia-phase", {card.name, to.id})
    local command = "AskForUseActiveSkill"
    room:notifyMoveFocus(player, "juanxia_active")
    local data = {"juanxia_active", "#juanxia-invoke::"..to.id, true, json.encode({})}
    local result = room:doRequest(player, command, json.encode(data))
    if result ~= "" then
      data = json.decode(result)
      room:useVirtualCard(data.interaction_data, nil, player, to, self.name)
      n = 2
    end
    if to.dead or player.dead then return end
    room:setPlayerMark(player, self.name, {to.id, n})
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) ~= 0 and player:getMark(self.name)[1] == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark(self.name)[2]
    room:setPlayerMark(player, self.name, 0)
    for i = 1, n, 1 do
      if not player.dead and not target.dead and
        room:askForSkillInvoke(target, self.name, nil, "#juanxia-slash:"..player.id.."::"..n..":"..i) then
        room:useVirtualCard("slash", nil, target, player, self.name, true)
      end
    end
  end,
}
local dingcuo = fk.CreateTriggerSkill{
  name = "dingcuo",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local cards = player:drawCards(2, self.name)
    if Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color and not player:isKongcheng() then
      player.room:askForDiscard(player, 1, 1, false, self.name, false, ".")
    end
  end
}
Fk:addSkill(juanxia_viewas)
Fk:addSkill(juanxia_active)
yangyi:addSkill(juanxia)
yangyi:addSkill(dingcuo)
Fk:loadTranslationTable{
  ["ol__yangyi"] = "杨仪",
  ["juanxia"] = "狷狭",
  [":juanxia"] = "结束阶段，你可以选择一名其他角色，依次视为对其使用至多两张仅指定唯一目标的普通锦囊牌。"..
  "若如此做，该角色的下回合结束时，其可依次视为对你使用等量的【杀】。",
  ["dingcuo"] = "定措",
  [":dingcuo"] = "每回合限一次，当你造成或受到伤害后，你可以摸两张牌，若这两张牌颜色不同，你弃置一张手牌。",
  ["#juanxia-choose"] = "狷狭：你可以选择一名角色，依次视为对其使用至多两张仅指定唯一目标的普通锦囊牌",
  ["#juanxia-invoke"] = "狷狭：你可以视为对 %dest 再使用一张锦囊",
  ["#juanxia-slash"] = "狷狭：是否视为对 %src 使用【杀】？（共%arg张，第%arg2张）",

  ["$juanxia1"] = "汝有何功？竟能居我之上！",
  ["$juanxia2"] = "恃才傲立，恩怨必偿。",
  ["$dingcuo1"] = "丞相新丧，吾当继之！",
  ["$dingcuo2"] = "规画分部，筹度粮谷。",
  ["~ol__yangyi"] = "魏延庸奴，吾，誓杀汝！",
}

local zhuling = General(extension, "ol__zhuling", "wei", 4)
local function getTrueSkills(player)
  local skills = {}
  for _, s in ipairs(player.player_skills) do
    if not (s.attached_equip or s.name[#s.name] == "&") then
      table.insertIfNeed(skills, s.name)
    end
  end
  return skills
end
local jixian = fk.CreateTriggerSkill{
  name = "jixian",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, Fk:cloneCard("slash")) and
        (p:getEquipment(Card.SubtypeArmor) or #getTrueSkills(p) > #getTrueSkills(player) or not p:isWounded()) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jixian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    local to = player.room:getPlayerById(self.cost_data)
    if to:getEquipment(Card.SubtypeArmor) then
      n = n + 1
    end
    if #getTrueSkills(to) > #getTrueSkills(player) then
      n = n + 1
    end
    if not to:isWounded() then
      n = n + 1
    end
    player.room:useVirtualCard("slash", nil, player, to, self.name, true)
    if not player.dead then
      player:drawCards(n, self.name)
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if not data.damageDealt then
      player.room:loseHp(player, 1, self.name)
    end
  end,
}
zhuling:addSkill(jixian)
Fk:loadTranslationTable{
  ["ol__zhuling"] = "朱灵",
  ["jixian"] = "急陷",
  [":jixian"] = "摸牌阶段结束时，你可以视为对符合以下任意条件的一名其他角色使用一张【杀】并摸X张牌（X为其符合的条件数）："..
  "1.装备区里有防具牌；2.技能数多于你；3.未受伤。然后若此【杀】未造成伤害，你失去1点体力。",
  ["#jixian-choose"] = "急陷：你可以视为使用【杀】并摸牌，若未造成伤害则失去1点体力",

  ["$jixian1"] = "全军出击，速攻敌城。",
  ["$jixian2"] = "勿以我为念，攻城！",
  ["~ol__zhuling"] = "母亲，弟弟，我来了……",
}

local zhanghe = General(extension, "ol__zhanghe", "qun", 4)
local ol__zhouxuan = fk.CreateTriggerSkill{
  name = "ol__zhouxuan",
  anim_type = "drawcard",
  expand_pile = "zhanghe_xuan",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player, 1, 5, false, self.name, true, ".", "#ol__zhouxuan-invoke")
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("zhanghe_xuan", self.cost_data, true, self.name)
  end,
}
local ol__zhouxuan_trigger = fk.CreateTriggerSkill{
  name = "#ol__zhouxuan_trigger",
  mute = true,
  expand_pile = "zhanghe_xuan",
  events = {fk.EventPhaseEnd, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and #player:getPile("zhanghe_xuan") > 0 then
      if event == fk.EventPhaseEnd then
        return player:hasSkill("ol__zhouxuan") and player.phase == Player.Play
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      room:moveCards({
        from = player.id,
        ids = player:getPile("zhanghe_xuan"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "ol__zhouxuan",
        specialName = "zhanghe_xuan",
      })
    else
      player:broadcastSkillInvoke("ol__zhouxuan")
      room:notifySkillInvoked(player, "ol__zhouxuan", "drawcard")
      if not table.every(room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Hand] < #player.player_cards[Player.Hand] end) then
        player:drawCards(#player:getPile("zhanghe_xuan"), "ol__zhouxuan")
      else
        player:drawCards(1, "ol__zhouxuan")
      end
      local card = room:askForCard(player, 1, 1, false, "ol__zhouxuan", false, ".|.|.|zhanghe_xuan|.|.", "#ol__zhouxuan-discard", "zhanghe_xuan")
      if #card == 0 then card = {table.random(player:getPile("zhanghe_xuan"))} end
      room:moveCards({
        from = player.id,
        ids = card,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "ol__zhouxuan",
        specialName = "zhanghe_xuan",
      })
    end
  end,
}
ol__zhouxuan:addRelatedSkill(ol__zhouxuan_trigger)
zhanghe:addSkill(ol__zhouxuan)
Fk:loadTranslationTable{
  ["ol__zhanghe"] = "张郃",
  ["ol__zhouxuan"] = "周旋",
  [":ol__zhouxuan"] = "弃牌阶段开始时，你可将至多五张手牌置于武将牌上（称为“旋”）直到你下个出牌阶段结束。"..
  "当你使用一张牌时，你摸一张牌，然后移去一张“旋”；若你的手牌不是场上唯一最多，则改为摸X张牌（X为“旋”的数量）。",
  ["zhanghe_xuan"] = "旋",
  ["#ol__zhouxuan-invoke"] = "周旋：你可以将至多5张手牌置为“旋”",
  ["#ol__zhouxuan-discard"] = "周旋：请移去一张“旋”",

  ["$ol__zhouxuan1"] = "详勘细察，洞若观火。",
  ["$ol__zhouxuan2"] = "知敌底细，方能百战百胜。",
  ["~ol__zhanghe"] = "我终究是看不透这人心。",
}

local dongzhao = General(extension, "ol__dongzhao", "wei", 3)
local xianlve = fk.CreateTriggerSkill{
  name = "xianlve",
  anim_type = "control",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target.role == "lord" and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#xianlve-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() then
        table.insertIfNeed(names, card.name)
      end
    end
    local choice = player.room:askForChoice(player, names, self.name, "#xianlve-choice")
    player.room:setPlayerMark(player, self.name, choice)
  end,
}
local xianlve_trigger = fk.CreateTriggerSkill{
  name = "#xianlve_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("xianlve") and target ~= player and player:getMark("xianlve") ~= 0 and
      player:getMark("xianlve") == data.card.trueName and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("xianlve")
    room:notifySkillInvoked(player, "xianlve", "drawcard")
    local cards = player:drawCards(2, "xianlve")
    for _, id in ipairs(cards) do
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        room:setCardMark(Fk:getCardById(id), "xianlve", 1)
      end
    end
    while table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("xianlve") > 0 end) do
      if not room:askForUseActiveSkill(player, "xianlve_active", "#xianlve-give", true) then
        for _, id in ipairs(player.player_cards[Player.Hand]) do
          room:setCardMark(Fk:getCardById(id), "xianlve", 0)
        end
      end
    end
    local skill = Fk.skills["xianlve"]
    skill:use(event, target, player, data)
  end,
}
local xianlve_active = fk.CreateActiveSkill{
  name = "xianlve_active",
  mute = true,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Fk:getCardById(to_select):getMark("xianlve") > 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    for _, id in ipairs(effect.cards) do
      room:setCardMark(Fk:getCardById(id), "xianlve", 0)
    end
    if effect.tos[1] ~= effect.from then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(effect.cards)
      room:obtainCard(target, dummy, false, fk.ReasonGive)
    end
  end,
}
local zaowang = fk.CreateActiveSkill{
  name = "zaowang",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#zaowang-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:changeMaxHp(target, 1)
    if target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    end
    target:drawCards(3, self.name)
    room:setPlayerMark(target, "@@zaowang", 1)
  end,
}
local zaowang_trigger = fk.CreateTriggerSkill{
  name = "#zaowang_trigger",

  refresh_events = {fk.BeforeGameOverJudge},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@zaowang") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if target.role == "lord" and player.role == "loyalist" then
      player.role = "lord"
      target.role = "loyalist"
      for _, p in ipairs(room.players) do
        room:notifyProperty(p, player, "role")
        room:notifyProperty(p, target, "role")
      end
      room:setPlayerMark(player, "@@zaowang", 0)
    elseif target == player and player.role == "rebel" and data.damage and data.damage.from and
      (data.damage.from.role == "lord" or data.damage.from.role == "loyalist") then
      room:gameOver("lord+loyalist")
    end
  end,
}
Fk:addSkill(xianlve_active)
xianlve:addRelatedSkill(xianlve_trigger)
zaowang:addRelatedSkill(zaowang_trigger)
dongzhao:addSkill(xianlve)
dongzhao:addSkill(zaowang)
Fk:loadTranslationTable{
  ["ol__dongzhao"] = "董昭",
  ["xianlve"] = "先略",
  [":xianlve"] = "主公的回合开始时，你可以声明一种普通锦囊牌牌名。每回合限一次，当其他角色使用被声明的牌后，你摸两张牌并分配给任意角色，"..
  "然后重新声明一张普通锦囊牌。",
  ["zaowang"] = "造王",
  [":zaowang"] = "限定技，出牌阶段，你可以令一名角色增加1点体力上限、回复1点体力并摸三张牌，若其为：忠臣，当主公死亡时与主公交换身份牌；"..
  "反贼，当其被主公或忠臣杀死时，主公方获胜。",
  ["#xianlve-invoke"] = "先略：你可以声明“先略”锦囊牌名",
  ["#xianlve-choice"] = "先略：选择要记录的牌名",
  ["#xianlve-give"] = "先略：将这些牌分配给任意角色，点“取消”自己保留",
  ["xianlve_active"] = "先略",
  ["@@zaowang"] = "造王",
  ["#zaowang-invoke"] = "造王：令一名角色加1点体力上限、回复1点体力并摸三张牌！",

  ["$xianlve1"] = "行略于先，未雨绸缪。",
  ["$xianlve2"] = "先见梧叶，而后知秋。",
  ["$zaowang1"] = "大魏当兴，吾主可王。",
  ["$zaowang2"] = "身加九锡，当君不让。",
  ["~ol__dongzhao"] = "昭，一心向魏，绝无二心……",
}

local wuyan = General(extension, "wuyanw", "wu", 4)
local lanjiang = fk.CreateTriggerSkill{
  name = "lanjiang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p.player_cards[Player.Hand] >= #player.player_cards[Player.Hand] then
        table.insert(targets, p.id)
        if room:askForSkillInvoke(p, self.name, nil, "#lanjiang-choose::"..player.id) then
          player:drawCards(1, self.name)
        end
      end
    end
    local targets1 = table.filter(targets, function(id)
      return #room:getPlayerById(id).player_cards[Player.Hand] == #player.player_cards[Player.Hand] end)
    if #targets1 > 0 then
      local to = room:askForChoosePlayers(player, targets1, 1, 1, "#lanjiang-damage", self.name, true)
      if #to > 0 then
        room:doIndicate(player.id, {to[1]})
        room:damage{
          from = player,
          to = room:getPlayerById(to[1]),
          damage = 1,
          skillName = self.name,
        }
      end
    end
    local targets2 = table.filter(targets, function (id)
      return #room:getPlayerById(id).player_cards[Player.Hand] < #player.player_cards[Player.Hand] end)
    if #targets2 > 0 then
      local to = room:askForChoosePlayers(player, targets2, 1, 1, "#lanjiang-draw", self.name, true)
      if #to > 0 then
        room:doIndicate(player.id, {to[1]})
        room:getPlayerById(to[1]):drawCards(1, self.name)
      end
    end
  end,
}
wuyan:addSkill(lanjiang)
Fk:loadTranslationTable{
  ["wuyanw"] = "吾彦",
  ["lanjiang"] = "澜江",
  [":lanjiang"] = "结束阶段，你可以令所有手牌数不小于你的角色依次选择是否令你摸一张牌。选择完成后，你可以对手牌数等于你的其中一名角色造成1点伤害，"..
  "然后令手牌数小于你的其中一名角色摸一张牌。",
  ["#lanjiang-choose"] = "澜江：是否令 %dest 摸一张牌？",
  ["#lanjiang-damage"] = "澜江：你可以对其中一名角色造成1点伤害",
  ["#lanjiang-draw"] = "澜江：你可以令其中一名角色摸一张牌",

  ["$lanjiang1"] = "一人擒虎力，千军拗锋芒。",
  ["$lanjiang2"] = "勇力擎四疆，狂澜涌八荒。",
  ["~wuyanw"] = "世间再无擒虎客……",
}

local chendeng = General(extension, "ol__chendeng", "qun", 4)
local fengji = fk.CreateTriggerSkill{
  name = "fengji",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"fengji_draw", "fengji_slash", "Cancel"}
    while true do
      local choice = room:askForChoice(player, choices, self.name, "#fengji-choice")
      table.removeOne(choices, choice)
      if choice == "Cancel" then
        break
      else
        room:setPlayerMark(player, "@"..choice, -1)
        local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#fengji-choose:::"..choice, self.name, true)
        if #to > 0 then
          room:addPlayerMark(room:getPlayerById(to[1]), "@"..choice, 2)
        end
      end
    end
    if #choices > 0 then
      for _, choice in ipairs(choices) do
        room:addPlayerMark(player, "@"..choice, 1)
      end
    end
  end,

  refresh_events = {fk.DrawNCards, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.DrawNCards then
        return player:getMark("@fengji_draw") ~= 0
      else
        return player:getMark("@fengji_draw") ~= 0 or player:getMark("@fengji_slash") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      data.n = data.n + player:getMark("@fengji_draw")
      room:setPlayerMark(player, "@fengji_draw", 0)
    else
      room:setPlayerMark(player, "@fengji_draw", 0)
      room:setPlayerMark(player, "@fengji_slash", 0)
    end
  end,
}
local fengji_targetmod = fk.CreateTargetModSkill{
  name = "#fengji_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@fengji_slash") ~= 0 and scope == Player.HistoryPhase then
      return player:getMark("@fengji_slash")
    end
  end,
}
fengji:addRelatedSkill(fengji_targetmod)
chendeng:addSkill(fengji)
Fk:loadTranslationTable{
  ["ol__chendeng"] = "陈登",
  ["fengji"] = "丰积",
  [":fengji"] = "摸牌阶段开始时，你可以令你本回合以下任意项数值-1，令一名其他角色下回合对应项数值+2，令你本回合未选择选项的数值+1：<br>"..
  "1.摸牌阶段摸牌数；2.出牌阶段使用【杀】次数上限。",
  ["#fengji-choice"] = "丰积：令你本回合-1，令一名其他角色下回合+2，令你本回合未选择的+1",
  ["fengji_draw"] = "摸牌阶段摸牌数",
  ["fengji_slash"] = "出牌阶段使用【杀】次数",
  ["@fengji_draw"] = "丰积:摸牌",
  ["@fengji_slash"] = "丰积:使用杀",
  ["#fengji-choose"] = "丰积：你可以令一名其他角色下回合%arg+2",

  ["$fengji1"] = "取舍有道，待机而赢。",
  ["$fengji2"] = "此退彼进，月亏待盈。",
  ["~ol__chendeng"] = "可无命，不可无脍……",
}

local tianyu = General(extension, "ol__tianyu", "wei", 4)
local saodi = fk.CreateTriggerSkill{
  name = "saodi",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and data.tos[1][1] ~= player.id then
      local left, right = 0, 0
      local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
      local temp = player
      while temp ~= to do
        if not temp.dead then
          right = right + 1
        end
        temp = temp.next
      end
      left = #Fk:currentRoom().alive_players - right
      if math.min(left, right) > 1 then
        self.cost_data = "both"
        if left > right then
          self.cost_data = "right"
        elseif left < right then
          self.cost_data = "left"
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel", "left", "right"}
    if self.cost_data == "left" then
      table.removeOne(choices, "right")
    elseif self.cost_data == "right" then
      table.removeOne(choices, "left")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#saodi-invoke::"..data.tos[1][1]..":"..data.card:toLogString())
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local dest = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    local from, to = player, dest
    if self.cost_data == "left" then
      from, to = dest, player
    end
    local temp = from.next
    while temp ~= to do
      if not temp.dead and not player:isProhibited(temp, data.card) then
        TargetGroup:pushTargets(data.targetGroup, temp.id)
        player.room:doIndicate(player.id, {temp.id})
      end
      temp = temp.next
    end
  end,
}
local zhuitao = fk.CreateTriggerSkill{
  name = "zhuitao",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p:getMark(self.name) == 0 or not table.contains(p:getMark(self.name), player.id) end)
    if #targets == 0 then return end
    local to = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#zhuitao-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local mark = to:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insert(mark, player.id)
    room:setPlayerMark(to, self.name, mark)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.to.dead and data.to:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = data.to:getMark(self.name)
    table.removeOne(mark, player.id)
    if #mark == 0 then mark = 0 end
    room:setPlayerMark(data.to, self.name, mark)
  end,
}
local zhuitao_distance = fk.CreateDistanceSkill{
  name = "#zhuitao_distance",
  correct_func = function(self, from, to)
    if to:getMark("zhuitao") ~= 0 and table.contains(to:getMark("zhuitao"), from.id) then
      return -1
    end
  end,
}
zhuitao:addRelatedSkill(zhuitao_distance)
tianyu:addSkill(saodi)
tianyu:addSkill(zhuitao)
Fk:loadTranslationTable{
  ["ol__tianyu"] = "田豫",
  ["saodi"] = "扫狄",
  [":saodi"] = "当你使用【杀】或普通锦囊牌仅指定一名其他角色为目标时，你可以令你与其之间（计算座次较短的方向）的角色均成为此牌的目标。",
  ["zhuitao"] = "追讨",
  [":zhuitao"] = "准备阶段，你可以令你与一名未以此法减少距离的其他角色的距离-1。当你对其造成伤害后，失去你以此法对其减少的距离。",
  ["#saodi-invoke"] = "扫狄：你可以令你与 %dest 之间一个方向上所有角色均成为%arg的目标",
  ["left"] = "←顺时针方向",
  ["right"] = "逆时针方向→",
  ["#zhuitao-choose"] = "追讨：你可以选择一名角色，你至其距离-1直到你对其造成伤害",

  ["$saodi1"] = "狄获悬野，秋风扫之！",
  ["$saodi2"] = "戎狄作乱，岂能坐视！",
  ["$zhuitao1"] = "敌将休走，汝命休矣！",
  ["$zhuitao2"] = "长缨在手，敌寇何逃！",
  ["~ol__tianyu"] = "命数之沙，已尽矣……",
}

local fanjiangzhangda = General(extension, "fanjiangzhangda", "wu", 4)
fanjiangzhangda.subkingdom = "shu"
local yuanchou = fk.CreateTriggerSkill{
  name = "yuanchou",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and data.card.color == Card.Black
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from == player.id then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "offensive")
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
    end
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)

    data.extra_data = data.extra_data or {}
    data.extra_data.yuanchouNullified = data.extra_data.yuanchouNullified or {}
    data.extra_data.yuanchouNullified[tostring(data.to)] = (data.extra_data.yuanchouNullified[tostring(data.to)] or 0) + 1
  end,

  refresh_events = { fk.CardUseFinished },
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.yuanchouNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.yuanchouNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.yuanchouNullified = nil
  end,
}
local juesheng = fk.CreateViewAsSkill{
  name = "juesheng",
  anim_type = "offensive",
  pattern = "duel",
  frequency = Skill.Limited,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local c = Fk:cloneCard("duel")
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(use.tos)[1])
    use.additionalDamage = (use.additionalDamage or 0) + math.max(to:usedCardTimes("slash", Player.HistoryGame), 1) - 1
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
}
local juesheng_record = fk.CreateTriggerSkill{
  name = "#juesheng_record",
  mute = true,
  events = {fk.CardUseFinished, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.CardUseFinished then
        return data.card and table.contains(data.card.skillNames, "juesheng")
      else
        return player:getMark("juesheng") > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
        local p = room:getPlayerById(id)
        if not p.dead and not p:hasSkill("juesheng", true) then
          room:setPlayerMark(p, "juesheng", 1)
          room:handleAddLoseSkills(p, "juesheng", nil, true, false)
        end
      end
    else
      room:setPlayerMark(player, "juesheng", 0)
      room:handleAddLoseSkills(player, "-juesheng", nil, true, false)
    end
  end,
}
juesheng:addRelatedSkill(juesheng_record)
fanjiangzhangda:addSkill(yuanchou)
fanjiangzhangda:addSkill(juesheng)
Fk:loadTranslationTable{
  ["fanjiangzhangda"] = "范疆张达",
  ["yuanchou"] = "怨仇",
  [":yuanchou"] = "锁定技，你使用的黑色【杀】无视目标角色防具，其他角色对你使用的黑色【杀】无视你的防具。",
  ["juesheng"] = "决生",
  [":juesheng"] = "限定技，你可以视为使用一张伤害为X的【决斗】（X为目标角色本局使用【杀】的数量且至少为1），然后其获得本技能直到其下回合结束。",

  ["$yuanchou1"] = "鞭挞之仇，不共戴天！",
  ["$yuanchou2"] = "三将军怎可如此对待我二人！",
  ["$juesheng1"] = "向死而生，索性拼个鱼死网破！",
  ["$juesheng2"] = "张翼德，我二人报仇来了！",
  ["~fanjiangzhangda"] = "吴侯救我！",
}

local yanghu = General(extension, "ol__yanghu", "jin", 4)
local huaiyuan = fk.CreateTriggerSkill{
  name = "huaiyuan",
  anim_type = "support",
  events = {fk.AfterCardsMove, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(self) then
      return player:getMark("huaiyuan") > 0
    else
      return target == player and player:hasSkill(self,false,true)
      and (player:getMark("@huaiyuan_maxcards") > 0 or player:getMark("@huaiyuan_attackrange") > 0)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    else
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#huaiyuan-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local n = player:getMark("huaiyuan")
      room:setPlayerMark(player, "huaiyuan", 0)
      local choices = {"huaiyuan_maxcards", "huaiyuan_attackrange", "draw1"}
      for _ = 1, n do
        local success, dat = room:askForUseActiveSkill(player, "huaiyuan_active", "#huaiyuan-invoke", false)
        local to = success and room:getPlayerById(dat.targets[1]) or table.random(room.alive_players)
        local choice = player:getMark("huaiyuan_active")
        if type(choice) ~= "string" then choice = table.random(choices) end
        if choice == "draw1" then
          to:drawCards(1, self.name)
        else
          room:addPlayerMark(to, "@"..choice, 1)
          room:broadcastProperty(to, "MaxCards")
        end
      end
    else
      local to = room:getPlayerById(self.cost_data)
      room:addPlayerMark(to, "@huaiyuan_maxcards", player:getMark("@huaiyuan_maxcards"))
      room:addPlayerMark(to, "@huaiyuan_attackrange", player:getMark("@huaiyuan_attackrange"))
      room:broadcastProperty(to, "MaxCards")
    end
  end,

  refresh_events = {fk.AfterDrawInitialCards, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterDrawInitialCards then
      return target == player and player:hasSkill(self)
    else
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@appease") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterDrawInitialCards then
      local cards = player:getCardIds(Player.Hand)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@appease", 1)
      end
      room:setPlayerMark(player, "@huaiyuan", #cards)
    else
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@appease") > 0 then
              n = n + 1
              room:setCardMark(Fk:getCardById(info.cardId), "@@appease", 0)
            end
          end
        end
      end
      room:removePlayerMark(player, "@huaiyuan", n)
      if player:hasSkill(self) then
        room:addPlayerMark(player, "huaiyuan", n)
      end
    end
  end,
}
local huaiyuan_attackrange = fk.CreateAttackRangeSkill{
  name = "#huaiyuan_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@huaiyuan_attackrange")
  end,
}
local huaiyuan_maxcards = fk.CreateMaxCardsSkill{
  name = "#huaiyuan_maxcards",
  correct_func = function(self, player)
    return player:getMark("@huaiyuan_maxcards")
  end,
}
local huaiyuan_active = fk.CreateActiveSkill{
  name = "huaiyuan_active",
  interaction = function()
    return UI.ComboBox {choices = {"huaiyuan_maxcards", "huaiyuan_attackrange", "draw1"}}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "huaiyuan_active", self.interaction.data)
  end,
}
Fk:addSkill(huaiyuan_active)
huaiyuan:addRelatedSkill(huaiyuan_maxcards)
huaiyuan:addRelatedSkill(huaiyuan_attackrange)
yanghu:addSkill(huaiyuan)
local chongxin = fk.CreateActiveSkill{
  name = "chongxin",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#chongxin-card")
    room:recastCard(card, target, self.name)
    if not player:isNude() then
      card = room:askForCard(player, 1, 1, true, self.name, false, ".", "#chongxin-card")
      room:recastCard(card, player, self.name)
    end
  end,
}
local dezhang = fk.CreateTriggerSkill{
  name = "dezhang",
  frequency = Skill.Wake,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return not table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@appease") > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "weishu", nil)
  end,
}
local weishu = fk.CreateTriggerSkill{
  name = "weishu",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.to == player.id and move.moveReason == fk.ReasonDraw and move.skillName ~= self.name and player.phase ~= Player.Draw then
            self.cost_data = {"draw", 0}
            return true
          end
          if move.from == player.id and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard then
            self.cost_data = {"discard", 0}
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt
    if self.cost_data[1] == "draw" then
      targets = table.map(room:getAlivePlayers(), Util.IdMapper)
      prompt = "#weishu-draw"
    elseif self.cost_data[1] == "discard" then
      targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), Util.IdMapper)
      prompt = "#weishu-discard"
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, false)
    if #to > 0 then
      self.cost_data[2] = to[1]
    else
      self.cost_data[2] = table.random(targets)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] == "draw" then
      room:getPlayerById(self.cost_data[2]):drawCards(1, self.name)
    else
      local to = room:getPlayerById(self.cost_data[2])
      local id = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({id}, self.name, to, player)
    end
  end,
}
yanghu:addSkill(chongxin)
yanghu:addSkill(dezhang)
yanghu:addRelatedSkill(weishu)
Fk:loadTranslationTable{
  ["ol__yanghu"] = "羊祜",
  ["huaiyuan"] = "怀远",
  [":huaiyuan"] = "你的初始手牌称为“绥”。你每失去一张“绥”时，令一名角色手牌上限+1或攻击范围+1或摸一张牌。当你死亡时，你可令一名其他角色获得你以此法增加的手牌上限和攻击范围。",
  ["chongxin"] = "崇信",
  [":chongxin"] = "出牌阶段限一次，你可令一名有手牌的其他角色与你各重铸一张牌。",
  ["dezhang"] = "德彰",
  [":dezhang"] = "觉醒技，回合开始时，若你没有“绥”，你减1点体力上限，获得〖卫戍〗。",
  ["weishu"] = "卫戍",
  [":weishu"] = "锁定技，你于摸牌阶段外非因〖卫戍〗摸牌后，你令一名角色摸一张牌；你于非弃牌阶段弃置牌后，你弃置一名其他角色的一张牌。",
  ["@@appease"] = "绥",
  ["@huaiyuan"] = "怀远",
  ["huaiyuan_active"] = "怀远",
  ["#huaiyuan-invoke"] = "怀远：令一名角色手牌上限+1 / 攻击范围+1 / 摸一张牌",
  ["#huaiyuan-choose"] = "怀远：你可以令一名其他角色获得“怀远”增加的手牌上限和攻击范围",
  ["#huaiyuan-choice"] = "怀远：选择令 %dest 执行的一项",
  ["huaiyuan_maxcards"] = "手牌上限+1",
  ["huaiyuan_attackrange"] = "攻击范围+1",
  ["@huaiyuan_maxcards"] = "怀远:手牌上限",
  ["@huaiyuan_attackrange"] = "怀远:攻击范围",
  ["#chongxin-card"] = "崇信：请重铸一张牌",
  ["#weishu-draw"] = "卫戍：令一名角色摸一张牌",
  ["#weishu-discard"] = "卫戍：弃置一名其他角色的一张牌",

  ["$huaiyuan1"] = "当怀远志，砥砺奋进。",
  ["$huaiyuan2"] = "举有成资，谋有全策。",
  ["$chongxin1"] = "非诚不行，无信不立。",
  ["$chongxin2"] = "以诚待人，可得其心。",
  ["$dezhang1"] = "以德怀柔，广得军心。",
  ["$dezhang2"] = "德彰四海，威震八荒。",
  ["$weishu1"] = "水来土掩，兵来将挡。",
  ["$weishu2"] = "吴人来犯，当用心戒备。",
  ["~ol__yanghu"] = "当断不断，反受其乱……",
}

local qinghegongzhu = General(extension, "qinghegongzhu", "wei", 3, 3, General.Female)

local zengou = fk.CreateTriggerSkill{
  name = "zengou",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.name == "jink" and player:inMyAttackRange(player.room:getPlayerById(data.from))
  end,
  on_cost = function(self, event, target, player, data)
    local discard_data = {
      num = 1,
      min_num = player.hp > 0 and 0 or 1,
      include_equip = true,
      skillName = self.name,
      pattern = ".|.|.|.|.|^basic",
    }
    local success, ret = player.room:askForUseActiveSkill(player, "discard_skill",
      "#zengou-invoke::"..target.id .. ":" .. data.card:toLogString(), true, discard_data)
    if success then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    if #self.cost_data > 0 then
      room:throwCard(self.cost_data, self.name, player, player)
    else
      room:loseHp(player, 1, self.name)
    end
    if not player.dead then
      local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if #cardlist > 0 and table.every(cardlist, function(id) return room:getCardArea(id) == Card.Processing end) then
        room:obtainCard(player.id, data.card, true)
      end
    end
    data.tos = {}
  end,
}
local zhangjiq = fk.CreateTriggerSkill{
  name = "zhangjiq",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and
      (player:getMark("zhangji1-turn") > 0 or (player:getMark("zhangji2-turn") > 0 and not target:isNude()))
  end,
  on_cost = function(self, event, target, player, data)
    if player:getMark("zhangji1-turn") > 0 then
      if player.room:askForSkillInvoke(player, self.name, data, "#zhangji-draw::"..target.id) then
        self.cost_data = "zhangji1"
        return true
      end
    else
      if player.room:askForSkillInvoke(player, self.name, data, "#zhangji-discard::"..target.id) then
        self.cost_data = "zhangji2"
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "zhangji1" then
      target:drawCards(2, self.name)
      if player:getMark("zhangji2-turn") > 0 and not target:isNude() and
        room:askForSkillInvoke(player, self.name, data, "#zhangji-discard::"..target.id) then
        room:doIndicate(player.id, {target.id})
        room:askForDiscard(target, 2, 2, true, self.name, false)
      end
    else
      room:doIndicate(player.id, {target.id})
      room:askForDiscard(target, 2, 2, true, self.name, false)
    end
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "zhangji1-turn", 1)
    else
      player.room:addPlayerMark(player, "zhangji2-turn", 1)
    end
  end,
}
qinghegongzhu:addSkill(zengou)
qinghegongzhu:addSkill(zhangjiq)
Fk:loadTranslationTable{
  ["qinghegongzhu"] = "清河公主",
  ["zengou"] = "谮构",
  [":zengou"] = "当你攻击范围内一名角色使用【闪】时，你可以弃置一张非基本牌或失去1点体力，令此【闪】无效，然后你获得之。",
  ["zhangjiq"] = "长姬",
  [":zhangjiq"] = "一名角色的结束阶段，若你本回合：造成过伤害，你可以令其摸两张牌；受到过伤害，你可以令其弃置两张牌。",
  ["#zengou-invoke"] = "谮构：你可以弃置一张非基本牌（不选牌则失去1点体力），令 %dest 使用的 %arg 无效且你获得之",
  ["#zhangji-draw"] = "长姬：你可以令 %dest 摸两张牌",
  ["#zhangji-discard"] = "长姬：你可以令 %dest 弃置两张牌",

  ["$zengou1"] = "此书定能置夏侯楙于死地。",
  ["$zengou2"] = "夏侯违制，请君上定夺。",
  ["$zhangjiq1"] = "魏武有子数十，唯我最长。",
  ["$zhangjiq2"] = "长姐为大，众弟怎可悖之？",
  ["~qinghegongzhu"] = "我言非虚，君上何疑于我？",
}

local tengfanglan = General(extension, "ol__tengfanglan", "wu", 3, 3, General.Female)
local function CanLuochong(player, target, i)
  if player:getMark("luochong"..tostring(i)) ~= "0" then return false end
  if target ~= nil then
    if target:getMark("luochong-round") > 0 then return false end
    if not target:isWounded() and i == 1 then return false end
    if target:isNude() and i == 3 then return false end
  end
  return true
end
local luochong = fk.CreateTriggerSkill{
  name = "luochong",
  anim_type = "masochism",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        if player:getMark("luochong_damaged-turn") == 0 then
          player.room:setPlayerMark(player, "luochong_damaged-turn", 1)
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      for i = 1, 4, 1 do
        if CanLuochong(player, p, i) then
          table.insert(targets, p.id)
          break
        end
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#luochong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = table.map(table.filter({1, 2, 3, 4}, function(i)
      return CanLuochong(player, to, i) end), function(n) return "luochong"..tostring(n) end)
    room:setPlayerMark(to, "luochong-round", 1)
    local choice = room:askForChoice(player, choices, self.name, "#luochong-choice::"..to.id)
    if choice == "luochong1" then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    elseif choice == "luochong2" then
      room:loseHp(to, 1, self.name)
    elseif choice == "luochong3" then
      if #to:getCardIds("he") < 3 then
        to:throwAllCards("he")
      else
        room:askForDiscard(to, 2, 2, true, self.name, false)
      end
    elseif choice == "luochong4" then
      to:drawCards(2, self.name)
    end
    room:setPlayerMark(player, choice, "✓")
    room:setPlayerMark(player, "@luochong", string.format("%s-%s-%s-%s",
    player:getMark("luochong1"),
    player:getMark("luochong2"),
    player:getMark("luochong3"),
    player:getMark("luochong4")))
  end,

  refresh_events = {fk.GameStart, fk.RoundStart},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for i = 1, 4, 1 do
      if player:getMark("luochong"..tostring(i)) ~= "×" then
        room:setPlayerMark(player, "luochong"..tostring(i), "0")
      end
    end
    room:setPlayerMark(player, "@luochong", string.format("%s-%s-%s-%s",
    player:getMark("luochong1"),
    player:getMark("luochong2"),
    player:getMark("luochong3"),
    player:getMark("luochong4")))
  end,
}
local aichen = fk.CreateTriggerSkill{
  name = "aichen",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return #table.filter({1, 2, 3, 4}, function(i) return CanLuochong(player, nil, i) end) > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.map(table.filter({1, 2, 3, 4}, function(i)
      return CanLuochong(player, nil, i) end), function(n) return "luochong"..tostring(n) end)
    local choice = room:askForChoice(player, choices, self.name, "#aichen-choice")
    room:setPlayerMark(player, choice, "×")
    room:setPlayerMark(player, "@luochong", string.format("%s-%s-%s-%s",
    player:getMark("luochong1"),
    player:getMark("luochong2"),
    player:getMark("luochong3"),
    player:getMark("luochong4")))
  end,
}
tengfanglan:addSkill(luochong)
tengfanglan:addSkill(aichen)
Fk:loadTranslationTable{
  ["ol__tengfanglan"] = "滕芳兰",
  ["luochong"] = "落宠",
  [":luochong"] = "准备阶段或当你每回合首次受到伤害后，你可以选择一项，令一名角色：1.回复1点体力；2.失去1点体力；3.弃置两张牌；4.摸两张牌。"..
  "每轮每项限一次，每轮对每名角色限一次。",
  ["aichen"] = "哀尘",
  [":aichen"] = "锁定技，当你进入濒死状态时，若〖落宠〗选项数大于1，你移除其中一项。",
  ["#luochong-choose"] = "落宠：你可以令一名角色执行一项效果",
  ["@luochong"] = "落宠",
  ["#luochong-choice"] = "落宠：选择令 %dest 执行的一项",
  ["luochong1"] = "回复1点体力",
  ["luochong2"] = "失去1点体力",
  ["luochong3"] = "弃置两张牌",
  ["luochong4"] = "摸两张牌",
  ["#aichen-choice"] = "哀尘：移除一种“落宠”选项",

  ["$luochong1"] = "宠至莫言非，思移难恃貌。",
  ["$luochong2"] = "君王一时情，安有恩长久。",
  ["$aichen1"] = "泪干红落面，心结发垂头。",
  ["$aichen2"] = "思君应叹息，苦泪无言垂。",
  ["~ol__tengfanglan"] = "封侯归命，夫妻同归……",
}

local menghuo = General(extension, "sp__menghuo", "qun", 4)
local function doManwang(player, i)
  local room = player.room
  if i == 1 then
    room:handleAddLoseSkills(player, "panqin", nil, true, false)
  elseif i == 2 then
    player:drawCards(1, "manwang")
  elseif i == 3 then
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "manwang",
      }
    end
  elseif i == 4 then
    player:drawCards(2, "manwang")
    room:handleAddLoseSkills(player, "-panqin", nil, true, false)
  end
end
local manwang = fk.CreateActiveSkill{
  name = "manwang",
  anim_type = "special",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for i = 1, #effect.cards, 1 do
      if i > 4 or player:getMark("@manwang") > (4-i) then return end
      doManwang(player, i)
    end
  end,
}
local panqin = fk.CreateTriggerSkill{
  name = "panqin",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (player.phase == Player.Play or player.phase == Player.Discard) then
      local ids = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) and player.room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
        return false
      end, Player.HistoryPhase)
      if #ids == 0 then return false end
      local card = Fk:cloneCard("savage_assault")
      card:addSubcards(ids)
      local tos = table.filter(player.room:getOtherPlayers(player), function(p) return not player:isProhibited(p, card) end)
      if not player:prohibitUse(card) and #tos > 0 then
        self.cost_data = {ids, tos}
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards_num = #self.cost_data[1]
    local tos_num = #self.cost_data[2]
    local promot = (player:getMark("@manwang") < 4 and tos_num >= cards_num) and "#panqin_delete-invoke" or "#panqin-invoke"
    if player.room:askForSkillInvoke(player, self.name, nil, promot) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data[1]
    local tos = self.cost_data[2]
    room:useVirtualCard("savage_assault", cards, player, tos, self.name)
    if #tos >= #cards then
      doManwang(player, 4 - player:getMark("@manwang"))
      if player:getMark("@manwang") < 4 then
        room:addPlayerMark(player, "@manwang")
      end
    end
  end,
}
menghuo:addSkill(manwang)
menghuo:addRelatedSkill(panqin)
Fk:loadTranslationTable{
  ["sp__menghuo"] = "孟获",
  ["manwang"] = "蛮王",
  [":manwang"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。",
  ["panqin"] = "叛侵",
  [":panqin"] = "出牌阶段结束时，或弃牌阶段结束时，你可以将本阶段你因弃置进入弃牌堆且仍在弃牌堆的牌当【南蛮入侵】使用，然后若此牌目标数不小于这些牌的数量，你执行并移除〖蛮王〗的最后一项。",
  ["@manwang"] = "蛮王",
  ["#panqin-invoke"] = "叛侵：你可将弃牌堆中你弃置的牌当【南蛮入侵】使用",
  ["#panqin_delete-invoke"] = "叛侵：你可将弃牌堆中你弃置的牌当【南蛮入侵】使用，然后执行并移除〖蛮王〗的最后一项",

  ["$manwang1"] = "不服王命，纵兵凶战危，也应以血相偿！",
  ["$manwang2"] = "夷汉所服，据南中诸郡，当以蛮王为号！",
  ["$panqin1"] = "百兽嘶鸣筋骨振，蛮王起兮万人随！",
  ["$panqin2"] = "呼勒格诗惹之民，召南中群雄复起！",
  ["~sp__menghuo"] = "有材而得生，无材而得纵……",
}

local ruiji = General(extension, "ruiji", "wu", 3, 3, General.Female)
local qiaoli = fk.CreateViewAsSkill{
  name = "qiaoli",
  anim_type = "offensive",
  interaction = function(self)
    local choices = {}
    if Self:getMark("qiaoli1-phase") == 0 then
      table.insert(choices, "qiaoli1-phase")
    end
    if Self:getMark("qiaoli2-phase") == 0 then
      table.insert(choices, "qiaoli2-phase")
    end
    return UI.ComboBox { choices = choices }
  end,
  prompt = function (self, selected, selected_cards)
    if self.interaction.data == "qiaoli1-phase" then
      return "#qiaoli1"
    elseif self.interaction.data == "qiaoli2-phase" then
      return "#qiaoli2"
    end
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "qiaoli1-phase" then
        return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon
      elseif self.interaction.data == "qiaoli2-phase" then
        return Fk:getCardById(to_select).type == Card.TypeEquip and Fk:getCardById(to_select).sub_type ~= Card.SubtypeWeapon
      end
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "qiaoli1-phase" then
      use.extra_data = use.extra_data or {}
      use.extra_data.qiaoli = {player.id, use.tos[1][1], Fk:getCardById(use.card.subcards[1]).attack_range}
    elseif self.interaction.data == "qiaoli2-phase" then
      room:addPlayerMark(player, "qiaoli2-turn")
      use.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("qiaoli1-phase") == 0 or player:getMark("qiaoli2-phase") == 0
  end,
}
local qiaoli_trigger = fk.CreateTriggerSkill{
  name = "#qiaoli_trigger",
  mute = true,
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead then
      if event == fk.Damage then
        if data.card and table.contains(data.card.skillNames, "qiaoli") then
          local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
          if e then
            local use = e.data[1]
            return use and use.extra_data and use.extra_data.qiaoli and use.extra_data.qiaoli[1] == player.id and
            use.extra_data.qiaoli[2] == data.to.id
          end
        end
      else
        return player.phase == Player.Finish and player:getMark("qiaoli2-turn") > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("qiaoli")
    room:notifySkillInvoked(player, "qiaoli", "drawcard")
    if event == fk.Damage then
      local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        local cards = player:drawCards(use.extra_data.qiaoli[3], "qiaoli")
        for _, id in ipairs(cards) do
          if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
            room:setCardMark(Fk:getCardById(id), "qiaoli", 1)
          end
        end
        while table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("qiaoli") > 0 end) do
          if not room:askForUseActiveSkill(player, "qiaoli_active", "#qiaoli-give", true) then
            for _, id in ipairs(player:getCardIds("h")) do
              room:setCardMark(Fk:getCardById(id), "qiaoli", 0)
            end
          end
        end
      end
    else
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|equip", player:getMark("qiaoli2-turn"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = "qiaoli",
        })
      end
    end
  end,
}
local qiaoli_active = fk.CreateActiveSkill{
  name = "qiaoli_active",
  mute = true,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Fk:getCardById(to_select):getMark("qiaoli") > 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    for _, id in ipairs(effect.cards) do
      room:setCardMark(Fk:getCardById(id), "qiaoli", 0)
    end
    if effect.tos[1] ~= effect.from then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(effect.cards)
      room:obtainCard(target, dummy, false, fk.ReasonGive)
    end
  end,
}
local qingliang = fk.CreateTriggerSkill{
  name = "qingliang",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      U.isOnlyTarget(player, data, fk.TargetConfirming) and not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qingliang-invoke::"..data.from..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    local suits = {"Cancel"}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id):getSuitString())
    end
    local choice = room:askForChoice(player, suits, self.name, "#qingliang-choice")
    if choice == "Cancel" then
      player:drawCards(1, self.name)
      if not room:getPlayerById(data.from).dead then
        room:getPlayerById(data.from):drawCards(1, self.name)
      end
    else
      local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getSuitString() == choice end)
      room:throwCard(cards, self.name, player, player)
      AimGroup:cancelTarget(data, player.id)
    end
  end,
}
qiaoli:addRelatedSkill(qiaoli_trigger)
Fk:addSkill(qiaoli_active)
ruiji:addSkill(qiaoli)
ruiji:addSkill(qingliang)
Fk:loadTranslationTable{
  ["ruiji"] = "芮姬",
  ["qiaoli"] = "巧力",
  [":qiaoli"] = "出牌阶段各限一次，1.你可以将一张武器牌当【决斗】使用，此牌对目标角色造成伤害后，你摸与之攻击范围等量张牌，然后可以分配其中任意张牌；"..
  "2.你可以将一张非武器装备牌当【决斗】使用且不能被响应，然后于结束阶段随机获得一张装备牌。",
  ["qingliang"] = "清靓",
  [":qingliang"] = "每回合限一次，当你成为其他角色使用的【杀】或伤害锦囊牌的唯一目标时，你可以展示所有手牌并选择一项："..
  "1.你与其各摸一张牌；2.弃置一种花色的所有手牌，取消此目标。",
  ["#qiaoli1"] = "巧力：将武器牌当【决斗】使用，造成伤害后摸此牌攻击范围张牌",
  ["#qiaoli2"] = "巧力：将非武器装备牌当【决斗】使用，不能被响应且结束阶段摸一张装备牌",
  ["qiaoli1-phase"] = "武器牌",
  ["qiaoli2-phase"] = "非武器装备牌",
  ["#qiaoli-give"] = "巧力：将这些牌分配给任意角色，点“取消”自己保留",
  ["qiaoli_active"] = "巧力",
  ["#qingliang-invoke"] = "清靓：%dest 对你使用%arg，是否发动“清靓”展示所有手牌？",
  ["#qingliang-choice"] = "清靓：弃置一种花色所有手牌并取消此牌，或点“取消”双方各摸一张牌",

  ["$qiaoli1"] = "别跑，且吃我一斧！",
	["$qiaoli2"] = "让我看看你的能耐。",
  ["$qingliang1"] = "挥斧摇清风，笑颜比朝霞。",
  ["$qingliang2"] = "素手抚重斧，飞矢擦靓装。",
  ["~ruiji"] = "这斧头，怎么变这么重了……",
}

local weizi = General(extension, "weizi", "qun", 3)
local yuanzi = fk.CreateTriggerSkill{
  name = "yuanzi",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return target.phase == Player.Start and player ~= target and not player:isKongcheng() and not target.dead and
        player:usedSkillTimes(self.name, Player.HistoryRound) == 0
    else
      return player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and target and target.phase ~= Player.NotActive and
      target:getHandcardNum() >= player:getHandcardNum()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if event == fk.EventPhaseStart then
      prompt = "#yuanzi-give::"..target.id
    else
      prompt = "#yuanzi-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:doIndicate(player.id, {target.id})
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player.player_cards[Player.Hand])
      room:obtainCard(target, dummy, false, fk.ReasonGive)
    else
      room:drawCards(player, 2, self.name)
    end
  end,
}
local liejie = fk.CreateTriggerSkill{
  name = "liejie",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#liejie-invoke"
    if data.from and not data.from.dead then
      prompt = "#liejie-cost::"..data.from.id
    end
    local cards = player.room:askForDiscard(player, 1, 3, true, self.name, true, ".", prompt, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    local n = 0
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).color == Card.Red then
        n = n + 1
      end
    end
    room:throwCard(cards, self.name, player, player)
    if player.dead then return false end
    room:drawCards(player, #cards, self.name)
    if not player.dead and data.from and not data.from.dead and not data.from:isNude() and n > 0 and
    room:askForSkillInvoke(player, self.name, data, "#liejie-discard::"..data.from.id..":"..n) then
      local discard = room:askForCardsChosen(player, data.from, 1, n, "he", self.name)
      room:throwCard(discard, self.name, data.from, player)
    end
  end,
}
weizi:addSkill(yuanzi)
weizi:addSkill(liejie)
Fk:loadTranslationTable{
  ["weizi"] = "卫兹",
  ["yuanzi"] = "援资",
  [":yuanzi"] = "每轮限一次，其他角色的准备阶段，你可以交给其所有手牌。若如此做，当其本回合造成伤害后，若其手牌数不小于你，你可以摸两张牌。",
  ["liejie"] = "烈节",
  [":liejie"] = "当你受到伤害后，你可以弃置至多三张牌并摸等量张牌，然后你可以弃置伤害来源至多X张牌（X为你以此法弃置的红色牌数）。",
  ["#yuanzi-give"] = "援资：你可以将所有手牌交给 %dest，其本回合造成伤害后你可以摸两张牌",
  ["#yuanzi-invoke"] = "援资：你可以摸两张牌",
  ["#liejie-cost"] = "烈节：弃置至多三张牌并摸等量牌，然后可以弃置 %dest 你弃置红色牌数的牌",
  ["#liejie-invoke"] = "烈节：弃置至多三张牌并摸等量牌",
  ["#liejie-discard"] = "烈节：你可以弃置 %dest 至多%arg张牌",

  ["$yuanzi1"] = "不过是些身外之物罢了。",
  ["$yuanzi2"] = "兹之家资，将军可尽取之。",
  ["$liejie1"] = "头可断，然节不可夺。",
  ["$liejie2"] = "血可流，而志不可改。",
  ["~weizi"] = "敌军势众，速退！",
}

local guohuai = General(extension, "guohuaij", "jin", 3, 3, General.Female)
local zhefu = fk.CreateTriggerSkill{
  name = "zhefu",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local targets = {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if not p:isKongcheng() then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#zhefu-choose:::"..data.card.trueName, self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForDiscard(to, 1, 1, false, self.name, true, data.card.trueName, "#zhefu-discard::"..player.id..":"..data.card.trueName)
    if #card == 0 then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local yidu = fk.CreateTriggerSkill{
  name = "yidu",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id) return
      (not data.damageDealt or (data.damageDealt and not data.damageDealt[id])) and not room:getPlayerById(id):isKongcheng() end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#yidu-invoke", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = room:askForCardsChosen(player, to, 1, math.min(3, #to.player_cards[Player.Hand]), "h", self.name)
    to:showCards(cards)
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).color ~= Fk:getCardById(cards[1]).color then
        return
      end
    end
    room:throwCard(cards, self.name, to, player)
  end,
}
guohuai:addSkill(zhefu)
guohuai:addSkill(yidu)
Fk:loadTranslationTable{
  ["guohuaij"] = "郭槐",
  ["zhefu"] = "哲妇",
  [":zhefu"] = "当你于回合外使用或打出一张牌后，你可以令一名有手牌的其他角色选择弃置一张同名牌或受到你的1点伤害。",
  ["yidu"] = "遗毒",
  [":yidu"] = "当你使用【杀】或伤害锦囊牌后，若有目标角色未受到此牌的伤害，你可以展示其至多三张手牌，若颜色均相同，你弃置这些牌。",
  ["#zhefu-choose"] = "哲妇：你可以指定一名角色，其弃置一张【%arg】或受到你的1点伤害",
  ["#zhefu-discard"] = "哲妇：你需弃置一张【%arg】，否则 %dest 对你造成1点伤害",
  ["#yidu-invoke"] = "遗毒：你可以选择一名角色，展示至多三张手牌，若颜色相同则全部弃置",

  ["$zhefu1"] = "非我善妒，实乃汝之过也！",
  ["$zhefu2"] = "履行不端者，当有此罚。",
  ["$yidu1"] = "彼之砒霜，吾之蜜糖。",
  ["$yidu2"] = "巧动心思，以遗他人。",
  ["~guohuaij"] = "我死后，切勿从粲、午之言。",
}

local zhaoyan = General(extension, "ol__zhaoyan", "wei", 4)
local tongxie = fk.CreateTriggerSkill{
  name = "tongxie",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 2, "#tongxie-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      table.insert(self.cost_data, player.id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "tongxie_src", self.cost_data)
    local nums = {}
    local targets = table.map(self.cost_data, function (id) return room:getPlayerById(id) end)
    for _, p in ipairs(targets) do
      local mark = p:getMark("@@tongxie")
      if mark == 0 then mark = {} end
      table.insertTable(mark, self.cost_data)
      room:setPlayerMark(p, "@@tongxie", mark)
      table.insert(nums, p:getHandcardNum())
    end
    local n = math.min(table.unpack(nums))
    if #table.filter(nums, function(i) return i == n end) > 1 then return end
    for _, p in ipairs(targets) do
      if p:getHandcardNum() == n then
        p:drawCards(1, self.name)
        break
      end
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseChanging then
        return player:getMark("tongxie_src") ~= 0 and data.from == Player.RoundStart
      else
        return player:getMark("@@tongxie") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      local tos = player:getMark("tongxie_src")
      room:setPlayerMark(player, "tongxie_src", 0)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          local mark = p:getMark("@@tongxie")
          if mark == 0 then return end
          for _, i in ipairs(tos) do
            table.removeOne(mark, i)
          end
          if #mark < 2 then mark = 0 end
          room:setPlayerMark(p, "@@tongxie", mark)
        end
      end
    else
      if player:getMark("tongxie_src") ~= 0 then
        local tos = player:getMark("tongxie_src")
        for _, id in ipairs(tos) do
          local p = room:getPlayerById(id)
          if not p.dead then
            local mark = p:getMark("@@tongxie")
            for _, i in ipairs(tos) do
              table.removeOne(mark, i)
            end
            if #mark < 2 then mark = 0 end
            room:setPlayerMark(p, "@@tongxie", mark)
          end
        end
      else
        local tos = player:getMark("@@tongxie")
        for _, id in ipairs(tos) do
          local p = room:getPlayerById(id)
          if not p.dead then
            local mark = p:getMark("@@tongxie")
            table.removeOne(mark, player.id)
            if #mark < 2 then mark = 0 end
            room:setPlayerMark(p, "@@tongxie", mark)
          end
        end
      end
    end
  end,
}
local tongxie_trigger = fk.CreateTriggerSkill{
  name = "#tongxie_trigger",
  mute = true,
  events = {fk.CardUseFinished, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@@tongxie") ~= 0 and target ~= player and table.contains(player:getMark("@@tongxie"), target.id) then
      if event == fk.CardUseFinished then
        return data.card.trueName == "slash" and #data.tos == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id and
          not player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1]).dead and not(data.extra_data and data.extra_data.tongxie)
      else
        return player:getMark("tongxie_lose-turn") == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local to = TargetGroup:getRealTargets(data.tos)[1]
      local use = room:askForUseCard(player, "slash", "slash", "#tongxie-slash::"..to, true,
        {must_targets = {to}, bypass_distances = true, bypass_times = true})
      if use then
        player:broadcastSkillInvoke("tongxie")
        room:notifySkillInvoked(player, "tongxie", "offensive")
        use.extra_data = use.extra_data or {}
        use.extra_data.tongxie = true
        room:useCard(use)
      end
    else
      if room:askForSkillInvoke(player, "tongxie", nil, "#tongxie-loseHp::"..target.id) then
        player:broadcastSkillInvoke("tongxie")
        room:notifySkillInvoked(player, "tongxie", "support")
        room:loseHp(player, 1, "tongxie")
        return true
      end
    end
  end,

  refresh_events = {fk.HpLost},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "tongxie_lose-turn", 1)
  end,
}
tongxie:addRelatedSkill(tongxie_trigger)
zhaoyan:addSkill(tongxie)
Fk:loadTranslationTable{
  ["ol__zhaoyan"] = "赵俨",
  ["tongxie"] = "同协",
  [":tongxie"] = "出牌阶段开始时，你可以令你与至多两名其他角色直到你的下回合开始成为“同协”角色，然后令其中手牌唯一最少的角色摸一张牌。<br>"..
  "当同协角色不以此法使用的仅指定唯一目标的【杀】结算后，其他同协角色可以依次对目标使用一张无距离限制的【杀】。<br>"..
  "当同协角色受到伤害时，本回合未失去过体力的其他同协角色可以防止此伤害并失去1点体力。",
  ["#tongxie-choose"] = "同协：选择至多两名其他角色与你成为“同协”角色",
  ["@@tongxie"] = "同协",
  ["#tongxie-slash"] = "同协：你可以对 %dest 使用一张【杀】（无距离限制）",
  ["#tongxie-loseHp"] = "同协：%dest 受到伤害，你可以失去1点体力防止之",

  ["$tongxie1"] = "分则必败，合则可胜！",
  ["$tongxie2"] = "唯同心协力，方可破敌。",
  ["~ol__zhaoyan"] = "援军不至，樊城之围难解……",
}

local zhouchu = General(extension, "ol__zhouchu", "jin", 4)
local shanduan = fk.CreateTriggerSkill{
  name = "shanduan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase > 3 and player.phase < 7
      else
        return player.phase == Player.NotActive
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = player:getMark(self.name)
    if event == fk.Damaged then
      if nums == 0 or #nums < 4 then
        nums = {2, 2, 3, 4}
      else
        local min = math.min(table.unpack(nums))
        for i = 1, 4, 1 do
          if nums[i] == min then
            nums[i] = min + 1
            table.sort(nums)
            break
          end
        end
      end
      room:setPlayerMark(player, self.name, nums)
    else
      local choices = table.map(nums, function (i) return tostring(i) end)
      if #choices == 0 then return end
      local choice = room:askForChoice(player, choices, self.name, "#shanduan"..(player.phase - 3).."-choice")
      room:setPlayerMark(player, "shanduan"..(player.phase - 3).."-turn", tonumber(choice))
      table.removeOne(nums, tonumber(choice))
      table.sort(nums)
      room:setPlayerMark(player, self.name, nums)
      if player.phase == Player.Play then
        choice = room:askForChoice(player, table.map(nums, function (i) return tostring(i) end), self.name, "#shanduan4-choice")
        room:setPlayerMark(player, "shanduan4-turn", tonumber(choice))
        table.removeOne(nums, tonumber(choice))
        table.sort(nums)
        room:setPlayerMark(player, self.name, nums)
      end
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.DrawNCards},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseChanging then
        return data.from == Player.RoundStart
      else
        return player:getMark("shanduan1-turn") > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      local nums = player:getMark(self.name)
      if nums == 0 or #nums < 4 then
        player.room:setPlayerMark(player, self.name, {1, 2, 3, 4})
      end
    else
      data.n = data.n + player:getMark("shanduan1-turn") - 2
    end
  end,
}
local shanduan_attackrange = fk.CreateAttackRangeSkill{
  name = "#shanduan_attackrange",
  correct_func = function(self, from, to)
    if from:getMark("shanduan2-turn") > 0 then
      return from:getMark("shanduan2-turn") - 1
    end
    return 0
  end,
}
local shanduan_targetmod = fk.CreateTargetModSkill{
  name = "#shanduan_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("shanduan4-turn") > 0 and scope == Player.HistoryPhase then
      return player:getMark("shanduan4-turn") - 1
    end
    return 0
  end,
}
local shanduan_maxcards = fk.CreateMaxCardsSkill{
  name = "#shanduan_maxcards",
  fixed_func = function(self, player)
    if player:getMark("shanduan3-turn") > 0 then
      return player:getMark("shanduan3-turn")
    end
  end,
}
local yilie = fk.CreateViewAsSkill{
  name = "yilie",
  pattern = "^nullification|.|.|.|.|basic|.",
  interaction = function()
    local names = {}
    local mark = Self:getMark("yilie-round")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and
        ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return Fk:getCardById(to_select).color == Fk:getCardById(selected[1]).color
      else
        return false
      end
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 2 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcards(cards)
    return card
  end,
  before_use = function(self, player)
    local mark = player:getMark("yilie-round")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    player.room:setPlayerMark(player, "yilie-round", mark)
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
shanduan:addRelatedSkill(shanduan_attackrange)
shanduan:addRelatedSkill(shanduan_targetmod)
shanduan:addRelatedSkill(shanduan_maxcards)
zhouchu:addSkill(shanduan)
zhouchu:addSkill(yilie)
Fk:loadTranslationTable{
  ["ol__zhouchu"] = "周处",
  ["shanduan"] = "善断",
  [":shanduan"] = "锁定技，你的阶段开始时，将数值1、2、3、4分配给以下项：<br>"..
  "摸牌阶段开始时，你选择本回合摸牌阶段摸牌数；<br>出牌阶段开始时，你选择本回合攻击范围、出牌阶段使用【杀】次数上限；<br>"..
  "弃牌阶段开始时，你选择本回合手牌上限。<br>当你于回合外受到伤害后，你下回合分配数值中的最小值+1。",
  ["yilie"] = "义烈",
  [":yilie"] = "你可以将两张颜色相同的手牌当一张本轮未以此法使用过的基本牌使用。",
  ["#shanduan1-choice"] = "善断：选择摸牌阶段摸牌数",
  ["#shanduan2-choice"] = "善断：选择攻击范围",
  ["#shanduan3-choice"] = "善断：选择手牌上限",
  ["#shanduan4-choice"] = "善断：选择使用【杀】次数上限",

  ["$shanduan1"] = "浪子回头，其期未晚矣！",
  ["$shanduan2"] = "心既存蛟虎，秉慧剑斩之！",
  ["$yilie1"] = "从来天下义，只在青山中！",
  ["$yilie2"] = "沥血染征袍，英名万古存！",
  ["~ol__zhouchu"] = "死战死谏，死亦可乎！",
}

local caoxiancaohua = General(extension, "caoxiancaohua", "qun", 3, 3, General.Female)
local huamu = fk.CreateTriggerSkill{
  name = "huamu",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    local room = player.room
    local card_ids = Card:getIdList(data.card)
    if #card_ids == 0 then return false end
    if data.card.type == Card.TypeEquip then
      if not table.every(card_ids, function (id)
        return room:getCardArea(id) == Card.PlayerEquip and room:getCardOwner(id) == player
      end) then return false end
    else
      if not table.every(card_ids, function (id)
        return room:getCardArea(id) == Card.Processing
      end) then return false end
    end
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local move_events = use_event:searchEvents(GameEvent.MoveCards, 1, function()
      return true
    end)
    if #move_events == 0 then return false end
    local moves = move_events[1].data
    for _, move in ipairs(moves) do
      if move.from ~= player.id then return false end
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea ~= Card.PlayerHand then return false end
      end
    end
    local turn_event = use_event:findParent(GameEvent.Turn, false)
    if not turn_event then return false end
    local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local last_find = false
    for i = #events, 1, -1 do
      local e = events[i]
      if e.id < turn_event.id then break end
      if e.id == use_event.id then
        last_find = true
      elseif last_find then
        local last_use = e.data[1]
        return not data.card:compareColorWith(last_use.card)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = Card:getIdList(data.card)
    local move_from = nil
    if data.card.type == Card.TypeEquip then
      move_from = player.id
      if not table.every(card_ids, function (id)
        return room:getCardArea(id) == Card.PlayerEquip and room:getCardOwner(id) == player
      end) then return false end
    else
      if not table.every(card_ids, function (id)
        return room:getCardArea(id) == Card.Processing
      end) then return false end
    end
    local reds, blacks = {}, {}
    for _, id in ipairs(card_ids) do
      local color = Fk:getCardById(id).color
      if color == Card.Red then
        table.insert(reds, id)
      elseif color == Card.Black then
        table.insert(blacks, id)
      end
    end
    local moveInfos = {}
    local audio_case = 3
    if #reds > 0 then
      table.insert(moveInfos, {
        ids = reds,
        from = move_from,
        to = player.id,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        specialName = "huamu_YuShu",
        moveVisible = true,
        proposer = player.id,
      })
      audio_case = audio_case - 2
    end
    if #blacks > 0 then
      table.insert(moveInfos, {
        ids = blacks,
        from = move_from,
        to = player.id,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        specialName = "huamu_LingShan",
        moveVisible = true,
        proposer = player.id,
      })
      audio_case = audio_case - 1
    end
    if #moveInfos > 0 then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name, audio_case * 2 + math.random(2))
      room:moveCards(table.unpack(moveInfos))
    end
  end,
}
local qianmeng = fk.CreateTriggerSkill{
  name = "qianmeng",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local piles = {"huamu_LingShan", "huamu_YuShu"}
      local QianmengCheck = function(pid)
        if not pid then return false end
        local move_player = player.room:getPlayerById(pid)
        local x = #move_player:getPile(piles[1])
        local y = #move_player:getPile(piles[2])
        return x == 0 or y == 0 or x == y
      end
      for _, move in ipairs(data) do
        if QianmengCheck(move.to) and move.toArea == Card.PlayerSpecial and table.contains(piles, move.specialName) then
          return true
        end
        if QianmengCheck(move.from) then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(piles, info.fromSpecialName) then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = {}
    local piles = {"huamu_LingShan", "huamu_YuShu"}
    local QianmengCheck = function(pid)
      if not pid or table.contains(targets, pid) then return false end
      local move_player = player.room:getPlayerById(pid)
      local x = #move_player:getPile(piles[1])
      local y = #move_player:getPile(piles[2])
      return x == 0 or y == 0 or x == y
    end
    for _, move in ipairs(data) do
      if QianmengCheck(move.to) and move.toArea == Card.PlayerSpecial and table.contains(piles, move.specialName) then
        table.insert(targets, move.to)
      end
      if QianmengCheck(move.from) then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(piles, info.fromSpecialName) then
            table.insert(targets, move.from)
            break
          end
        end
      end
    end
    for _ = 1, #targets, 1 do
      if not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local liangyuan = fk.CreateViewAsSkill{
  name = "liangyuan",
  pattern = "peach,analeptic",
  interaction = function()
    local all_names, piles, names = {"peach", "analeptic"}, {"huamu_YuShu", "huamu_LingShan"}, {}
    local mark = Self:getMark("liangyuan_record-round")
    for i = 1, 2, 1 do
      local name = all_names[i]
      if type(mark) ~= "table" or not table.contains(mark, name) then
        if not table.every(Fk:currentRoom().alive_players, function (p)
          return #p:getPile(piles[i]) == 0
        end) then
        local to_use = Fk:cloneCard(name)
          if ((Fk.currentResponsePattern == nil and Self:canUse(to_use) and not Self:prohibitUse(to_use)) or
              (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
            table.insertIfNeed(names, name)
          end
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local card_ids = {}
    local pile_name = "huamu_LingShan"
    if self.interaction.data == "peach" then
      pile_name = "huamu_YuShu"
    end
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertTable(card_ids, p:getPile(pile_name))
    end
    if #card_ids == 0 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcards(card_ids)
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("liangyuan_record-round")
    if type(mark) ~= "table" then
      mark = {}
    end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "liangyuan_record-round", mark)
  end,
  enabled_at_play = function(self, player)
    local names, piles = {"peach", "analeptic"}, {"huamu_YuShu", "huamu_LingShan"}
    local mark = player:getMark("liangyuan_record-round")
    for i = 1, 2, 1 do
      local name = names[i]
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local card_ids = {}
        local pile_name = piles[i]
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(card_ids, p:getPile(pile_name))
        end
        if #card_ids > 0 then
          local to_use = Fk:cloneCard(name)
          to_use:addSubcards(card_ids)
          if player:canUse(to_use) and not player:prohibitUse(to_use) then
            return true
          end
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local names, piles = {"peach", "analeptic"}, {"huamu_YuShu", "huamu_LingShan"}
    local mark = player:getMark("liangyuan_record-round")
    for i = 1, 2, 1 do
      local name = names[i]
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local card_ids = {}
        local pile_name = piles[i]
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(card_ids, p:getPile(pile_name))
        end
        if #card_ids > 0 then
          local to_use = Fk:cloneCard(name)
          to_use:addSubcards(card_ids)
          if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use) and
              not player:prohibitUse(to_use) then
            return true
          end
        end
      end
    end
  end,
}
local jisi = fk.CreateTriggerSkill{
  name = "jisi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start and
        player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      local all_skills = Fk.generals[player.general]:getSkillNameList()
      if table.contains(all_skills, self.name) then
        for _, skill_name in ipairs(all_skills) do
          if player:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
            return true
          end
        end
      end
      if player.deputyGeneral and player.deputyGeneral ~= "" then
        local all_deputy_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
        if table.contains(all_deputy_skills, self.name) then
          for _, skill_name in ipairs(all_deputy_skills) do
            if player:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "jisi_active", "#jisi-choose", true)
    if success then
      self.cost_data = {dat.targets[1], Fk.skills["jisi_active"].interaction.data}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data[1])
    room:handleAddLoseSkills(tar, self.cost_data[2], nil)
    player:throwAllCards("h")
    if not player.dead and not tar.dead then
      room:useVirtualCard("slash", nil, player, tar, self.name, true)
    end
  end,
}
local jisi_active = fk.CreateActiveSkill{
  name = "jisi_active",
  interaction = function(self)
    local skills = {}
    local all_skills = Fk.generals[Self.general]:getSkillNameList()
    if table.contains(all_skills, jisi.name) then
      for _, skill_name in ipairs(all_skills) do
        if Self:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
          table.insertIfNeed(skills, skill_name)
        end
      end
    end
    if Self.deputyGeneral and Self.deputyGeneral ~= "" then
      local all_deputy_skills = Fk.generals[Self.deputyGeneral]:getSkillNameList()
      if table.contains(all_deputy_skills, jisi.name) then
        for _, skill_name in ipairs(all_deputy_skills) do
          if Self:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
            table.insertIfNeed(skills, skill_name)
          end
        end
      end
    end
    return UI.ComboBox { choices = skills }
  end,
  max_card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return self.interaction.data ~= nil and #selected == 0 and to_select ~= Self.id
  end,
}
Fk:addSkill(jisi_active)
caoxiancaohua:addSkill(huamu)
caoxiancaohua:addSkill(qianmeng)
caoxiancaohua:addSkill(liangyuan)
caoxiancaohua:addSkill(jisi)

Fk:loadTranslationTable{
  ["caoxiancaohua"] = "曹宪曹华",
  ["huamu"] = "化木",
  [":huamu"] = "当你使用与本回合上一张使用的牌颜色不同的手牌后，你可以将之置于你的武将牌上，黑色牌称为「灵杉」，红色牌称为「玉树」。",
  ["qianmeng"] = "前盟",
  [":qianmeng"] = "锁定技，当一名角色的「灵杉」「玉树」数量变化后，若两者相等或一项为0，你摸一张牌。",
  ["liangyuan"] = "良缘",
  [":liangyuan"] = "每轮各限一次，你可以将全场所有「灵杉」当【酒】、「玉树」当【桃】使用。",
  ["jisi"] = "羁肆",
  ["jisi_active"] = "羁肆",
  [":jisi"] = "限定技，准备阶段，你可以令一名角色获得此武将牌上发动过的一个技能，然后你弃置所有手牌并视为对其使用一张【杀】。",

  ["huamu_LingShan"] = "灵杉",
  ["huamu_YuShu"] = "玉树",
  ["#liangyuan-active"] = "发动良缘，将全场所有「灵杉」当【酒】、「玉树」当【桃】来使用",
  ["#jisi-choose"] = "你可以发动羁肆，令一名角色获得一个技能，然后你弃置所有手牌并视为对其使用【杀】",

  ["$huamu1"] = "左杉右树，可共余生。",
  ["$huamu2"] = "夫君，当与妾共越此人间之阶！",
  ["$huamu3"] = "四月寻春花更香。",
  ["$huamu4"] = "一树樱桃带雨红。",
  ["$huamu5"] = "山重水复，心有灵犀。",
  ["$huamu6"] = "灵之来兮如云。",
  ["$qianmeng1"] = "前盟已断，杉树长别。",
  ["$qianmeng2"] = "苍山有灵，杉树相依。",
  ["$liangyuan1"] = "千古奇遇，共剪西窗。",
  ["$liangyuan2"] = "金玉良缘，来日方长。",
  ["$jisi1"] = "被褐怀玉，天放不羁。",
  ["$jisi2"] = "心若野马，不系璇台。",
  ["~caoxiancaohua"] = "爱恨有泪，聚散无常……",
}

local huojun = General(extension, "ol__huojun", "shu", 4)
local qiongshou = fk.CreateTriggerSkill{
  name = "qiongshou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local subtype = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide, Card.SubtypeTreasure}
    local slots = {}
    for _, type in ipairs(subtype) do
      for i = 1, #player:getAvailableEquipSlots(type), 1 do
        table.insert(slots, Util.convertSubtypeAndEquipSlot(type))
      end
    end
    room:abortPlayerArea(player, slots)
    player:drawCards(4, self.name)
  end,
}
local qiongshou_maxcards = fk.CreateMaxCardsSkill{
  name = "#qiongshou_maxcards",
  frequency = Skill.Compulsory,
  correct_func = function(self, player)
    if player:hasSkill("qiongshou") then
      return 4
    else
      return 0
    end
  end,
}
local fenrui = fk.CreateTriggerSkill{
  name = "fenrui",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isNude() then
      return table.find({Player.WeaponSlot, Player.ArmorSlot, Player.OffensiveRideSlot, Player.DefensiveRideSlot, Player.TreasureSlot},
        function(slot) return table.contains(player.sealedSlots, slot) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#fenrui-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local slots = {Player.WeaponSlot, Player.ArmorSlot, Player.OffensiveRideSlot, Player.DefensiveRideSlot, Player.TreasureSlot}
    local subtype = {"weapon", "armor", "offensive_horse", "defensive_horse", "treasure"}
    for _, slot in ipairs(player.sealedSlots) do
      if slot ~= Player.JudgeSlot then
        table.insert(choices, subtype[table.indexOf(slots, slot)])
      end
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(player, choices, self.name, "#fenrui-choice")
    room:resumePlayerArea(player, slots[table.indexOf(subtype, choice)])
    room:throwCard(self.cost_data, self.name, player, player)  --FIXME: 最好应该是用interaction来选
    if player.dead then return end
    if choice == "offensive_horse" then
      choice = "offensive_ride"
    elseif choice == "defensive_horse" then
      choice = "defensive_ride"
    end
    local id = room:getCardsFromPileByRule(".|.|.|.|.|"..choice, 1, "allPiles")[1]
    if id then
      room:useCard({
        from = player.id,
        tos = {{player.id}},
        card = Fk:getCardById(id),
      })
    end
    if not player.dead and player:getMark("@@fenrui") == 0 then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return #p:getCardIds("e") < #player:getCardIds("e") end), Util.IdMapper)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#fenrui-choose", self.name, true)
      if #to > 0 then
        room:setPlayerMark(player, "@@fenrui", 1)
        to = room:getPlayerById(to[1])
        room:damage{
          from = player,
          to = to,
          damage = #player:getCardIds("e") - #to:getCardIds("e"),
          skillName = self.name,
        }
      end
    end
  end,
}
qiongshou:addRelatedSkill(qiongshou_maxcards)
huojun:addSkill(qiongshou)
huojun:addSkill(fenrui)
Fk:loadTranslationTable{
  ["ol__huojun"] = "霍峻",
  ["qiongshou"] = "穷守",
  [":qiongshou"] = "锁定技，游戏开始时，你废除所有装备栏并摸四张牌。你的手牌上限+4。",
  ["fenrui"] = "奋锐",
  [":fenrui"] = "结束阶段，你可以弃置一张牌并复原一个装备栏，随机使用一张对应的装备牌，然后每局游戏限一次，你可以对一名装备区牌数小于"..
  "你的角色造成X点伤害（X为你与其装备区牌数之差）。",
  ["#fenrui-invoke"] = "奋锐：你可以弃置一张牌恢复一个装备栏，随机使用一张对应的装备牌",
  ["#fenrui-choice"] = "奋锐：选择你要恢复的栏位",
  ["@@fenrui"] = "奋锐",
  ["#fenrui-choose"] = "奋锐：你可以对一名装备少于你的角色造成你与其装备数之差的伤害！（每局限一次）",
  
  ["$qiongshou1"] = "戍守孤城，其势不侵。",
  ["$qiongshou2"] = "吾头可得，而城不可得。",
  ["$fenrui1"] = "待其疲敝，则可一击破之。",
  ["$fenrui2"] = "覆军斩将，便在旦夕之间。",
  ["~ol__huojun"] = "主公，峻有负所托！",
}

local dengzhong = General(extension, "dengzhong", "wei", 4)
local kanpod = fk.CreateViewAsSkill{
  name = "kanpod",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
}
local kanpod_prey = fk.CreateTriggerSkill{
  name = "#kanpod_prey",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and not data.chain and
      not data.to.dead and not data.to:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#kanpod-invoke::"..data.to.id..":"..data.card:getSuitString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = data.to.player_cards[Player.Hand]
    local hearts = table.filter(cards, function (id) return Fk:getCardById(id).suit == data.card.suit end)
    room:fillAG(player, cards)
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).suit ~= data.card.suit then
          room:takeAG(player, cards[i], {player})
      end
    end
    if #hearts == 0 then
      room:delay(3000)
      room:closeAG(player)
      return
    end
    local id = room:askForAG(player, hearts, true, self.name)
    room:closeAG(player)
    if id then
      room:obtainCard(player.id, id, true, fk.ReasonPrey)
    end
  end,
}
local gengzhan = fk.CreateTriggerSkill{
  name = "gengzhan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.room.current ~= player and player.room.current.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      self.cost_data = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "slash" then
              table.insert(self.cost_data, info.cardId)
            end
          end
        end
      end
      return #self.cost_data > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    if #cards == 1 then
      room:obtainCard(player.id, cards[1], true, fk.ReasonJustMove)
    else
      room:fillAG(player, cards)
      local id = room:askForAG(player, cards, false, self.name)
      if id == nil then
        id = table.random(cards)
      end
      room:closeAG(player)
      room:obtainCard(player.id, id, true, fk.ReasonJustMove)
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if target == player then
        return player.phase == Player.Play and player:getMark(self.name) > 0
      else
        if target.phase == Player.Finish then
          for _, id in ipairs(Fk:getAllCardIds()) do
            if Fk:getCardById(id).trueName == "slash" and target:usedCardTimes(Fk:getCardById(id).name) > 0 then
              return
            end
          end
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      room:addPlayerMark(player, "@gengzhan-phase", player:getMark(self.name))
      room:setPlayerMark(player, self.name, 0)
    else
      room:addPlayerMark(player, self.name, 1)
    end
  end,
}
local gengzhan_targetmod = fk.CreateTargetModSkill{
  name = "#gengzhan_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self.name, true) and skill.trueName == "slash_skill" and player:getMark("@gengzhan-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@gengzhan-phase")
    end
  end,
}
kanpod:addRelatedSkill(kanpod_prey)
gengzhan:addRelatedSkill(gengzhan_targetmod)
dengzhong:addSkill(kanpod)
dengzhong:addSkill(gengzhan)
Fk:loadTranslationTable{
  ["dengzhong"] = "邓忠",
  ["kanpod"] = "勘破",
  [":kanpod"] = "当你使用【杀】对目标角色造成伤害后，你可以观看其手牌并获得其中一张与此【杀】花色相同的牌。每回合限一次，你可以将一张手牌当【杀】使用。",
  ["gengzhan"] = "更战",
  [":gengzhan"] = "其他角色出牌阶段限一次，当一张【杀】因弃置置入弃牌堆后，你可以获得之。其他角色的结束阶段，若其本回合未使用过【杀】，"..
  "你下个出牌阶段使用【杀】的限制次数+1。",
  ["#kanpod_prey"] = "勘破",
  ["#kanpod-invoke"] = "勘破：你可以观看 %dest 的手牌并获得其中一张%arg牌",
  ["@gengzhan-phase"] = "更战",

  ["$kanpod1"] = "兵锋相交，便可知其玄机。",
  ["$kanpod2"] = "先发一军，以探敌营虚实。",
  ["$gengzhan1"] = "将无常败，军可常胜。",
  ["$gengzhan2"] = "前进可活，后退即死。",
  ["~dengzhong"] = "杀身报国，死得其所。",
}

local xiahouxuan = General(extension, "xiahouxuan", "wei", 3)
local huanfu = fk.CreateTriggerSkill{
  name = "huanfu",
  anim_type = "drawcard",
  events ={fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, player.maxHp, true, self.name, true, ".", "#huanfu-invoke:::"..player.maxHp)
    if #cards > 0 then
      self.cost_data = #cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.huanfu = data.extra_data.huanfu or {}
    data.extra_data.huanfu[player.id] = self.cost_data
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.huanfu and data.extra_data.huanfu[player.id] and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    if data.damageDealt then
      local n = 0
      for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
        if data.damageDealt[id] then
          n = n + data.damageDealt[id]
        end
      end
      if n == data.extra_data.huanfu[player.id] then
        player:drawCards(2 * n, self.name)
      end
    end
  end,
}
local qingyix = fk.CreateActiveSkill{
  name = "qingyix",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < 2 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = {player}
    for _, id in ipairs(effect.tos) do
      table.insert(targets, room:getPlayerById(id))
    end
    local cards = {}
    while true do
      for _, p in ipairs(targets) do
        local id = room:askForCard(p, 1, 1, true, self.name, false, ".", "#qingyi-discard")
        if #id == 1 then
          id = id[1]
        else
          id = table.random(p:getCardIds("he"))
        end
        p.tag[self.name] = id
      end
      local ids = {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(cards, p.tag[self.name])  --小心落英、纵玄
        table.insertIfNeed(ids, p.tag[self.name])
        room:throwCard({p.tag[self.name]}, self.name, p, p)
        p.tag[self.name] = nil
      end
      if table.every(ids, function(id) return Fk:getCardById(id).type == Fk:getCardById(ids[1]).type end) and
        table.every(targets, function(p) return not p:isNude() end) and
        room:askForSkillInvoke(player, self.name, nil, "#qingyi-invoke") then
        --continue
      else
        break
      end
    end
    room:setPlayerMark(player, "qingyi-turn", cards)
  end,
}
local qingyix_record = fk.CreateTriggerSkill{
  name = "#qingyix_record",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:usedSkillTimes("qingyix") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getMark("qingyi-turn")
    for _, id in ipairs(cards) do
      if room:getCardArea(id) ~= Card.DiscardPile then
        table.removeOne(cards, id)
      end
    end
    if #cards == 0 then return end
    local get = {}
    room:fillAG(player, cards)
    while #cards > 0 do
      local id = room:askForAG(player, cards, false, self.name)
      if id ~= nil then
        for i = #cards, 1, -1 do
          if Fk:getCardById(cards[i]).color == Fk:getCardById(id).color then
            room:takeAG(player, cards[i], room.players)
            table.removeOne(cards, cards[i])
          end
        end
        table.insert(get, id)
      else
        id = table.random(cards)
      end
    end
    room:closeAG(player)
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
  end,
}
local zeyue = fk.CreateTriggerSkill{
  name = "zeyue",
  anim_type = "control",
  frequency = Skill.Limited,
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player.tag[self.name] and #player.tag[self.name] > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, id in ipairs(player.tag[self.name]) do
      local p = room:getPlayerById(id)
      if not p.dead and #p.player_skills > 0 then
        local skills = table.map(Fk.generals[p.general].skills, function(s) return s.name end)
        for _, skill in ipairs(skills) do
          if p:hasSkill(skill, true) and skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Wake and
            skill.frequency ~= Skill.Limited then
            table.insertIfNeed(targets, id)
            break
          end
        end
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zeyue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local skills = {}
    for _, skill in ipairs(to.player_skills) do
      if not skill.attached_equip and skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Wake and
        skill.frequency ~= Skill.Limited then
        table.insertIfNeed(skills, skill.name)
      end
    end
    local choice = room:askForChoice(player, skills, self.name, "#zeyue-choice::"..to.id, true)
    room:handleAddLoseSkills(to, "-"..choice, nil, true, false)
    room:setPlayerMark(to, self.name, choice)
    to.tag["zeyue_count"] = {0, player}
  end,

  refresh_events = {fk.Damaged, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, true) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      --这里本不应判断技能发动次数，但为了减少运算就不记录了
      if event == fk.Damaged then
        return data.from and data.from ~= player
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damaged then
      player.tag[self.name] = player.tag[self.name] or {}
      table.insertIfNeed(player.tag[self.name], data.from.id)
    else
      player.tag[self.name] = {}
    end
  end,
}
local zeyue_record = fk.CreateTriggerSkill{
  name = "#zeyue_record",
  anim_type = "special",
  events ={fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    return player.tag["zeyue_count"] and not player.dead and not player.tag["zeyue_count"][2].dead and player.tag["zeyue_count"][1] > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.tag["zeyue_count"][2]
    for i = 1, player.tag["zeyue_count"][1], 1 do
      if player.dead or to.dead then return end
      room:useVirtualCard("slash", nil, player, to, "zeyue", true)
    end
  end,

  refresh_events ={fk.RoundStart, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if player:getMark("zeyue") ~= 0 and player.tag["zeyue_count"] then
      if event == fk.RoundStart then
        return true
      else
        return data.card and table.contains(data.card.skillNames, "zeyue")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.RoundStart then
      player.tag["zeyue_count"][1] = player.tag["zeyue_count"][1] + 1
    else
      player.room:handleAddLoseSkills(player, player:getMark("zeyue"), nil, true, false)
      player.room:setPlayerMark(player, "zeyue", 0)
    end
  end,
}
qingyix:addRelatedSkill(qingyix_record)
zeyue:addRelatedSkill(zeyue_record)
xiahouxuan:addSkill(huanfu)
xiahouxuan:addSkill(qingyix)
xiahouxuan:addSkill(zeyue)
Fk:loadTranslationTable{
  ["xiahouxuan"] = "夏侯玄",
  ["huanfu"] = "宦浮",
  [":huanfu"] = "当你使用【杀】指定目标或成为【杀】的目标后，你可以弃置任意张牌（至多为你的体力上限），若此【杀】对目标角色造成的伤害值为弃牌数，"..
  "你摸弃牌数两倍的牌。",
  ["qingyix"] = "清议",
  [":qingyix"] = "出牌阶段限一次，你可以与至多两名有牌的其他角色同时弃置一张牌，若类型相同，你可以重复此流程。结束阶段，你可以获得其中颜色不同的牌各一张。",
  ["zeyue"] = "迮阅",
  [":zeyue"] = "限定技，准备阶段，你可以令一名你上个回合结束后（首轮为游戏开始后）对你造成过伤害的其他角色失去武将牌上一个技能（锁定技、觉醒技、限定技除外）。"..
  "每轮结束时，其视为对你使用X张【杀】（X为其已失去此技能的轮数），若此【杀】造成伤害，其获得以此法失去的技能。",
  ["#huanfu-invoke"] = "宦浮：你可以弃置至多%arg张牌，若此【杀】造成伤害值等于弃牌数，你摸两倍的牌",
  ["#qingyi-discard"] = "清议：弃置一张牌",
  ["#qingyi-invoke"] = "清议：是否继续发动“清议”？",
  ["#qingyix_record"] = "清议",
  ["#zeyue-choose"] = "迮阅：你可以令一名角色失去一个技能，其每轮视为对你使用【杀】，造成伤害后恢复失去的技能",
  ["#zeyue-choice"] = "迮阅：选择令 %dest 失去的一个技能",
  ["#zeyue_record"] = "迮阅",

  ["$huanfu1"] = "宦海浮沉，莫问前路。",
  ["$huanfu2"] = "仕途险恶，吉凶难料。",
  ["$qingyix1"] = "布政得失，愿与诸君共议。",
  ["$qingyix2"] = "领军伐谋，还请诸位献策。",
  ["$zeyue1"] = "以令相迮，束阀阅之家。",
  ["$zeyue2"] = "以正相争，清朝野之妒。",
  ["~xiahouxuan"] = "玉山倾颓心无尘……",
}

local zhangzhi = General(extension, "zhangzhi", "qun", 3)
local bixin_viewas = fk.CreateViewAsSkill{
  name = "bixin_viewas",
  interaction = function()
    local names = {}
    local mark = Self:getMark("bixin-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if mark == 0 or (not table.contains(mark, card.trueName)) then
        if card.type == Card.TypeBasic and card.name ~= "jink" and (card.name ~= "peach" or (card.name == "peach" and Self:isWounded())) and
          Self:usedCardTimes(card.name, Player.HistoryRound) == 0 then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "bixin"
    return card
  end,
}
local bixin = fk.CreateTriggerSkill{
  name = "bixin",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and
      (player:getMark("bixin_basic") == 0 or player:getMark("bixin_trick") == 0 or player:getMark("bixin_equip") == 0) then
      if player:usedSkillTimes("ximo", Player.HistoryGame) == 2 then
        return target == player and player.phase == Player.Finish
      elseif player:usedSkillTimes("ximo", Player.HistoryGame) == 1 then
        return target == player and (player.phase == Player.Start or player.phase == Player.Finish)
      elseif player:usedSkillTimes("ximo", Player.HistoryGame) == 0 then
        return target.phase == Player.Start or target.phase == Player.Finish
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "bixin_viewas", "#bixin-invoke", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    for _, type in ipairs({"basic", "trick", "equip"}) do
      if player:getMark("bixin_"..type) == 0 then
        table.insert(types, type)
      end
    end
    if #types == 0 then return true end
    local choice = room:askForChoice(player, types, self.name, "#bixin-choice")
    room:addPlayerMark(player, "bixin_"..choice, 1)
    player:drawCards(3, self.name)
    local cards = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      if Fk:getCardById(id):getTypeString() == choice then
        table.insert(cards, id)
      end
    end
    if #cards == 0 then return true end
    local card = Fk.skills["bixin_viewas"]:viewAs(self.cost_data.cards)
    card:addSubcards(cards)
    room:useCard{
      from = player.id,
      tos = table.map(self.cost_data.targets, function(id) return {id} end),
      card = card,
    }
  end,
}
local bixinEx = fk.CreateViewAsSkill{
  name = "bixinEx",
  pattern = ".|.|.|.|.|basic",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and Self:usedCardTimes(card.name, Player.HistoryRound) == 0 then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "bixin"
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
local bixinEx_trigger = fk.CreateTriggerSkill{
  name = "#bixinEx_trigger",
  events = {fk.PreCardUse},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "bixin")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    for _, type in ipairs({"basic", "trick", "equip"}) do
      if player:getMark("bixin_"..type) < 3 then
        table.insert(types, type)
      end
    end
    if #types == 0 then return true end
    local choice = room:askForChoice(player, types, "bixin", "#bixin-choice")
    room:addPlayerMark(player, "bixin_"..choice, 1)
    player:drawCards(1, "bixin")
    local cards = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      if Fk:getCardById(id):getTypeString() == choice then
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        from = player.id,
        toArea = Card.Processing,
        moveReason = fk.ReasonUse,
      })
      data.card:addSubcards(cards)  --甚至可以手动加子卡
      return false
    else
      return true
    end
  end,
}
local ximo = fk.CreateTriggerSkill{
  name = "ximo",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.name == "bixin"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, type in ipairs({"basic", "trick", "equip"}) do
      room:setPlayerMark(player, "bixin_"..type, 0)
    end
    if player:usedSkillTimes(self.name, Player.HistoryGame) > 2 then
      room:handleAddLoseSkills(player, "-ximo|feibai", nil, true, false)
      room:handleAddLoseSkills(player, "-bixin|bixinEx", nil, false, true)
    end
  end,
}
local feibai = fk.CreateTriggerSkill{
  name = "feibai",
  anim_type = "switch",
  switch_skill_name = "feibai",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.PreHpRecover},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DamageCaused then
        return target == player and player:getSwitchSkillState(self.name, false) == fk.SwitchYang and
          data.card and data.card.color ~= Card.Black
      else
        return player:getSwitchSkillState(self.name, false) == fk.SwitchYin and
          data.recoverBy and data.recoverBy == player and data.card and data.card.color ~= Card.Red
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      data.num = data.num + 1
    end
  end,
}
Fk:addSkill(bixin_viewas)
zhangzhi:addSkill(bixin)
zhangzhi:addSkill(ximo)
zhangzhi:addRelatedSkill(feibai)
bixinEx:addRelatedSkill(bixinEx_trigger)
Fk:addSkill(bixinEx)
Fk:loadTranslationTable{
  ["zhangzhi"] = "张芝",
  ["bixin"] = "笔心",
  [":bixin"] = "『每名角色的』『准备阶段和』『结束阶段，』你可以声明一种牌的类型并摸3张牌（每种类型限1次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
  ["ximo"] = "洗墨",
  [":ximo"] = "锁定技，当你发动〖笔心〗后，移除其描述的前五个字符，若为第三次发动，交换其描述中的两个数字，你失去本技能并获得〖飞白〗。",
  ["feibai"] = "飞白",
  [":feibai"] = "转换技，锁定技，阳：当你的非黑色牌造成伤害时，此伤害值+1；阴：当你的非红色牌回复体力时，此回复值+1。",
  ["bixinEx"] = "笔心",
  [":bixinEx"] = "你可以声明一种牌的类型并摸1张牌（每种类型限3次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
  ["#bixin-invoke"] = "笔心：你可以声明一种牌的类型并摸3张牌，将所有此类型手牌当一种基本牌使用",
  ["#bixin-choice"] = "笔心：选择用来转化的牌的类别",
  ["bixin_viewas"] = "笔心",

  ["$bixin1"] = "携笔落云藻，文书剖纤毫。",
  ["$bixin2"] = "执纸抒胸臆，挥笔涕汍澜。",
  ["$ximo1"] = "帛尽漂洗，以待后用。",
  ["$ximo2"] = "故帛无尽，而笔不停也。",
  ["$ximo3"] = "以帛为纸，临池习书。",
  ["$feibai1"] = "字之体势，一笔而成。",
  ["$feibai2"] = "超前绝伦，独步无双。",
  ["~zhangzhi"] = "力透三分，何以言老……",
}

local godsunquan = General(extension, "godsunquan", "god", 4)
local yuheng_skills = {
  --standard
  "keji", "xiaoji", "jieyin", "ex__zhiheng", "ex__yingzi", "ex__fanjian", "ex__guose",
  --shzl
  "tianyi", "yinghun", "haoshi", "dimeng", "jiang", "zhijian",
  --sp
  "hongyuan", "duanbing", "fenxun", "mumu", "tanhu", "yanxiao",
  --yjcm
  "xuanfeng", "pojun", "anxu", "gongqi", "anjian", "zhiyan", "danshou", "shenxing", "bingyi", "yanzhu", "anguo", "jishe",
  --ol
  "duwu", "canshi", "shanxi", "xiashu", "lianpian", "bizheng", "yidian", "lanjiang", "yuanchou", "ol__hongyuan", "ol__bingyi", "ol__mumu",
  "xianbi",
  --mobile
  "yingjian", "dujin", "chongjian", "mobile__shangyi", "mobile__diaodu", "yanji", "mou__kurou", "mou__guose", "mou__fanjian", "m_ex__pojun",
  --tenyear
  "xunxian", "guolun", "duanfa", "sp__youdi", "qinguo", "zhukou", "jinjian", "jingzao", "xinyou", "zhiren", "sibian", "boyan", "niji",
  --overseas
  "os__yilie", "os__fenming", "os__shangyi",
  --offline
  "miaojian",
  --wandian
  "wd__kangyin", "wd__kenjian",
}

--[[
  "ex__zhiheng", "dimeng", "anxu", "ol__bingyi", "shenxing",
  "xingxue", "anguo", "os__jiexun", "xiashu", "ol__hongyuan",
  "lanjiang", "sp__youdi", "guanwei", "diaodu", "bizheng"
]]

local yuheng = fk.CreateTriggerSkill{
  name = "yuheng",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TurnStart then
        return not player:isNude()
      else
        return player:getMark(self.name) ~= 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local default_discard = table.find(player:getCardIds{Player.Hand, Player.Equip}, function (id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
      if default_discard == nil then return false end
      local cards = {default_discard}
      local _, ret = room:askForUseActiveSkill(player, "yuheng_active", "#yuheng-invoke", false)
      if ret then
        cards = ret.cards
      end
      room:throwCard(cards, self.name, player, player)
      if player.dead then return end
      local skills = table.random(table.filter(yuheng_skills, function (skill_name)
        return not player:hasSkill(skill_name, true)
      end), #cards)
      if #skills == 0 then return false end
      local mark = type(player:getMark("yuheng")) == "table" and player:getMark("yuheng") or {}
      table.insertTableIfNeed(mark, skills)
      room:setPlayerMark(player, "yuheng", mark)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    else
      local skills = player:getMark(self.name)
      room:setPlayerMark(player, "yuheng", 0)
      skills = table.filter(skills, function (skill_name)
        return player:hasSkill(skill_name, true)
      end)
      if #skills == 0 then return false end
      room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
      if not player.dead then
        player:drawCards(#skills, self.name)
      end
    end
  end,
}
local yuheng_active = fk.CreateActiveSkill{
  name = "yuheng_active",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    if Self:prohibitDiscard(Fk:getCardById(to_select)) then return false end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function(id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
}
local dili = fk.CreateTriggerSkill{
  name = "dili",
  anim_type = "special",
  events = {fk.EventAcquireSkill, fk.MaxHpChanged},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.room.logic:getCurrentEvent() ~= nil
  end,
  can_wake = function(self, event, target, player, data)
    local n = 0
    for _, s in ipairs(player.player_skills) do
      if not (s.attached_equip or s.name[#s.name] == "&") then
        n = n + 1
      end
    end
    return n > player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    local skills = {}
    for _, s in ipairs(player.player_skills) do
      if not (s.attached_equip or s.name[#s.name] == "&" or s == self) then
        table.insertIfNeed(skills, s.name)
      end
    end
    local result = room:askForCustomDialog(player, self.name,
    "packages/utility/qml/ChooseSkillBox.qml", {
      skills, 0, 3, "#dili-invoke"
    })
    if result == "" then return false end
    local choice = json.decode(result)
    if #choice > 0 then
      room:handleAddLoseSkills(player, "-"..table.concat(choice, "|-"), nil, true, false)
      skills = {"shengzhi", "quandao", "chigang"}
      local skill = {}
      for i = 1, #choice, 1 do
        if i > 3 then break end
        table.insert(skill, skills[i])
      end
      room:handleAddLoseSkills(player, table.concat(skill, "|"), nil, true, false)
    end
  end,
}
local shengzhi = fk.CreateTriggerSkill{
  name = "shengzhi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not data.cardSkill and data.frequency ~= Skill.Compulsory and
      data.frequency ~= Skill.Wake and not data.attached_equip and data.name[#data.name] ~= "&"
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shengzhi-turn", 1)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@shengzhi-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shengzhi-turn", 0)
  end,
}
local shengzhi_targetmod = fk.CreateTargetModSkill{
  name = "#shengzhi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("@@shengzhi-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:getMark("@@shengzhi-turn") > 0
  end,
}
local quandao = fk.CreateTriggerSkill{
  name = "quandao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isKongcheng() then
      player:drawCards(1, self.name)
    else
      local slash = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == "slash" end)
      local trick = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):isCommonTrick() end)
      if #slash == #trick then
        player:drawCards(1, self.name)
      else
        local n = #slash - #trick
        if n > 0 then
          room:askForDiscard(player, n, n, false, self.name, false, "slash")
        else
          room:askForDiscard(player, -n, -n, false, self.name, false, ".|.|.|.|.|trick")
        end
        if not player.dead then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
local chigang = fk.CreateTriggerSkill{
  name = "chigang",
  anim_type = "switch",
  switch_skill_name = "chigang",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to == Player.Judge
  end,
  on_use = function(self, event, target, player, data)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      data.to = Player.Draw
    else
      data.to = Player.Play
    end
  end,
}
local qionglan = fk.CreateTriggerSkill{
  name = "qionglan",
  frequency = Skill.Compulsory,
  can_trigger = Util.FalseFunc,
}
local jiaohui = fk.CreateTriggerSkill{
  name = "jiaohui",
  frequency = Skill.Compulsory,
  can_trigger = Util.FalseFunc,
}
local yuanlv = fk.CreateTriggerSkill{
  name = "yuanlv",
  frequency = Skill.Compulsory,
  can_trigger = Util.FalseFunc,
}
Fk:addSkill(yuheng_active)
shengzhi:addRelatedSkill(shengzhi_targetmod)
godsunquan:addSkill(yuheng)
godsunquan:addSkill(dili)
godsunquan:addRelatedSkill(shengzhi)
godsunquan:addRelatedSkill(quandao)
godsunquan:addRelatedSkill(chigang)
godsunquan:addRelatedSkill(qionglan)
godsunquan:addRelatedSkill(jiaohui)
godsunquan:addRelatedSkill(yuanlv)
Fk:loadTranslationTable{
  ["godsunquan"] = "神孙权",
  ["yuheng"] = "驭衡",
  [":yuheng"] = "锁定技，回合开始时，你弃置任意张花色不同的牌，随机获得等量吴势力武将的技能。回合结束时，你失去以此法获得的技能，摸等量张牌。",
  ["dili"] = "帝力",
  [":dili"] = "觉醒技，当你的技能数超过体力上限后，你减少1点体力上限，失去任意个其他技能并获得〖圣质〗〖权道〗〖持纲〗中的前等量个。",
  ["shengzhi"] = "圣质",
  [":shengzhi"] = "锁定技，当你发动非锁定技后，你本回合使用的下一张牌无距离和次数限制。",
  ["quandao"] = "权道",
  [":quandao"] = "锁定技，当你使用【杀】或普通锦囊牌时，你将手牌中两者数量弃至相同并摸一张牌。",
  ["chigang"] = "持纲",
  [":chigang"] = "转换技，锁定技，阳：你的判定阶段改为摸牌阶段；阴：你的判定阶段改为出牌阶段。",
  ["yuheng_active"] = "驭衡",
  ["#yuheng-invoke"] = "驭衡：弃置任意张花色不同的牌，随机获得等量吴势力武将的技能",
  ["#dili-invoke"] = "帝力：选择失去至多三个技能",
  [":Cancel"] = "取消",
  ["@@shengzhi-turn"] = "圣质",
  ["qionglan"] = "穹览",
  [":qionglan"] = "此东吴命运线未开启。",
  ["jiaohui"] = "交辉",
  [":jiaohui"] = "此东吴命运线未开启。",
  ["yuanlv"] = "渊虑",
  [":yuanlv"] = "此东吴命运线未开启。",

  ["$dili1"] = "身处巅峰，览天下大事。",
  ["$dili2"] = "位居至尊，掌至高之权。",
  ["$yuheng1"] = "权术妙用，存乎一心。",
  ["$yuheng2"] = "威权之道，皆在于衡。",
  ["$shengzhi1"] = "位继父兄，承弘德以继往。",
  ["$shengzhi2"] = "英魂犹在，履功业而开来。",
  ["$chigang1"] = "秉承伦常，扶树纲纪。",
  ["$chigang2"] = "至尊临位，则朝野自肃。",
  ["$qionglan1"] = "事无巨细，咸既问询。",
  ["$qionglan2"] = "纵览全局，以小见大。",
  ["$quandao1"] = "继策掌权，符令吴会。",
  ["$quandao2"] = "以权驭衡，谋定天下。",
  ["$jiaohui1"] = "日月交辉，天下大白。",
  ["$jiaohui2"] = "雄鸡引颈，声鸣百里。",
  ["$yuanlv1"] = "临江而眺，静观江水东流。",
  ["$yuanlv2"] = "屹立山巅，笑看大江潮来。",
  ["~godsunquan"] = "困居江东，枉称至尊……",
}

local ahuinan = General(extension, "ahuinan", "qun", 4)
local jueman = fk.CreateTriggerSkill{
  name = "jueman",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      player.tag[self.name] = player.tag[self.name] or {}
      if #player.tag[self.name] < 2 then
        player.tag[self.name] = {}
        return
      end
      local n = 0
      if player.tag[self.name][1][1] == player.id then
        n = n + 1
      end
      if player.tag[self.name][2][1] == player.id then
        n = n + 1
      end
      self.cost_data = nil
      if #player.tag[self.name] > 2 and n == 0 then
        self.cost_data = player.tag[self.name][3][2]
      end
      if #player.tag[self.name] > 1 and n == 1 then
        self.cost_data = 1
      end
      player.tag[self.name] = {}
      return self.cost_data
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data == 1 then
      player:drawCards(1, self.name)
    else
      local room = player.room
      local name = self.cost_data.name
      local targets = {}
      if name == "slash" then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not player:isProhibited(p, Fk:cloneCard(name)) end), Util.IdMapper)
      elseif (name == "peach" and player:isWounded()) or name == "analeptic" then
        targets = {player.id}
      end
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#jueman-choose:::"..name, self.name, false)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:useVirtualCard(name, nil, player, room:getPlayerById(to), self.name, true)
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.type == Card.TypeBasic and not table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insert(player.tag[self.name], {target.id, data.card})
  end,
}
ahuinan:addSkill(jueman)
Fk:loadTranslationTable{
  ["ahuinan"] = "阿会喃",
  ["jueman"] = "蟨蛮",
  [":jueman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均不为你，你视为使用本回合第三张使用的基本牌；仅其中之一为你，你摸一张牌。",
  ["#jueman-choose"] = "蟨蛮：选择视为使用【%arg】的目标",

  ["$jueman1"] = "伤人之蛇蝎，向来善藏行。",
  ["$jueman2"] = "我不欲伤人，奈何人自伤。",
  ["~ahuinan"] = "什么？大王要杀我？",
}

return extension
