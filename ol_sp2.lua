local extension = Package("ol_sp2")
extension.extensionName = "ol"

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
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = {}
    local skills = table.map(Fk.generals[target.general].skills, function(s) return s.name end)
    for _, skill in ipairs(skills) do
      if target:hasSkill(skill, true, true) and skill.frequency ~= Skill.Limited and skill.frequency ~= Skill.Wake and
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
    player.tag[self.name] = player.tag[self.name] or {}
    if #player.tag[self.name] > 0 then
      room:handleAddLoseSkills(player, choice.."|-"..player.tag[self.name][1], nil, true, true)
    else
      room:handleAddLoseSkills(player, choice, nil, true, true)
    end
    player.tag[self.name] = {choice}
  end,
}
local shanzhuan = fk.CreateTriggerSkill{
  name = "shanzhuan",
  anim_type = "control",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
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
}
--群张辽 2020.10.26

local zhangling = General(extension, "zhangling", "qun", 3)
local huqi = fk.CreateTriggerSkill{
  name = "huqi",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and data.from and not data.from.dead
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
    if from:hasSkill(self.name) then
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
  card_filter = function(self, to_select, selected)
    return false
  end,
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
    player:removeCards(Player.Special, player:getPile("zhangling_lu"), "zhangling_lu")
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
}
--卧龙凤雏 2021.2.7

local panshu = General(extension, "ol__panshu", "wu", 3, 3, General.Female)
local weiyi = fk.CreateTriggerSkill{
  name = "weiyi",
  anim_type = "control",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target.dead and target:getMark(self.name) == 0
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
    return Self:usedSkillTimes("jinzhi", Player.HistoryRound)
  end,
  target_num = 0,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      return true
    else
      return #selected < Self:usedSkillTimes("jinzhi", Player.HistoryRound) and
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
  pattern = ".|.|.|.|.|basic",
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
  card_filter = function()
    return false
  end,
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
    local black = #table.filter(player:getCardIds{Player.Hand, Player.Equip}, function(id) return Fk:getCardById(id).color == Card.Black end)
    local red = #table.filter(player:getCardIds{Player.Hand, Player.Equip}, function(id) return Fk:getCardById(id).color == Card.Red end)
    return math.max(black, red) > player:usedSkillTimes(self.name, Player.HistoryRound)
  end,
  enabled_at_response = function(self, player, response)
    local black = #table.filter(player:getCardIds{Player.Hand, Player.Equip}, function(id) return Fk:getCardById(id).color == Card.Black end)
    local red = #table.filter(player:getCardIds{Player.Hand, Player.Equip}, function(id) return Fk:getCardById(id).color == Card.Red end)
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
}

local huangzu = General(extension, "ol__huangzu", "qun", 4)
local wangong = fk.CreateTriggerSkill{
  name = "wangong",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("@@wangong") > 0 and data.card.trueName == "slash"
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
}
-- 黄承彦 2021.7.15

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
    if #cards ~= 1 then return end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = function(self, player)
    return false
  end,
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
}

local duxi = General(extension, "duxi", "wei", 3)
local quxi_active = fk.CreateActiveSkill{
  name = "#quxi_active",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
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
      return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
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
      local targets = table.map(room:getOtherPlayers(to), function(p) return p.id end)
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard
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
      return player:hasSkill(self.name) and player.phase == Player.Discard
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
  [":quxi"] = "限定技，出牌阶段结束时，你可以跳过弃牌阶段并翻至背面，选择两名手牌数不同的其他角色，其中手牌少的角色获得另一名角色一张牌并获得「丰」，另一名角色获得「歉」。<br>"..
  "有「丰」的角色摸牌阶段摸牌数+1，有「歉」的角色摸牌阶段摸牌数-1。当有「丰」或「歉」的角色死亡时或每轮开始时，你可以转移「丰」「歉」。",
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
}

Fk:loadTranslationTable{
  ["lvkuanglvxiang"] = "吕旷吕翔",
  ["qigong"] = "齐攻",
  [":qigong"] = "当你使用的仅指定单一目标的【杀】被【闪】抵消后，你可以令一名角色对此目标再使用一张无距离限制的【杀】，此【杀】不可被响应。",
  ["liehou"] = "列侯",
  [":liehou"] = "出牌阶段限一次，你可以令你攻击范围内一名有手牌的角色交给你一张手牌，若如此做，你将一张手牌交给你攻击范围内的另一名其他角色。",
}

