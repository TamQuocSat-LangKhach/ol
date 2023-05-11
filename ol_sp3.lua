local extension = Package("ol_sp3")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp3"] = "OL专属3",
  ["olz"] = "宗族",
}

Fk:loadTranslationTable{
  ["sp__menghuo"] = "孟获",
  ["manwang"] = "蛮王",
  [":manwang"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。",
  ["panqin"] = "叛侵",
  [":panqin"] = "出牌和弃牌阶段结束时，你可以将弃牌堆中你本阶段弃置的牌当【南蛮入侵】使用，若此牌目标数不小于这些牌的数量，你执行并移除〖蛮王〗的最后一项。",
}

Fk:loadTranslationTable{
  ["ruiji"] = "芮姬",
  ["qiaoli"] = "巧力",
  [":qiaoli"] = "出牌阶段各限一次，1.你可以将一张武器牌当【决斗】使用，此牌对目标角色造成伤害后，你摸与之攻击范围等量张牌，然后可以分配其中任意张牌；2.你可以将一张非武器装备牌当【决斗】使用且不能被响应，然后于结束阶段随机获得一张装备牌。",
  ["qingliang"] = "清靓",
  [":qingliang"] = "每回合限一次，当你成为其他角色使用的【杀】或伤害锦囊牌的唯一目标时，你可以展示所有手牌并选择一项：1.你与其各摸一张牌；2.弃器一种花色的所有手牌，取消此目标。",
}

local wangxiang = General(extension, "wangxiang", "jin", 3)
local bingxin = fk.CreateViewAsSkill{
  name = "bingxin",
  pattern = ".|.|.|.|.|basic|.",
  interaction = function()
    local names = {}
    local mark = Self:getMark("bingxin-turn")
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
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = Fk:currentRoom()
    local mark = player:getMark("bingxin-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    room:setPlayerMark(player, "bingxin-turn", mark)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    local cards = player.player_cards[Player.Hand]
    return #cards == player.hp and (player.dying or
      (table.every(cards, function (id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)))
  end,
  enabled_at_response = function(self, player, response)
    local cards = player.player_cards[Player.Hand]
    return not response and #cards == player.hp and (player.dying or
    (table.every(cards, function (id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)))
  end,
}
wangxiang:addSkill(bingxin)
Fk:loadTranslationTable{
  ["wangxiang"] = "王祥",
  ["bingxin"] = "冰心",
  [":bingxin"] = "若你手牌的数量等于体力值且颜色相同，你可以摸一张牌视为使用一张与本回合以此法使用过的牌牌名不同的基本牌。",
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
    local room = target.room
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and data.card.type == Card.TypeBasic
  end,
  on_cost = function(self, event, target, player, data)
    local targets = {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if not p:isKongcheng() then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#zhefu-choose", self.name, true)
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
    return target == player and player:hasSkill(self.name) and data.card.is_damage_card and #TargetGroup:getRealTargets(data.tos) == 1 and
      not (data.card.extra_data and table.contains(data.card.extra_data, self.name)) and
      not player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1]):isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yidu-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    local cards = room:askForCardsChosen(player, to, 1, math.min(3, #to.player_cards[Player.Hand]), "h", self.name)
    to:showCards(cards)
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).color ~= Fk:getCardById(cards[1]).color then
        return
      end
    end
    room:throwCard(cards, self.name, to, player)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card
  end,
  on_refresh = function(self, event, target, player, data)
    data.card.extra_data = data.card.extra_data or {}
    table.insertIfNeed(data.card.extra_data, self.name)
  end,
}
guohuai:addSkill(zhefu)
guohuai:addSkill(yidu)
Fk:loadTranslationTable{
  ["guohuaij"] = "郭槐",
  ["zhefu"] = "哲妇",
  [":zhefu"] = "当你于回合外使用或打出一张基本牌后，你可以令一名有手牌的其他角色选择弃置一张同名基本牌或受到你的1点伤害。",
  ["yidu"] = "遗毒",
  [":yidu"] = "当你使用仅指定唯一目标的【杀】或伤害锦囊牌后，若此牌未对其造成伤害，你可以展示其至多三张手牌，若颜色均相同，其弃置这些牌。",
  ["#zhefu-choose"] = "哲妇：你可以指定一名角色，其弃置一张同名牌或受到你的1点伤害",
  ["#zhefu-discard"] = "哲妇：你需弃置一张【%arg】，否则 %dest 对你造成1点伤害",
  ["#yidu-invoke"] = "遗毒：你可以展示 %dest 至多三张手牌，若颜色相同则全部弃置",
}

--赵俨2022.8.14
--周处 曹宪曹华2022.9.6
--王衍2022.9.29
--霍峻 邓忠2022.10.21
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
      room:obtainCard(player, id, true, fk.ReasonPrey)
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
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          self.cost_data = {}
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "slash" then
              table.insert(self.cost_data, info.cardId)
            end
          end
          return #self.cost_data > 0
        end
      end
    end
    return
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    if #cards == 1 then
      room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    else
      room:fillAG(player, cards)
      local id = room:askForAG(player, cards, false, self.name)
      if id == nil then
        id = table.random(cards)
      end
      room:closeAG(player)
      room:obtainCard(player, id, true, fk.ReasonJustMove)
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
  [":gengzhan"] = "其他角色出牌阶段限一次，当一张【杀】因弃置置入弃牌堆后，你可以获得之。其他角色的结束阶段，若其本回合未使用过【杀】，你下个出牌阶段使用【杀】的限制次数+1。",
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
    player.room:setPlayerMark(player, self.name, self.cost_data)
    data.card.extra_data = data.card.extra_data or {}
    table.insert(data.card.extra_data, self.name)
  end,

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true) and data.card and data.card.extra_data and table.contains(data.card.extra_data, self.name) then
      if event == fk.Damage then
        return not data.chain
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "huanfu2", data.damage)
    else
      if player:getMark(self.name) == player:getMark("huanfu2") then
        player:drawCards(2*player:getMark(self.name), self.name)
      end
      room:setPlayerMark(player, self.name, 0)
      room:setPlayerMark(player, "huanfu2", 0)
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
      room:obtainCard(player, dummy, true, fk.ReasonJustMove)
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
          if p:hasSkill(skill, true) and skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Wake and skill.frequency ~= Skill.Limited then
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
      if not skill.attached_equip and skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Wake and skill.frequency ~= Skill.Limited then
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
  [":huanfu"] = "当你使用【杀】指定目标或成为【杀】的目标后，你可以弃置任意张牌（至多为你的体力上限），若此【杀】对目标角色造成的伤害值为弃牌数，你摸弃牌数两倍的牌。",
  ["qingyix"] = "清议",
  [":qingyix"] = "出牌阶段限一次，你可以与至多两名有牌的其他角色同时弃置一张牌，若类型相同，你可以重复此流程。结束阶段，你可以获得其中颜色不同的牌各一张。",
  ["zeyue"] = "迮阅",
  [":zeyue"] = "限定技，准备阶段，你可以令一名你上个回合结束后（首轮为游戏开始后）对你造成过伤害的其他角色失去武将牌上一个技能（锁定技、觉醒技、限定技除外）。每轮结束时，其视为对你使用X张【杀】（X为其已失去此技能的轮数），若此【杀】造成伤害，其获得以此法失去的技能。",
  ["#huanfu-invoke"] = "宦浮：你可以弃置至多%arg张牌，若此【杀】造成伤害值等于弃牌数，你摸两倍的牌",
  ["#qingyi-discard"] = "清议：弃置一张牌",
  ["#qingyi-invoke"] = "清议：是否继续发动“清议”？",
  ["#qingyix_record"] = "清议",
  ["#zeyue-choose"] = "迮阅：你可以令一名角色失去一个技能，其每轮视为对你使用【杀】，造成伤害后恢复失去的技能",
  ["#zeyue_record"] = "迮阅",
}
--张芝2022.11.19