Fk:loadTranslationTable{
  ["ol__dengzhi"] = "邓芝",
  ["xiuhao"] = "修好",
  [":xiuhao"] = "每名角色的回合限一次，你对其他角色造成伤害，或其他角色对你造成伤害时，你可防止此伤害，令伤害来源摸两张牌。",
  ["sujian"] = "素俭",
  [":sujian"] = "锁定技，弃牌阶段，你改为：将所有非本回合获得的手牌分配给其他角色，或弃置非本回合获得的手牌，并弃置一名其他角色至多等量的牌。",
}

local bianfuren = General(extension, "ol__bianfuren", "wei", 3, 3, General.Female)
local ol__wanwei = fk.CreateTriggerSkill{
  name = "ol__wanwei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local names = {}
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if (move.moveReason == fk.ReasonPrey or move.moveReason == fk.ReasonDiscard) and
            (move.proposer ~= player and move.proposer ~= player.id) then
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
    return player:hasSkill(self.name) and target ~= player and not player:isKongcheng() and
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
}

local zuofen = General(extension, "zuofen", "jin", 3, 3, General.Female)
local zhaosong = fk.CreateTriggerSkill{
  name = "zhaosong",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Draw and not target:isKongcheng() and
      target:getMark("@@zuofen_lei") == 0 and target:getMark("@@zuofen_fu") == 0 and target:getMark("@@zuofen_song") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhaosong-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
        return not p:isAllNude() end), function(p) return p.id end), 1, 1, "#zhaosong2-invoke", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
        not player:isProhibited(p, data.card) end), function(p) return p.id end)
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
      room:broadcastSkillInvoke("zhaosong", 1)
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
      room:broadcastSkillInvoke("zhaosong", 2)
      room:notifySkillInvoked(player, self.name, "control")
      room:removePlayerMark(player, "@@zuofen_fu", 1)
      local to = room:getPlayerById(self.cost_data)
      local cards = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
      room:throwCard(cards, self.name, to, player)
    else
      room:broadcastSkillInvoke("zhaosong", 3)
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Hand] <= #player.player_cards[Player.Hand] end), function(p) return p.id end)
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
}

--冯方女

local yangyi = General(extension, "ol__yangyi", "shu", 3)
local juanxia_viewas = fk.CreateViewAsSkill{
  name = "juanxia_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick and card.skill.target_num == 1 then  --FIXME：衍生牌
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
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
        if card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick and card.skill.target_num == 1 and
          card.skill:targetFilter(mark[2], {}, {}, card) and
          not Self:isProhibited(Fk:currentRoom():getPlayerById(mark[2]), card) then  --FIXME：衍生牌
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
}
local juanxia = fk.CreateTriggerSkill{
  name = "juanxia",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseViewAsSkill(player, "juanxia_viewas", "#juanxia-choose", true)
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
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local cards = player:drawCards(2, self.name)
    if Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color then
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
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
}