local olz__xunchen = General(extension, "olz__xunchen", "qun", 3)
local sankuang = fk.CreateTriggerSkill{
  name = "sankuang",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local mark = "sankuang_"..data.card:getTypeString().."-round"
      if player:getMark(mark) == 0 then
        player.room:addPlayerMark(player, mark, 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      local n = 0
      if #p:getCardIds{Player.Equip, Player.Judge} > 0 then n = n + 1 end
      if p:isWounded() then n = n + 1 end
      if p.hp < #p.player_cards[Player.Hand] then n = n + 1 end
      p.tag["sankuang"] = n  --TODO: show target's sankuang_num when targeting
      if #p:getCardIds{Player.Hand, Player.Equip} >= n then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#sankuang-choose:::"..data.card:toLogString(), self.name)
      if #to == 0 then
        to = {table.random(targets)}
      end
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if player.tag["beishi"] == nil then
      player.tag["beishi"] = to.id
    end
    local n = to.tag["sankuang"]
    if n > 0 then
      local cards = room:askForCard(to, n, #to:getCardIds{Player.Hand, Player.Equip}, true, self.name, false, ".", "#sankuang-give:::"..tostring(n))
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, false, fk.ReasonGive)
    end
    if room:getCardArea(data.card) == Card.PlayerEquip or room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(to, data.card, true, fk.ReasonPrey)
    end
  end,
}
local beishi = fk.CreateTriggerSkill{
  name = "beishi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:isWounded() and player.tag["beishi"] then
      for _, move in ipairs(data) do
        if move.from == player.tag["beishi"] and player.room:getPlayerById(move.from):isKongcheng() then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,
}
local daojie = fk.CreateTriggerSkill{
  name = "daojie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("daojie-turn") == 0 and
      data.card.type == Card.TypeTrick and not data.card.is_damage_card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "daojie-turn", 1)
    local skills = {"Cancel"}
    for _, skill in ipairs(player.player_skills) do
      if skill.frequency == Skill.Compulsory and not skill.attached_equip then
        table.insert(skills, skill.name)
      end
    end
    local choice = room:askForChoice(player, skills, self.name)
    if choice == "Cancel" then
      room:loseHp(player, 1, self.name)
    else
      room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
      if room:getCardArea(data.card) == Card.Processing then
        local targets = {}
        for _, p in ipairs(room:getAlivePlayers()) do
          if string.find(p.general, "olz__xun") then
            table.insert(targets, p.id)
          end
        end
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#daojie-choose:::"..data.card:toLogString(), self.name)
        if #to == 0 then
          to = {table.random(targets)}
        end
        room:obtainCard(to[1], data.card, true, fk.ReasonPrey)
      end
    end
  end,
}
olz__xunchen:addSkill(sankuang)
olz__xunchen:addSkill(beishi)
olz__xunchen:addSkill(daojie)
Fk:loadTranslationTable{
  ["olz__xunchen"] = "荀谌",
  ["sankuang"] = "三恇",
  [":sankuang"] = "锁定技，当你每轮首次使用一种类别的牌后，你令一名其他角色交给你至少X张牌并获得你使用的牌（X为其满足的项数：1.场上有牌；2.已受伤；3.体力值小于手牌数）。",
  ["beishi"] = "卑势",
  [":beishi"] = "锁定技，当你首次发动〖三恇〗选择的角色失去最后的手牌后，你回复1点体力。",
  ["daojie"] = "蹈节",
  [":daojie"] = "宗族技，锁定技，当你每回合首次使用非伤害锦囊牌后，你选择一项：1.失去1点体力；2.失去一个锁定技，然后令一名同族角色获得此牌。",
  ["#sankuang-choose"] = "三恇：令一名其他角色交给你至少X张牌并获得你使用的%arg",
  ["#sankuang-give"] = "三恇：你须交给其%arg张牌",
  ["#daojie-choose"] = "蹈节：令一名同族角色获得此%arg",
}

Fk:loadTranslationTable{
  ["olz__xunshu"] = "荀淑",
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有同名手牌记为「神君」，本阶段结束时，你可以将X张牌当任意「神君」牌使用（X为「神君」牌数）。",
  ["balong"] = "八龙",
  [":balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类型，你展示手牌并摸至与存活角色数相同。",
}

local xuncan = General(extension, "olz__xuncan", "wei", 3)
local yushen = fk.CreateActiveSkill{
  name = "yushen",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):isWounded() and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player.tag["fenchai"] == nil and player.gender ~= target.gender then
      player.tag["fenchai"] = target.id
    end
    room:recover({
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    local choice = room:askForChoice(player, {"yushen1", "yushen2"}, self.name)
    if choice == "yushen1" then
      room:useVirtualCard("ice__slash", nil, target, player, self.name, true)
    else
      room:useVirtualCard("ice__slash", nil, player, target, self.name, true)
    end
   end
}
local shangshen = fk.CreateTriggerSkill{
  name = "shangshen",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and not target.dead and data.damageType ~= fk.NormalDamage then
      if player:getMark("shangshen-turn") == 0 then
        player.room:addPlayerMark(player, "shangshen-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#shangshen-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.tag["fenchai"] == nil and player.gender ~= target.gender then
      player.tag["fenchai"] = target.id
    end
    local judge = {
      who = player,
      reason = "lightning",
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and judge.card.number >= 2 and judge.card.number <= 9 then
      room:damage{
        to = player,
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
    local n = 4 - #target.player_cards[Player.Hand]
    if n > 0 then
      target:drawCards(n, self.name)
    end
  end,
}
local fenchai = fk.CreateTriggerSkill{
  name = "fenchai",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.FinishRetrial},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.tag["fenchai"]
  end,
  on_use = function(self, event, target, player, data)
    if player.room:getPlayerById(player.tag["fenchai"]).dead then
      data.card.suit = Card.Spade
    else
      data.card.suit = Card.Heart
    end
  end,
}
xuncan:addSkill(yushen)
xuncan:addSkill(shangshen)
xuncan:addSkill(fenchai)
xuncan:addSkill("daojie")
Fk:loadTranslationTable{
  ["olz__xuncan"] = "荀粲",
  ["yushen"] = "熨身",
  [":yushen"] = "出牌阶段限一次，你可以选择一名其他角色并令其回复1点体力，然后选择一项：1.视为其对你使用一张冰【杀】；2.视为你对其使用一张冰【杀】。",
  ["shangshen"] = "伤神",
  [":shangshen"] = "当每回合首次有角色受到属性伤害后，你可以进行一次【闪电】判定并令其将手牌摸至四张。",
  ["fenchai"] = "分钗",
  [":fenchai"] = "锁定技，若首次成为你技能目标的异性角色存活，你的判定牌视为<font color='red'>♥</font>，否则视为♠。",
  ["#shangshen-invoke"] = "伤神：你可以进行一次【闪电】判定并令 %dest 将手牌摸至四张",
  ["yushen1"] = "视为其对你使用冰【杀】",
  ["yushen2"] = "视为你对其使用冰【杀】",
}

Fk:loadTranslationTable{
  ["olz__xuncai"] = "荀采",
  ["lieshi"] = "烈誓",
  [":lieshi"] = "出牌阶段，你可以选择一项：1.废除判定区并受到你的1点火焰伤害；2.弃置所有【闪】；3.弃置所有【杀】。然后令一名其他角色选择其他两项中的一项。",
  ["dianzhan"] = "点盏",
  [":dianzhan"] = "锁定技，当你每轮首次使用一种花色的牌后，你横置此牌唯一目标并重铸此花色的所有手牌，然后若你以此法横置了角色且你以此法重铸了牌，你摸一张牌。",
  ["huanyin"] = "还阴",
  [":huanyin"] = "锁定技，当你进入濒死状态时，你将手牌摸至4张。",
}
--神孙权（制衡技能版）

local olz__wuban = General(extension, "olz__wuban", "shu", 4)
local zhanding = fk.CreateViewAsSkill{
  name = "zhanding",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return true
  end,
  view_as = function(self, cards)
    if #cards == 0 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    if player:getMaxCards() > 0 then
      Fk:currentRoom():addPlayerMark(player, "MinusMaxCards", 1)  --TODO: this global MaxCardsSkill is in tenyear_sp, move it
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self.name) and not response
  end,
}
local zhanding_record = fk.CreateTriggerSkill{
  name = "#zhanding_record",
  anim_type = "offensive",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "zhanding")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "zhanding")
    else
      if data.card.extra_data and table.contains(data.card.extra_data, "zhanding") then
        local n = #player.player_cards[Player.Hand] - player:getMaxCards()
        if n < 0 then
          player:drawCards(-n, self.name)
        elseif n > 0 then
          player.room:askForDiscard(player, n, n, false, self.name, false)
        end
      else
        player:addCardUseHistory(data.card.trueName, -1)
      end
    end
  end,
}
local muyin = fk.CreateTriggerSkill{
  name = "muyin",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      self.muyin_tos = {}
      local n = player:getMaxCards()
      for _, p in ipairs(player.room:getAlivePlayers()) do
        if p:getMaxCards() > n then
          n = p:getMaxCards()
        end
      end
      for _, p in ipairs(player.room:getAlivePlayers()) do
        if string.find(p.general, "olz__wu") and p:getMaxCards() < n then
          table.insert(self.muyin_tos, p.id)
        end
      end
      return #self.muyin_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.muyin_tos, 1, 1, "#muyin-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), "AddMaxCards", 1)
  end,
}
zhanding:addRelatedSkill(zhanding_record)
olz__wuban:addSkill(zhanding)
olz__wuban:addSkill(muyin)
Fk:loadTranslationTable{
  ["olz__wuban"] = "吴班",
  ["zhanding"] = "斩钉",
  [":zhanding"] = "你可以将任意张牌当【杀】使用并令你手牌上限-1，若此【杀】：造成伤害，你将手牌数调整至手牌上限；未造成伤害，此【杀】不计入次数。",
  ["muyin"] = "穆荫",
  [":muyin"] = "宗族技，准备阶段，你可以令一名手牌上限不为全场最大的同族角色手牌上限+1。",
  ["#muyin-choose"] = "穆荫：你可以令一名同族角色手牌上限+1",
}

local olz__wuxian = General(extension, "olz__wuxian", "shu", 3, 3, General.Female)
local yirong = fk.CreateActiveSkill{
  name = "yirong",
  anim_type = "drawcard",
  target_num = 0,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 and #player.player_cards[Player.Hand] ~= player:getMaxCards()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = #player.player_cards[Player.Hand] - player:getMaxCards()
    if n < 0 then
      player:drawCards(-n, self.name)
      if player:getMaxCards() > 0 then
        room:addPlayerMark(player, "MinusMaxCards", 1)
      end
    elseif n > 0 then
      room:askForDiscard(player, n, n, false, self.name, false)
      room:addPlayerMark(player, "AddMaxCards", 1)
    end
  end,
}
local guixiang = fk.CreateTriggerSkill{
  name = "guixiang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.to > Player.RoundStart and data.to < Player.NotActive then
      player.room:addPlayerMark(player, "guixiang-turn", 1)
      return player:getMark("guixiang-turn") == player:getMaxCards()
    end
  end,
  on_use = function(self, event, target, player, data)
    data.to = Player.Play
  end,
}
olz__wuxian:addSkill(yirong)
olz__wuxian:addSkill(guixiang)
olz__wuxian:addSkill("muyin")
Fk:loadTranslationTable{
  ["olz__wuxian"] = "吴苋",
  ["yirong"] = "移荣",
  [":yirong"] = "出牌阶段限两次，你可以将手牌摸/弃至手牌上限并令你手牌上限-1/+1。",
  ["guixiang"] = "贵相",
  [":guixiang"] = "锁定技，你回合内第X个阶段改为出牌阶段（X为你的手牌上限）。",
}
--阿会喃 胡班2023.1.13
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

--傅肜2023.2.4
--刘巴2023.2.25
--族：韩韶 韩融
--[[local hanshao = General(extension, "olz__hanshao", "qun", 3)
local xumin = fk.CreateActiveSkill{
  name = "xumin",
  anim_type = "support",
  card_num = 1,
  min_target_num = 1,
  max_target_num = 999,
  can_use = function(self, player)
    return not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local card = Fk:cloneCard("amazing_grace")
    card:addSubcards(effect.cards)
    card.skillName = self.name
    local tos = {}
    for _, id in ipairs(effect.tos) do
      table.insert(tos, {id})
    end
    room:useCard{
      from = effect.from,
      tos = tos,
      card = card,
    }
  end,
}
hanshao:addSkill(liuju)
hanshao:addSkill(xumin)]]--
Fk:loadTranslationTable{
  ["olz__hanshao"] = "韩韶",
  ["fangzhen"] = "放赈",
  [":fangzhen"] = "出牌阶段开始时，你可以横置一名角色并选择一项：1.摸两张牌并交给其两张牌；2.令其回复1点体力。第X轮开始时（X为其座次），你失去此技能。",
  ["liuju"] = "留驹",
  [":liuju"] = "出牌阶段结束时，你可以与一名角色拼点，输的角色可以使用拼点牌中的非基本牌。若你与其的相互距离因此变化，你复原〖恤民〗。",
  ["xumin"] = "恤民",
  [":xumin"] = "宗族技，限定技，你可以将一张牌当【五谷丰登】对任意名其他角色使用。",
}
Fk:loadTranslationTable{
  ["olz__hanrong"] = "韩融",
  ["lianhe"] = "连和",
  [":lianhe"] = "出牌阶段开始时，你可以横置两名角色，其下个出牌阶段结束时，若其此阶段未摸牌，其选择一项：1.令你摸X+1张牌；2.交给你X-1张牌（X为其此阶段获得牌数且至多为3）。",
  ["huanjia"] = "缓颊",
  [":huanjia"] = "出牌阶段结束时，你可以与一名角色拼点，赢的角色可以使用一张拼点牌，若其：未造成伤害，你获得另一张拼点牌；造成了伤害，你失去一个技能。",
}
--马承2023.3.26

local quhuang = General(extension, "quhuang", "wu", 3)
local qiejian = fk.CreateTriggerSkill{
  name = "qiejian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("qiejian-turn") == 0 then
      for _, move in ipairs(data) do
        if move.from and player.room:getPlayerById(move.from):isKongcheng() and not player.room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              self.cost_data = move.from
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    player:drawCards(1, self.name)
    to:drawCards(1, self.name)
    local choices = {"qiejian_nulli"}
    if #player:getCardIds{Player.Equip, Player.Judge} > 0 or #to:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(choices, 1, "qiejian_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "qiejian_discard" then
      local targets = {}
      if #player:getCardIds{Player.Equip, Player.Judge} > 0 then table.insertIfNeed(targets, player.id) end
      if #to:getCardIds{Player.Equip, Player.Judge} > 0 then table.insertIfNeed(targets, to.id) end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#qiejian-choose", self.name)
      local p
      if #tos > 0 then
        p = room:getPlayerById(tos[1])
      else
        p = room:getPlayerById(table.random(targets))
      end
      local id = room:askForCardChosen(player, p, 'ej', self.name)
      room:throwCard({id}, self.name, p, player)
    else
      room:addPlayerMark(player, "qiejian-turn", 1)
    end
  end,
}
local nishou = fk.CreateTriggerSkill{
  name = "nishou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              self.cost_data = info.cardId
              return not player:hasDelayedTrick("lightning") or player:getMark(self.name) == 0
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if not player:hasDelayedTrick("lightning") then
      table.insert(choices, "nishou_lightning")
    end
    if player:getMark(self.name) == 0 then
      table.insert(choices, "nishou_nulli")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "nishou_lightning" then
      local card = Fk:cloneCard("lightning")
      card:addSubcards({self.cost_data})
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    else
      room:addPlayerMark(player, self.name, 1)  --ATTENTION: this mark shouldn't end with "-phase"!
    end
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) > 0 and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    local n = #player.player_cards[Player.Hand]
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] < n then
        n = #p.player_cards[Player.Hand]
      end
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] == n then
        table.insert(targets, p.id)
      end
    end
    local to
    if #targets == 0 then
      return
    elseif #targets == 1 then
      to = targets[1]
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#nishou-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
    end
    local cards1 = table.clone(player.player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(to).player_cards[Player.Hand])
    local move1 = {
      from = player.id,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,  --FIXME: this is still visible! same problem with dimeng!
    }
    local move2 = {
      from = to,
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = cards1,
      fromArea = Card.Processing,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    local move4 = {
      ids = cards2,
      fromArea = Card.Processing,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move3, move4)
  end,
}
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去最后的手牌后，你可以与其各摸一张牌，然后选择一项：1.弃置你或其场上一张牌；2.本回合本技能失效。",
  ["nishou"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将第一张装备牌当【闪电】使用；2.本阶段结束时与手牌数最少的角色交换手牌，然后本阶段内你无法选择本项。",
  ["qiejian_discard"] = "弃置你或其场上一张牌",
  ["qiejian_nulli"] = "本回合本技能失效",
  ["#qiejian-choose"] = "切谏：弃置你或其场上一张牌",
  ["nishou_lightning"] = "将第一张装备牌当【闪电】使用",
  ["nishou_nulli"] = "本阶段无法选择本项，本阶段结束时你与手牌数最少的角色交换手牌",
  ["#nishou-choose"] = "泥首：你需与手牌数最少的角色交换手牌",
}