local zhanghe = General(extension, "ol__zhanghe", "qun", 4)
local ol__zhouxuan = fk.CreateTriggerSkill{
  name = "ol__zhouxuan",
  anim_type = "drawcard",
  expand_pile = "zhanghe_xuan",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard
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

  refresh_events = {fk.EventPhaseEnd, fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    if target == player and #player:getPile("zhanghe_xuan") > 0 then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Play
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      room:moveCards({
        from = player.id,
        ids = player:getPile("zhanghe_xuan"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = "zhanghe_xuan",
      })
    else
      if not table.every(room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Hand] < #player.player_cards[Player.Hand] end) then
        player:drawCards(#player:getPile("zhanghe_xuan"), self.name)
      else
        player:drawCards(1, self.name)
      end
      local card = room:askForCard(player, 1, 1, false, self.name, false, ".|.|.|zhanghe_xuan|.|.", "#ol__zhouxuan-discard", "zhanghe_xuan")
      if #card == 0 then card = {table.random(player:getPile("zhanghe_xuan"))} end
      room:moveCards({
        from = player.id,
        ids = card,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = "zhanghe_xuan",
      })
    end
  end,
}
zhanghe:addSkill(ol__zhouxuan)
Fk:loadTranslationTable{
  ["ol__zhanghe"] = "张郃",
  ["ol__zhouxuan"] = "周旋",
  [":ol__zhouxuan"] = "弃牌阶段开始时，你可将至多五张手牌置于武将牌上（称为“旋”）直到你下个出牌阶段结束。"..
  "当你使用一张牌时，你摸一张牌，然后移去一张“旋”；若你的手牌不是场上唯一最多，则改为摸X张牌（X为“旋”的数量）。",
  ["zhanghe_xuan"] = "旋",
  ["#ol__zhouxuan-invoke"] = "周旋：你可以将至多5张手牌置为“旋”",
  ["#ol__zhouxuan-discard"] = "周旋：请移去一张“旋”",
}

Fk:loadTranslationTable{
  ["ol__dongzhao"] = "董昭",
  ["xianlve"] = "先略",
  [":xianlve"] = "主公的回合开始时，你可以声明一种普通锦囊牌牌名。每回合限一次，当其他角色使用被声明的牌后，你摸两张牌并分配给任意角色，"..
  "然后重新声明一张普通锦囊牌。",
  ["zaowang"] = "造王",
  [":zaowang"] = "限定技，出牌阶段，你可以令一名角色增加1点体力上限、回复1点体力并摸三张牌，若其为：忠臣，当主公死亡时与主公交换身份牌；:"..
  "反贼，当其被主公或忠臣杀死时，主公方获胜。",
}

local wuyan = General(extension, "wuyanw", "wu", 4)
local lanjiang = fk.CreateTriggerSkill{
  name = "lanjiang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
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
}

local chendeng = General(extension, "ol__chendeng", "qun", 4)
local fengji = fk.CreateTriggerSkill{
  name = "fengji",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
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
        local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id end), 1, 1, "#fengji-choose:::"..choice, self.name, true)
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
}

Fk:loadTranslationTable{
  ["ol__tianyu"] = "田豫",
  ["saodi"] = "扫狄",
  [":saodi"] = "当你使用【杀】或普通锦囊牌仅指定一名其他角色为目标时，你可以令你与其之间的角色均成为此牌的目标。",
  ["zhuitao"] = "追讨",
  [":zhuitao"] = "准备阶段，你可以令你与一名未以此法减少距离的其他角色的距离-1。当你对其造成伤害后，失去你以此法对其减少的距离。",
}

Fk:loadTranslationTable{
  ["fanjiangzhangda"] = "范疆张达",
  ["yuanchou"] = "怨仇",
  [":yuanchou"] = "锁定技，你使用的黑色【杀】无视目标角色防具，其他角色对你使用的黑色【杀】无视你的防具。",
  ["juesheng"] = "决生",
  [":juesheng"] = "限定技，你可以视为使用一张伤害为X的【决斗】（X为目标角色本局使用【杀】的数量且至少为1），然后其获得本技能直到其下回合结束。",
}

local yanghu = General(extension, "ol__yanghu", "jin", 4)
local huaiyuan = fk.CreateTriggerSkill{
  name = "huaiyuan",
  anim_type = "support",
  events = {fk.AfterCardsMove, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(self.name) and player:getMark(self.name) ~= 0 then
      self.trigger_times = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(player:getMark(self.name), info.cardId) then
              self.trigger_times = self.trigger_times + 1
              table.removeOne(player:getMark(self.name), info.cardId)
              if #player:getMark(self.name) == 0 then
                player.room:setPlayerMark(player, self.name, 0)
                break
              end
            end
          end
        end
      end
      return self.trigger_times > 0
    elseif event == fk.Death then
      return target == player and (player:getMark("@huaiyuan_maxcards") > 0 or player:getMark("@huaiyuan_attackrange") > 0)
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      local ret
      for i = 1, self.trigger_times do
        ret = self:doCost(event, target, player, data)
        if ret then return ret end
      end
    else
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
        return p.id end), 1, 1, "#huaiyuan-invoke", self.name, false)
        if #to > 0 then
          self.cost_data = to[1]
        else
          self.cost_data = player.id
        end
        return true
    else
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, "#huaiyuan-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if event == fk.AfterCardsMove then
      local choice = room:askForChoice(player, {"huaiyuan_maxcards", "huaiyuan_attackrange", "draw1"}, self.name, "#huaiyuan-choice::"..to.id)
      if choice == "draw1" then
        to:drawCards(1, self.name)
      else
        room:addPlayerMark(to, "@"..choice, 1)
      end
    else
      room:addPlayerMark(to, "@huaiyuan_maxcards", player:getMark("@huaiyuan_maxcards"))
      room:addPlayerMark(to, "@huaiyuan_attackrange", player:getMark("@huaiyuan_attackrange"))
    end
  end,

  refresh_events = {fk.AfterDrawInitialCards},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, table.clone(player.player_cards[Player.Hand]))
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
local chongxin = fk.CreateActiveSkill{
  name = "chongxin",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#chongxin-card")
    room:recastCard(card, target, self.name)
    card = room:askForCard(player, 1, 1, true, self.name, false, ".", "#chongxin-card")
    room:recastCard(card, player, self.name)
  end,
}
local dezhang = fk.CreateTriggerSkill{
  name = "dezhang",
  frequency = Skill.Wake,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.from == Player.RoundStart and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("huaiyuan") == 0
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
    if player:hasSkill(self.name) then
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
      targets = table.map(room:getAlivePlayers(), function(p) return p.id end)
      prompt = "#weishu-draw"
    elseif self.cost_data[1] == "discard" then
      targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), function(p) return p.id end)
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
huaiyuan:addRelatedSkill(huaiyuan_maxcards)
huaiyuan:addRelatedSkill(huaiyuan_attackrange)
yanghu:addSkill(huaiyuan)
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
}