local zhanghua = General(extension, "zhanghua", "jin", 3)
local bihun = fk.CreateTriggerSkill{
  name = "bihun",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #player.player_cards[Player.Hand] > player:getMaxCards() and data.firstTarget and
      #AimGroup:getAllTargets(data.tos) > 0 and
      not table.every(AimGroup:getAllTargets(data.tos), function(id) return id == player.id end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #AimGroup:getAllTargets(data.tos) == 1 and AimGroup:getAllTargets(data.tos)[1] ~= player.id and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(AimGroup:getAllTargets(data.tos)[1], data.card, true, fk.ReasonJustMove)
    end
    for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
      AimGroup:cancelTarget(data, id)
    end
  end,
}
local jianhe = fk.CreateActiveSkill{
  name = "jianhe",
  anim_type = "offensive",
  min_card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    else
      if Fk:getCardById(selected[1]).type == Card.TypeEquip then
        return Fk:getCardById(to_select).type == Card.TypeEquip
      end
      return Fk:getCardById(to_select).trueName == Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("jianhe-turn") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(target, "jianhe-turn", 1)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
    })
    local n = #effect.cards
    player:drawCards(n, self.name)
    if #target:getCardIds{Player.Hand, Player.Equip} < n then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      local type = Fk:getCardById(effect.cards[1]):getTypeString()
      local cards = room:askForCard(target, n, n, true, self.name, true, ".|.|.|.|.|"..type, "#jianhe-choose:::"..tostring(n))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          from = effect.tos[1],
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
        })
        target:drawCards(#cards, self.name)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end
}
local chuanwu = fk.CreateTriggerSkill{
  name = "chuanwu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local skills = table.map(Fk.generals[player.general].skills, function(s) return s.name end)
    for i = #skills, 1, -1 do
      if not player:hasSkill(skills[i], true) then
        table.removeOne(skills, skills[i])
      end
    end
    local to_lose = {}
    player.tag[self.name] = player.tag[self.name] or {}
    local n = math.min(player:getAttackRange(), #skills)
    for i = 1, n, 1 do
      if player:hasSkill(skills[i], true) then
        table.insert(to_lose, skills[i])
        table.insert(player.tag[self.name], skills[i])
      end
    end
    player.room:handleAddLoseSkills(player, "-"..table.concat(to_lose, "|-"), nil, true, false)
    player:drawCards(n, self.name)
  end,
}
local chuanwu_record = fk.CreateTriggerSkill{
  name = "#chuanwu_record",

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player.tag["chuanwu"]
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, table.concat(player.tag["chuanwu"], "|"), nil, true, false)
    player.tag["chuanwu"] = {}
  end,
}
chuanwu:addRelatedSkill(chuanwu_record)
zhanghua:addSkill(bihun)
zhanghua:addSkill(jianhe)
zhanghua:addSkill(chuanwu)
Fk:loadTranslationTable{
  ["zhanghua"] = "张华",
  ["bihun"] = "弼昏",
  [":bihun"] = "锁定技，当你使用牌指定其他角色为目标时，若你的手牌数大于手牌上限，你取消之并令唯一目标获得此牌。",
  ["jianhe"] = "剑合",
  [":jianhe"] = "出牌阶段每名角色限一次，你可以重铸至少两张同名牌或至少两张装备牌，令一名角色选择一项：1.重铸等量张与之类型相同的牌；2.受到你造成的1点雷电伤害。",
  ["chuanwu"] = "穿屋",
  [":chuanwu"] = "锁定技，当你造成或受到伤害后，你失去你武将牌上前X个技能直到回合结束（X为你的攻击范围），然后摸等同失去技能数张牌。",
  ["#jianhe-choose"] = "剑合：你需重铸%arg张相同类别的牌，否则受到1点雷电伤害",
}

local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
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
      self.cost_data = {}
      if n == 2 then
        for i = 1, 2, 1 do
          if player.tag[self.name][i][2].name ~= "jink" then
            table.insertIfNeed(self.cost_data, player.tag[self.name][i][2].name)
          end
        end
      elseif n == 1 then
        if player.tag[self.name][1][1] == player.id then
          self.cost_data = player.tag[self.name][2][1]
        else
          self.cost_data = player.tag[self.name][1][1]
        end
      else
        player.tag[self.name] = {}
        return
      end
      player.tag[self.name] = {}
      return self.cost_data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "number" then
      room:doIndicate(player.id, {self.cost_data})
      local to = room:getPlayerById(self.cost_data)
      if to:isNude() then return end
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard(card, self.name, to, player)
    else
      local name = room:askForChoice(player, self.cost_data, self.name, "#jianman-choice")
      local targets = {}
      if string.find(name, "slash") then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not player:isProhibited(p, Fk:cloneCard(name)) end), function(p) return p.id end)
      else
        targets = {player.id}
      end
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#jianman-choose:::"..name, self.name, false)
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
dongtuna:addSkill(jianman)
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["jianman"] = "鹣蛮",
  [":jianman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均为你，你视为使用其中的一张牌；仅其中之一为你，你弃置另一名使用者一张牌。",
  ["#jianman-choice"] = "选择视为使用的牌名",
  ["#jianman-choose"] = "鹣蛮：选择视为使用【%arg】的目标",
}