local qinghegongzhu = General(extension, "qinghegongzhu", "wei", 3, 3, General.Female)
local zengou = fk.CreateTriggerSkill{
  name = "zengou",
  anim_type = "control",
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card.name == "jink" and player:inMyAttackRange(player.room:getPlayerById(data.from))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#zengou-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|^basic", "#zengou-discard") == 0 then
      room:loseHp(player, 1, self.name)
    end
    if room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
    return true
  end,
}
local zhangjiq = fk.CreateTriggerSkill{
  name = "zhangjiq",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Finish and
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
      if player:getMark("zhangji2-turn") > 0 and not target:isNude() and room:askForSkillInvoke(player, self.name, data, "#zhangji-discard::"..target.id) then
        room:askForDiscard(target, 2, 2, true, self.name, false)
      end
    else
      room:askForDiscard(target, 2, 2, true, self.name, false)
    end
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
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
  ["#zengou-invoke"] = "谮构：你可以弃置一张非基本牌或失去1点体力令 %dest 的【闪】无效，你获得之",
  ["#zengou-discard"] = "谮构：弃置一张非基本牌，或点“取消”失去1点体力",
  ["#zhangji-draw"] = "长姬：你可以令 %dest 摸两张牌",
  ["#zhangji-discard"] = "长姬：你可以令 %dest 弃置两张牌",
}

Fk:loadTranslationTable{
  ["ol__tengfanglan"] = "滕芳兰",
  ["luochong"] = "落宠",
  [":luochong"] = "准备阶段或当你每回合首次受到伤害后，你可以选择一项，令一名角色：1.回复1点体力；2.失去1点体力；3.弃置两张牌；4.摸两张牌。"..
  "每轮每项每名角色限一次。",
  ["aichen"] = "哀尘",
  [":aichen"] = "锁定技，当你进入濒死状态时，若【落宠】选项数大于1，你移除其中一项。",
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
local panqin_record = fk.CreateTriggerSkill{  --怎样在没获得过叛侵的情况下为叛侵记录牌
  name = "#panqin_record",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Play or player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          local mark = player:getMark("panqin-phase")
          if mark == 0 then mark = {} end
          table.insertIfNeed(mark, info.cardId)
          player.room:setPlayerMark(player, "panqin-phase", mark)
        end
      end
    end
  end,
}
local panqin = fk.CreateTriggerSkill{
  name = "panqin",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (player.phase == Player.Play or player.phase == Player.Discard) and
      player:getMark("panqin-phase") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = player:getMark("panqin-phase")
    local cards = {}
    for _, id in ipairs(ids) do
      if room:getCardArea(id) == Card.DiscardPile then
        table.insertIfNeed(cards, id)
      end
    end
    if #cards > 0 and player.room:askForSkillInvoke(player, self.name, nil, "#panqin-invoke:::"..#cards) then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(self.cost_data)
    card.skillName = self.name
    room:useCard({
      from = player.id,
      card = card,
    })
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.firstTarget and table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if #TargetGroup:getRealTargets(data.tos) >= #data.card.subcards then
      doManwang(player, 4 - player:getMark("@manwang"))
      if player:getMark("@manwang") < 4 then
        player.room:addPlayerMark(player, "@manwang", 1)
      end
    end
  end,
--[[
  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Play or player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          local mark = player:getMark("panqin-phase")
          if mark == 0 then mark = {} end
          table.insertIfNeed(mark, info.cardId)
          player.room:addPlayerMark(player, "panqin-phase", mark)
        end
      end
    end
  end,]]--
}
manwang:addRelatedSkill(panqin_record)  --FIXME
menghuo:addSkill(manwang)
menghuo:addRelatedSkill(panqin)
Fk:loadTranslationTable{
  ["sp__menghuo"] = "孟获",
  ["manwang"] = "蛮王",
  [":manwang"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。",
  ["panqin"] = "叛侵",
  [":panqin"] = "出牌和弃牌阶段结束时，你可以将弃牌堆中你本阶段弃置的牌当【南蛮入侵】使用，若此牌目标数不小于这些牌的数量，你执行并移除〖蛮王〗的最后一项。",
  ["@manwang"] = "蛮王",
  ["#panqin-invoke"] = "叛侵：你可以将弃牌堆中的%arg张牌当【南蛮入侵】使用",
}

Fk:loadTranslationTable{
  ["ruiji"] = "芮姬",
  ["qiaoli"] = "巧力",
  [":qiaoli"] = "出牌阶段各限一次，1.你可以将一张武器牌当【决斗】使用，此牌对目标角色造成伤害后，你摸与之攻击范围等量张牌，然后可以分配其中任意张牌；"..
  "2.你可以将一张非武器装备牌当【决斗】使用且不能被响应，然后于结束阶段随机获得一张装备牌。",
  ["qingliang"] = "清靓",
  [":qingliang"] = "每回合限一次，当你成为其他角色使用的【杀】或伤害锦囊牌的唯一目标时，你可以展示所有手牌并选择一项："..
  "1.你与其各摸一张牌；2.弃器一种花色的所有手牌，取消此目标。",
}

local weizi = General(extension, "weizi", "qun", 3)
local yuanzi = fk.CreateTriggerSkill{
  name = "yuanzi",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target.phase == Player.Start and
          player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and not player:isKongcheng()
      else
        return player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and #target.player_cards[Player.Hand] >= #player.player_cards[Player.Hand]
      end
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
    if event == fk.EventPhaseStart then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player.player_cards[Player.Hand])
      player.room:obtainCard(target, dummy, false, fk.ReasonGive)
    else
      player:drawCards(2, self.name)
    end
  end,
}
local liejie = fk.CreateTriggerSkill{
  name = "liejie",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if data.from and not data.from.dead and not data.from:isNude() then
      prompt = "#liejie-cost::"..data.from.id
    else
      prompt = "#liejie-invoke"
    end
    local cards = player.room:askForDiscard(player, 1, 3, true, self.name, true, ".", prompt)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = self.cost_data
    player:drawCards(#cards, self.name)
    if data.from and not data.from.dead and not data.from:isNude() then
      local n = 0
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).color == Card.Red then
          n = n + 1
        end
      end
      if n == 0 then return end
      local room = player.room
      if room:askForSkillInvoke(player, self.name, data, "#liejie-discard::"..data.from.id..":"..n) then
        local discard = room:askForCardsChosen(player, data.from, 1, n, "he", self.name)
        room:throwCard(discard, self.name, data.from, player)
      end
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
}

local guohuai = General(extension, "guohuaij", "jin", 3, 3, General.Female)
local zhefu = fk.CreateTriggerSkill{
  name = "zhefu",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive
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
    return target == player and player:hasSkill(self.name) and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets
    if data.damageDealt then
      targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id) return
        not data.damageDealt[id] and not room:getPlayerById(id):isKongcheng()
      end)
    else
      targets = TargetGroup:getRealTargets(data.tos)
    end
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
}