local zhangyi = General(extension, "ol__zhangyiy", "shu", 4)
local dianjun = fk.CreateTriggerSkill{
  name = "dianjun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player,
      damage = 1,
      skillName = self.name,
    }
    player:gainAnExtraPhase(Player.Play)
  end,
}
local kangrui = fk.CreateTriggerSkill{
  name = "kangrui",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase ~= Player.NotActive and not target.dead then
      if target:getMark("kangrui-turn") == 0 then
        player.room:addPlayerMark(target, "kangrui-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#kangrui-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local choice = room:askForChoice(target, {"recover", "kangrui_damage"}, self.name)
    if choice == "recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    else
      room:addPlayerMark(target, "kangrui_damage-turn", 1)
    end
  end,

  refresh_events = {fk.DamageCaused, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("kangrui_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      player.room:addPlayerMark(player, "MinusMaxCards-turn", 999)
      player.room:setPlayerMark(player, "kangrui_damage-turn", 0)
    end
  end,
}
zhangyi:addSkill(dianjun)
zhangyi:addSkill(kangrui)
Fk:loadTranslationTable{
  ["ol__zhangyiy"] = "张翼",
  ["dianjun"] = "殿军",
  [":dianjun"] = "锁定技，回合结束时，你受到1点伤害并执行一个额外的出牌阶段。",
  ["kangrui"] = "亢锐",
  [":kangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并令其：1.回复1点体力；2.本回合下次造成的伤害+1，然后当其造成伤害后，其此回合手牌上限改为0。",
  ["#kangrui-invoke"] = "亢锐：你可以摸一张牌，令 %dest 选择回复1点体力或本回合下次造成伤害+1",
  ["kangrui_damage"] = "本回合下次造成伤害+1，造成伤害后本回合手牌上限改为0",
}

local maxiumatie = General(extension, "maxiumatie", "qun", 4)
local kenshang = fk.CreateViewAsSkill{
  name = "kenshang",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return true
  end,
  view_as = function(self, cards)
    if #cards < 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local room = Fk:currentRoom()
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not player:isProhibited(p, use.card) end), function(p) return p.id end)
    local n = math.min(#targets, #use.card.subcards)
    local tos = room:askForChoosePlayers(player, targets, n, n, "#kenshang-choose:::"..n, self.name, false)
    if #tos > 0 then
      table.forEach(TargetGroup:getRealTargets(use.tos), function (id)
        TargetGroup:removeTarget(use.tos, id)
      end)
      for _, id in ipairs(tos) do
        TargetGroup:pushTargets(use.tos, id)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self.name) and not response
  end,
}
local kenshang_record = fk.CreateTriggerSkill{
  name = "#kenshang_record",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "kenshang")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "kenshang", data.damage)
    else
      if player:getMark("kenshang") > 0 then
        if #data.card.subcards > player:getMark("kenshang") then
          player:drawCards(1, "kenshang")
        end
        room:setPlayerMark(player, "kenshang", 0)
      end
    end
  end,
}
kenshang:addRelatedSkill(kenshang_record)
maxiumatie:addSkill("mashu")
maxiumatie:addSkill(kenshang)
Fk:loadTranslationTable{
  ["maxiumatie"] = "马休马铁",
  ["kenshang"] = "垦伤",
  [":kenshang"] = "你可以将至少两张牌当【杀】使用，然后目标可以改为等量的角色。你以此法使用的【杀】结算后，若这些牌数大于此牌造成的伤害，你摸一张牌。",
  ["#kenshang-choose"] = "垦伤：你可以将目标改为指定%arg名角色",
}

local zhujun = General(extension, "ol__zhujun", "qun", 4)
local cuipo = fk.CreateTriggerSkill{
  name = "cuipo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("@cuipo-turn") == #Fk:translate(data.card.trueName)/3
  end,
  on_use = function(self, event, target, player, data)
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@cuipo-turn", 1)
  end,
}
zhujun:addSkill(cuipo)
Fk:loadTranslationTable{
  ["ol__zhujun"] = "朱儁",
  ["cuipo"] = "摧破",
  [":cuipo"] = "锁定技，当你每回合使用第X张牌时（X为此牌牌名字数），若为【杀】或伤害锦囊牌，此牌伤害+1，否则你摸一张牌。",
  ["@cuipo-turn"] = "摧破",
}
--族吴匡 王瓘 2023.5.10

return extension