Fk:loadTranslationTable{
  ["ol__zhaoyan"] = "赵俨",
  ["tongxie"] = "同协",
  [":tongxie"] = "出牌阶段开始时，你可以令你与至多两名其他角色直到你的下回合开始称为“同协”角色，然后令其中手牌唯一最少的角色摸一张牌。<br>"..
  "当同协角色使用仅指定单一目标的【杀】结算后，其他同协角色可以依次对目标使用一张无距离限制的【杀】。<br>"..
  "当同协角色受到伤害时，本回合未失去过体力的其他同协角色可以防止此伤害并失去1点体力。",
}

local zhouchu = General(extension, "ol__zhouchu", "jin", 4)
local shanduan = fk.CreateTriggerSkill{
  name = "shanduan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
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
      local choice = room:askForChoice(player, choices, self.name, "#shanduan"..(player.phase - 3).."-choice")
      room:setPlayerMark(player, "shanduan"..(player.phase - 3).."-phase", tonumber(choice))
      table.removeOne(nums, tonumber(choice))
      table.sort(nums)
      room:setPlayerMark(player, self.name, nums)
      if player.phase == Player.Play then
        choice = room:askForChoice(player, table.map(nums, function (i) return tostring(i) end), self.name, "#shanduan4-choice")
        room:setPlayerMark(player, "shanduan4-phase", tonumber(choice))
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
        return player:getMark("shanduan1-phase") > 0
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
      data.n = data.n + player:getMark("shanduan1-phase") - 2
    end
  end,
}
local shanduan_attackrange = fk.CreateAttackRangeSkill{
  name = "#shanduan_attackrange",
  correct_func = function(self, from, to)
    if from:getMark("shanduan2-phase") > 0 then
      return from:getMark("shanduan2-phase") - 1
    end
    return 0
  end,
}
local shanduan_targetmod = fk.CreateTargetModSkill{
  name = "#shanduan_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("shanduan4-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("shanduan4-phase") - 1
    end
    return 0
  end,
}
local shanduan_maxcards = fk.CreateMaxCardsSkill{
  name = "#shanduan_maxcards",
  fixed_func = function(self, player)
    if player:getMark("shanduan3-phase") > 0 then
      return player:getMark("shanduan3-phase")
    end
  end,
}
local yilie = fk.CreateViewAsSkill{
  name = "yilie",
  pattern = ".|.|.|.|.|basic|.",
  interaction = function()
    local names = {}
    local mark = Self:getMark("yilie-round")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and
        ((Fk.currentResponsePattern == nil and card.skill:canUse(Self)) or
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
  "摸牌阶段开始时，你选择本阶段摸牌数；出牌阶段开始时，你选择本阶段攻击范围、使用【杀】次数上限；弃牌阶段开始时，你选择本阶段手牌上限。<br>"..
  "当你于回合外受到伤害后，你下回合分配数值中的最小值+1。",
  ["yilie"] = "义烈",
  [":yilie"] = "你可以将两张颜色相同的手牌当一张本轮未以此法使用过的基本牌使用。",
  ["#shanduan1-choice"] = "善断：选择摸牌阶段摸牌数",
  ["#shanduan2-choice"] = "善断：选择攻击范围",
  ["#shanduan3-choice"] = "善断：选择手牌上限",
  ["#shanduan4-choice"] = "善断：选择使用【杀】次数上限",
}

Fk:loadTranslationTable{
  ["caoxiancaohua"] = "曹宪曹华",
  ["huamu"] = "化木",
  [":huamu"] = "当你使用与本回合上一张使用的牌颜色不同的手牌后，你可以将之置于你的武将牌上，黑色牌称为「灵杉」，红色牌称为「玉树」。",
  ["qianmeng"] = "前盟",
  [":qianmeng"] = "锁定技，当一名角色的「灵杉」「玉树」数量变化后，若两者相等或一项为0，你摸一张牌。",
  ["liangyuan"] = "良缘",
  [":liangyuan"] = "每轮各限一次，你可以将全场所有「灵杉」当【酒】、「玉树」当【桃】使用。",
  ["jisi"] = "羁肆",
  [":jisi"] = "限定技，准备阶段，你可以令一名角色获得你武将牌上发动过的一个技能，然后你弃置所有手牌并视为对其使用一张【杀】。",
}

local wangyan = General(extension, "wangyan", "jin", 3)
local yangkuang = fk.CreateTriggerSkill{
  name = "yangkuang",
  anim_type = "control",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#yangkuang-invoke"
    if room.current and not room.current.dead then
      prompt = "#yangkuang2-invoke::"..room.current.id
    end
    return room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useVirtualCard("analeptic", nil, player, player, self.name)
    player:drawCards(1, self.name)
    if room.current and not room.current.dead then
      room.current:drawCards(1, self.name)
    end
  end,
}
local cihuang_active = fk.CreateActiveSkill{
  name = "cihuang_active",
  card_num = 1,
  target_num = 0,
  interaction = function()
    local names = {}
    local mark = Self:getMark("cihuang-round")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if mark == 0 or (not table.contains(mark, card.name)) then
        if Self.phase == Player.NotActive then
          if (card.trueName == "slash" and card.name ~= "slash") or
            (card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick and card.skill.target_num == 1) then  --FIXME：衍生牌
            table.insertIfNeed(names, card.name)
          end
        else
          if table.contains({"ex_nihilo", "fire_attack", "foresight"}, card.name) then
            table.insertIfNeed(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(to_select)
    return #selected == 0
  end,
}
local cihuang = fk.CreateTriggerSkill{
  name = "cihuang",
  anim_type = "control",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.room:getPlayerById(data.from).phase ~= Player.NotActive and
      data.tos and #data.tos == 1 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local command = "AskForUseActiveSkill"
    room:notifyMoveFocus(player, "cihuang_active")
    local data = {"cihuang_active", "#cihuang-invoke::"..data.from, true, json.encode({})}
    local result = room:doRequest(player, command, json.encode(data))
    if result == "" then return false end
    data = json.decode(result)
    self.cost_data = {
      cards = json.decode(data.card).subcards,
      interaction_data = data.interaction_data,
    }
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(self.cost_data.interaction_data)
    card:addSubcards(self.cost_data.cards)
    room:useCard{
      from = player.id,
      tos = {{room.current.id}},
      card = card,
      disresponsiveList = table.map(room.alive_players, function(p) return p.id end),
    }
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("cihuang-round")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card.name)
    player.room:setPlayerMark(player, "cihuang-round", mark)
  end,
}
local sanku = fk.CreateTriggerSkill{
  name = "sanku",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.MaxHpChanged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      return event == fk.EnterDying or (event == fk.MaxHpChanged and data.num > 0)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      room:changeMaxHp(player, -1)
      if not player.dead then
        room:recover({
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = self.name
        })
      end
    else
      player.maxHp = player.maxHp - data.num
      room:broadcastProperty(player, "maxHp")  --FIXME: 没有相关时机，此法会触发相关技能（eg威重）
    end
  end,
}
Fk:addSkill(cihuang_active)
wangyan:addSkill(yangkuang)
wangyan:addSkill(cihuang)
wangyan:addSkill(sanku)
Fk:loadTranslationTable{
  ["wangyan"] = "王衍",
  ["yangkuang"] = "阳狂",
  [":yangkuang"] = "当你回复体力至上限后，你可以视为使用一张【酒】并与当前回合角色各摸一张牌。",
  ["cihuang"] = "雌黄",
  [":cihuang"] = "当前回合角色对唯一目标使用的牌被抵消后，你可以将一张牌当一张本轮你未使用过的属性【杀】或单一目标普通锦囊牌对使用者使用且此牌不能被响应。",
  ["sanku"] = "三窟",
  [":sanku"] = "锁定技，当你进入濒死状态时，你减1点体力上限并回复体力至上限；当你的体力上限增加时，你防止之。",
  ["#yangkuang-invoke"] = "阳狂：你可以视为使用【酒】并摸一张牌",
  ["#yangkuang2-invoke"] = "阳狂：你可以视为使用【酒】并与 %dest 各摸一张牌",
  ["#cihuang-invoke"] = "雌黄：选择一张牌，将之当属性【杀】或单目标锦囊对 %dest 使用",
}

--霍峻2022.10.21
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
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not data.chain and
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
    if player:hasSkill(self.name) and player.room.current ~= player and player.room.current.phase == Player.Play and
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
    if player:hasSkill(self.name) then
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
}

local xiahouxuan = General(extension, "xiahouxuan", "wei", 3)
local huanfu = fk.CreateTriggerSkill{
  name = "huanfu",
  anim_type = "drawcard",
  events ={fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and not player:isNude()
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
  card_filter = function(self, to_select, selected)
    return false
  end,
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
          id = table.random(p:getCardIds{Player.Hand, Player.Equip})
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:usedSkillTimes("qingyix") > 0
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
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
    local choice = room:askForChoice(player, skills, self.name)
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
  on_cost = function(self, event, target, player, data)
    return true
  end,
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
  ["#zeyue_record"] = "迮阅",
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
  card_filter = function()
    return false
  end,
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
    if player:hasSkill(self.name) and
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
    local success, dat = player.room:askForUseViewAsSkill(player, "bixin_viewas", "#bixin-invoke", true)
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
    local choice = room:askForChoice(player, types, self.name, "#bixin-choice")
    room:addPlayerMark(player, "bixin_"..choice, 1)
    player:drawCards(3, self.name)
    local cards = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      if Fk:getCardById(id):getTypeString() == choice then
        table.insert(cards, id)
      end
    end
    if #cards == 0 then
      player:addSkillUseHistory("ximo", 1)  --FIXME: 耦了耦了
      room:broadcastSkillInvoke("ximo")
      room:notifySkillInvoked(player, "ximo")
      for _, type in ipairs({"basic", "trick", "equip"}) do
        room:setPlayerMark(player, "bixin_"..type, 0)
      end
      if player:usedSkillTimes("ximo", Player.HistoryGame) > 2 then
        room:handleAddLoseSkills(player, "-ximo|feibai", nil, true, false)
        room:handleAddLoseSkills(player, "-bixin|bixinEx", nil, false, true)
      end
      return
    end
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
  card_filter = function()
    return false
  end,
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
    return target == player and player:hasSkill(self.name, true) and table.contains(data.card.skillNames, "bixin")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    for _, type in ipairs({"basic", "trick", "equip"}) do
      if player:getMark("bixin_"..type) < 3 then
        table.insert(types, type)
      end
    end
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
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and table.contains(data.card.skillNames, "bixin")
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
    if player:hasSkill(self.name) then
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
}

Fk:loadTranslationTable{
  ["godsunquan"] = "神孙权",
  ["yuheng"] = "驭衡",
  [":yuheng"] = "锁定技，回合开始时，你弃置任意张花色不同的牌，随机获得等量吴势力角色的技能。回合结束时，你失去以此法获得的技能，摸等量张牌。",
  ["dili"] = "帝力",
  [":dili"] = "觉醒技，当你的技能数超过体力上限后，你减少1点体力上限，失去任意个其他技能并获得〖圣质〗〖权道〗〖持纲〗中的前等量个。",
  ["shengzhi"] = "圣质",
  [":shengzhi"] = "锁定技，当你发动非锁定技后，你本回合使用的下一张牌无距离和次数限制。",
  ["quandao"] = "权道",
  [":quandao"] = "锁定技，当你使用【杀】或普通锦囊牌时，你将手牌中两者数量弃至相同并摸一张牌。",
  ["chigang"] = "持纲",
  [":chigang"] = "转换技，锁定技，阳：你的判定阶段改为摸牌阶段；阴：你的判定阶段改为出牌阶段。",
}

local ahuinan = General(extension, "ahuinan", "qun", 4)
local jueman = fk.CreateTriggerSkill{
  name = "jueman",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
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
          return not player:isProhibited(p, Fk:cloneCard(name)) end), function(p) return p.id end)
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
    return player:hasSkill(self.name) and data.card.type == Card.TypeBasic and not table.contains(data.card.skillNames, self.name)
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
}

return extension
