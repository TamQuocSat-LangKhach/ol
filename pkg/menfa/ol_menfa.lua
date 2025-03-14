local extension = Package("ol_menfa")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_menfa"] = "OL-门阀士族",
}

local xunshu = General(extension, "olz__xunshu", "qun", 3)
local shenjun_viewas = fk.CreateViewAsSkill{
  name = "shenjun_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Self:getMark("@$shenjun")) do
      local name = Fk:getCardById(id).name
      if Self:canUse(Fk:cloneCard(name), { bypass_times = true }) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return U.CardNameBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected < #Self:getMark("@$shenjun")
  end,
  view_as = function(self, cards)
    if Self:getMark("@$shenjun") ~= 0 and #cards ~= #Self:getMark("@$shenjun") or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shenjun"
    return card
  end,
}
local shenjun = fk.CreateTriggerSkill{
  name = "shenjun",
  anim_type = "special",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.CardUsing then
        return (data.card.trueName == "slash" or data.card:isCommonTrick()) and not player:isKongcheng() and
          table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end)
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and type(player:getMark("@$shenjun")) == "table"
        and #player:getMark("@$shenjun") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return true
    else
      local room = player.room
      local success, dat = room:askForUseActiveSkill(player, "shenjun_viewas",
      "#shenjun-invoke:::"..#player:getMark("@$shenjun"), true, { bypass_times = true })
      if success then
        self.cost_data = dat
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == data.card.trueName end)
      player:showCards(cards)
      if player.dead then return end
      local mark = player:getMark("@$shenjun")
      if mark == 0 then mark = {} end
      for _, id in ipairs(cards) do
        if table.contains(player:getCardIds("h"), id) and not table.contains(mark, id) then
          table.insert(mark, id)
          room:setCardMark(Fk:getCardById(id), "@@shenjun-inhand", 1)
        end
      end
      room:setPlayerMark(player, "@$shenjun", mark)
    else
      local dat = table.simpleClone(self.cost_data)
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      card.skillName = "shenjun"
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return type(player:getMark("@$shenjun")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local handcards = player:getCardIds(Player.Hand)
    local cards = table.filter(player:getMark("@$shenjun"), function (id)
      return table.contains(handcards, id)
    end)
    player.room:setPlayerMark(player, "@$shenjun", #cards > 0 and cards or 0)
  end,
}
local balong = fk.CreateTriggerSkill{
  name = "balong",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.HpLost, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and not player:isKongcheng() then
      local x = player:getMark("balong_record-turn")
      local room = player.room
      local hp_event = room.logic:getCurrentEvent()
      if not hp_event or (x > 0 and x ~= hp_event.id) then return false end
      local types = {Card.TypeBasic, Card.TypeEquip, Card.TypeTrick}
      local num = {0, 0, 0}
      for i = 1, 3, 1 do
        num[i] = #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == types[i] end)
      end
      if num[3] <= num[1] or num[3] <= num[2] then return false end
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          if e.data[1] == player then
            local reason = e.data[3]
            local game_event = nil
            if reason == "damage" then
              game_event = GameEvent.Damage
            elseif reason == "loseHp" then
              game_event = GameEvent.LoseHp
            elseif reason == "recover" then
              game_event = GameEvent.Recover
            else
              return true
            end
            local first_event = e:findParent(game_event)
            if first_event then
              x = first_event.id
              room:setPlayerMark(player, "balong_record-round", x)
            end
            return true
          end
        end, Player.HistoryTurn)
      end
      return hp_event.id == x
    end
  end,
  on_use = function(self, event, target, player, data)
    player:showCards(player:getCardIds("h"))
    if player:getHandcardNum() < #player.room.alive_players and not player.dead then
      player:drawCards(#player.room.alive_players - player:getHandcardNum(), self.name)
    end
  end,
}
Fk:loadTranslationTable{
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有同名手牌记为“神君”，本阶段结束时，你可以将X张牌当任意“神君”牌使用（X为“神君”牌数）。",
  ["balong"] = "八龙",
  [":balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类型，你展示手牌并摸至与存活角色数相同。",

  ["@$shenjun"] = "神君",
  ["@@shenjun-inhand"] = "神君",
  ["#shenjun-invoke"] = "神君：你可以将%arg张牌当一种“神君”牌使用",
  ["shenjun_viewas"] = "神君",

  ["$shenjun1"] = "区区障眼之法，难遮神人之目。",
  ["$shenjun2"] = "我以天地为师，自可道法自然。",
  ["$balong1"] = "八龙之蜿蜿，云旗之委蛇。",
  ["$balong2"] = "穆王乘八牡，天地恣遨游。",
}

local dianzhan = fk.CreateTriggerSkill{
  name = "dianzhan",
  events = {fk.CardUseFinished},
  frequency = Skill.Compulsory,
  anim_type = "drawCard",
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    local suit = data.card.suit
    if suit == Card.NoSuit then return false end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark_name = "dianzhan_" .. data.card:getSuitString() .. "-round"
    local mark = player:getMark(mark_name)
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data[1]
        if last_use.from == player.id and last_use.card.suit == suit then
          mark = e.id
          room:setPlayerMark(player, mark_name, mark)
          return true
        end
        return false
      end, Player.HistoryRound)
    end
    return mark == use_event.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dianzhan1, dianzhan2 = false, false
    local tos =TargetGroup:getRealTargets(data.tos)
    if #tos == 1 then
      local to = room:getPlayerById(tos[1])
      if not to.dead and not to.chained then
        dianzhan1 = true
        to:setChainState(true)
      end
    end
    if player.dead then return false end
    local cards = table.filter(player:getCardIds(Player.Hand), function (id)
      return Fk:getCardById(id).suit == data.card.suit
    end)
    if #cards > 0 then
      dianzhan2 = true
      room:recastCard(cards, player, self.name)
    end
    if dianzhan1 and dianzhan2 and not player.dead then
      room:drawCards(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player == target and player:hasSkill(self, true) and data.card.suit ~= Card.NoSuit
    elseif event == fk.EventLoseSkill then
      return target == player and data == self and player:getMark("@dianzhan_suit-round") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      local suitRecorded = player:getTableMark("@dianzhan_suit-round")
      if table.insertIfNeed(suitRecorded, data.card:getSuitString(true)) then
        player.room:setPlayerMark(player, "@dianzhan_suit-round", suitRecorded)
      end
    elseif event == fk.EventLoseSkill then
      player.room:setPlayerMark(player, "@dianzhan_suit-round", 0)
    end
  end,
}
Fk:loadTranslationTable{
  ["dianzhan"] = "点盏",
  [":dianzhan"] = "锁定技，当你每轮首次使用一种花色的牌后，你令此牌唯一目标横置并重铸此花色的所有手牌，若均执行，你摸一张牌。",

  ["@dianzhan_suit-round"] = "点盏",

  ["$dianzhan1"] = "此灯如我，独向光明。",
  ["$dianzhan2"] = "此间皆暗，唯灯瞩明。",
}

local hanshao = General(extension, "olz__hanshao", "qun", 3)
local fangzhen = fk.CreateTriggerSkill{
  name = "fangzhen",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not table.every(player.room.alive_players, function(p) return p.chained end)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local targets = table.filter(room.alive_players, function(p)
        return not p.chained
      end)
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
        "#fangzhen-choose", self.name, true)
      if #to > 0 then
        self.cost_data = {tos = to}
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if to.seat > room:getBanner("RoundCount") and player:getMark("@fangzhen") < to.seat then
      room:setPlayerMark(player, "@fangzhen", to.seat)
    end
    to:setChainState(true)
    if to.dead or player.dead then return end
    local choices = {"fangzhen1"}
    if to:isWounded() then
      table.insert(choices, "fangzhen2")
    end
    local choice = room:askForChoice(player, choices, self.name, "#fangzhen-choice::"..to.id)
    if choice == "fangzhen1" then
      player:drawCards(2, self.name)
      if to == player then return end
      local cards = player:getCardIds("he")
      if #cards > 2 then
        cards = room:askForCard(player, 2, 2, true, self.name, false, ".", "#fangzhen-give::"..to.id)
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@fangzhen") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@fangzhen", 0)
  end,
}
local fangzhen_delay = fk.CreateTriggerSkill{
  name = "#fangzhen_delay",
  events = {fk.RoundStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fangzhen, true) and player:getMark("@fangzhen") == player.room:getBanner("RoundCount")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "fangzhen", "negative")
    player:broadcastSkillInvoke("fangzhen")
    player.room:handleAddLoseSkills(player, "-fangzhen", nil, true, false)
  end,
}
local liuju = fk.CreateTriggerSkill{
  name = "liuju",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
    not player:isKongcheng() and table.find(player.room.alive_players, function(p)
      return player:canPindian(p) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
      return player:canPindian(p) end), Util.IdMapper), 1, 1, "#liuju-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local pindian = player:pindian({to}, self.name)
    local loser = nil
    if pindian.results[to.id].winner == player then
      loser = to
    elseif pindian.results[to.id].winner == to then
      loser = player
    end
    if not loser or loser.dead then return false end
    local n1, n2 = player:distanceTo(to), to:distanceTo(player)
    local ids = {}
    table.insert(ids, pindian.fromCard:getEffectiveId())
    table.insert(ids, pindian.results[to.id].toCard:getEffectiveId())
    local extra_data = { bypass_times = true }
    while true do
      local to_use = table.filter(ids, function (id)
        local card = Fk:getCardById(id)
        return card.type ~= Card.TypeBasic and room:getCardArea(card) == Card.DiscardPile and
          not loser:prohibitUse(card) and loser:canUse(card, extra_data)
      end)
      if #to_use == 0 then break end
      local use = room:askForUseRealCard(loser, to_use, self.name, "#liuju-use", {expand_pile = to_use}, true, true)
      if use == nil then break end
      table.removeOne(ids, use.card:getEffectiveId())
      room:useCard(use)
      if player.dead then break end
    end
    if player:usedSkillTimes("xumin", Player.HistoryGame) > 0 and not player.dead and not to.dead and
    (player:distanceTo(to) ~= n1 or to:distanceTo(player) ~= n2) then
      player:setSkillUseHistory("xumin", 0, Player.HistoryGame)
    end
  end,
}
Fk:loadTranslationTable{
  ["fangzhen"] = "放赈",
  [":fangzhen"] = "出牌阶段开始时，你可以横置一名角色，然后选择：1.摸两张牌并交给其两张牌；2.令其回复1点体力。第X轮开始时（X为其座次），"..
  "你失去此技能。",
  ["liuju"] = "留驹",
  [":liuju"] = "出牌阶段结束时，你可以与一名角色拼点，输的角色可以使用拼点牌中的任意张非基本牌。若你与其的相互距离因此变化，你复原〖恤民〗。",
  ["#fangzhen-choose"] = "放赈：你可以横置一名角色，摸两张牌交给其或令其回复体力",
  ["fangzhen1"] = "摸两张牌并交给其两张牌",
  ["fangzhen2"] = "令其回复1点体力",
  ["#fangzhen-choice"] = "放赈：选择对 %dest 执行的一项",
  ["#fangzhen-give"] = "放赈：选择两张牌交给 %dest",
  ["@fangzhen"] = "放赈",
  ["#liuju-choose"] = "留驹：你可以拼点，输的角色可以使用其中的非基本牌",
  ["#liuju-use"] = "留驹：你可以使用其中的非基本牌",

  ["$fangzhen1"] = "百姓罹灾，当施粮以赈。",
  ["$fangzhen2"] = "开仓放粮，以赈灾民。",
  ["$liuju1"] = "当逐千里之驹，情深可留嬴城。",
  ["$liuju2"] = "乡老十里相送，此驹可彰吾情。",
}

local hanrong = General(extension, "olz__hanrong", "qun", 3)
local lianhe = fk.CreateTriggerSkill{
  name = "lianhe",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      #table.filter(player.room.alive_players, function(p) return not p.chained end) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
      return not p.chained end), Util.IdMapper), 2, 2, "#lianhe-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data.tos)
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        p:setChainState(true)
        room:addTableMarkIfNeed(p, "@@lianhe", player.id)
      end
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase ~= Player.Play then return false end
    if event == fk.AfterCardsMove then
      return player:getMark("@lianhe-phase") ~= 0
    elseif event == fk.EventPhaseStart then
      return player == target and #player:getTableMark("@@lianhe") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local x = tonumber(player:getMark("@lianhe-phase"))
      local update_mark = false
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand and #move.moveInfo > 0 then
          if move.moveReason == fk.ReasonDraw then
            room:setPlayerMark(player, "@lianhe-phase", 0)
            room:setPlayerMark(player, "lianhe_targets-phase", 0)
            return
          end
          if x < 3 then
            update_mark = true
            x = x + #move.moveInfo
          end
        end
      end
      if update_mark then
        room:setPlayerMark(player, "@lianhe-phase", math.min(3, x))
      end
    elseif event == fk.EventPhaseStart then
      local mark = player:getTableMark("@@lianhe")
      room:setPlayerMark(player, "lianhe_targets-phase", mark)
      room:setPlayerMark(player, "@lianhe-phase", "0")
      room:setPlayerMark(player, "@@lianhe", 0)
    end
  end,
}
local lianhe_delay = fk.CreateTriggerSkill{
  name = "#lianhe_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and target.phase == Player.Play and target:getMark("@lianhe-phase") ~= 0 and
    table.contains(target:getTableMark("lianhe_targets-phase"), player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:notifySkillInvoked(player, "lianhe")
    player:broadcastSkillInvoke("lianhe")
    local n = tonumber(target:getMark("@lianhe-phase"))
    if n < 2 or player == target then
      player:drawCards(n + 1, "lianhe")
    else
      local cards = room:askForCard(target, n - 1, n - 1, true, "lianhe", true, ".",
        "#lianhe-card:"..player.id.."::"..tostring(n - 1)..":"..tostring(n + 1))
      if #cards == n - 1 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, "lianhe", nil, false, target.id)
      else
        player:drawCards(n + 1, "lianhe")
      end
    end
  end,
}
local huanjia = fk.CreateTriggerSkill{
  name = "huanjia",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng() and
      table.find(player.room.alive_players, function(p) return not player:canPindian(p) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
      return player:canPindian(p) end), Util.IdMapper), 1, 1, "#huanjia-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local pindian = player:pindian({to}, self.name)
    local winner = nil
    if pindian.results[to.id].winner == player then
      winner = player
    elseif pindian.results[to.id].winner == to then
      winner = to
    end
    if not winner or winner.dead then return end
    local ids = {}
    table.insert(ids, pindian.fromCard:getEffectiveId())
    table.insert(ids, pindian.results[to.id].toCard:getEffectiveId())
    local to_use = table.filter(ids, function (id)
      local card = Fk:getCardById(id)
      return room:getCardArea(id) == Card.DiscardPile and
        not winner:prohibitUse(card) and winner:canUse(card, { bypass_times = true })
    end)
    if #to_use == 0 then return false end
    local use = room:askForUseRealCard(winner, to_use, self.name, "#huanjia-use:" .. player.id, {
      bypass_times = true,
      extraUse = true,
      expand_pile = to_use,
    }, true, true)
    if use then
      table.removeOne(ids, use.card:getEffectiveId())
      use.extra_data = { huanjia_source = player.id, huanjia_ids = ids }
      room:useCard(use)
    end
  end,
}
local huanjia_delay = fk.CreateTriggerSkill{
  name = "#huanjia_delay",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.huanjia_source == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("huanjia")
    if data.damageDealt then
      room:notifySkillInvoked(player, "huanjia", "negative")
      local skills = {}
      for _, skill in ipairs(player.player_skills) do
        if skill:isPlayerSkill(player) then
          table.insert(skills, skill.name)
        end
      end
      local choice = room:askForChoice(player, skills, "huanjia", "#huanjia-choice", true)
      room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
    else
      room:notifySkillInvoked(player, "huanjia", "drawcard")
      local ids = data.extra_data.huanjia_ids
      if type(ids) ~= "table" then return false end
      ids = table.filter(ids, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #ids > 0 then
        room:moveCardTo(ids, Player.Hand, player, fk.ReasonPrey, "huanjia", nil, true, player.id)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["lianhe"] = "连和",
  [":lianhe"] = "出牌阶段开始时，你可以横置两名角色，这些角色的下个出牌阶段的阶段结束时，若其于此阶段内未摸过牌，其选择："..
  "1.令你摸X+1张牌；2.交给你X-1张牌（X为其于此阶段内得到过的牌数且至多为3）。",
  ["huanjia"] = "缓颊",
  [":huanjia"] = "出牌阶段结束时，你可以与一名角色拼点，赢的角色可以使用一张拼点牌，若此牌：未造成伤害，你获得另一张拼点牌；造成了伤害，你失去一个技能。",
  ["#lianhe-choose"] = "连和：你可以横置两名角色，你根据其下个出牌阶段获得牌数摸牌",
  ["@@lianhe"] = "连和",
  ["@lianhe-phase"] = "连和",
  ["#lianhe-card"] = "连和：你需交给 %src %arg张牌，否则其摸%arg2张牌",
  ["#huanjia-choose"] = "缓颊：你可以拼点，赢的角色可以使用一张拼点牌",
  ["#huanjia-use"] = "缓颊：你可以使用一张拼点牌，若未造成伤害则 %src 获得另一张，若造成伤害则其失去一个技能",
  ["#huanjia_delay"] = "缓颊",
  ["#huanjia-choice"] = "缓颊：你需失去一个技能",

  ["$lianhe1"] = "枯草难存于劲风，唯抱簇得生。",
  ["$lianhe2"] = "吾所来之由，一为好，二为和。",
  ["$huanjia1"] = "我之所言，皆为君好。",
  ["$huanjia2"] = "吾言之切切，请君听之。",
}

local wukuang = General(extension, "olz__wukuang", "qun", 4)
local lianzhuw = fk.CreateActiveSkill{
  name = "lianzhuw",
  anim_type = "switch",
  switch_skill_name = "lianzhuw",
  attached_skill_name = "lianzhuw&",
  card_num = function()
    if Self:getSwitchSkillState("lianzhuw", false) == fk.SwitchYang then
      return 1
    else
      return 0
    end
  end,
  target_num = 0,
  prompt = function (self, selected_cards, selected_targets)
    return "#lianzhuw-"..Self:getSwitchSkillState("lianzhuw", false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return #selected == 0
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:recastCard(effect.cards, player, self.name)
      local color = Fk:getCardById(effect.cards[1]):getColorString()
      local prompt = "#lianzhuw1-card:::"..color
      if color == "nocolor" then
        prompt = "#lianzhuw2-card"
      end
      local card = room:askForCard(player, 1, 1, true, self.name, true, ".", prompt)
      if #card > 0 then
        room:recastCard(card, player, self.name)
        if player.dead then return end
        if color ~= "nocolor" then
          local color2 = Fk:getCardById(card[1]):getColorString()
          if color2 ~= "nocolor" and color2 == color then
            room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
          end
        end
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
        return player:inMyAttackRange(p) end), Util.IdMapper)
      if #targets == 0 then return end
      local target = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhuw1-choose", self.name, false)
      if #target > 0 then
        target = room:getPlayerById(target[1])
      else
        target = room:getPlayerById(table.random(targets))
      end
      local use1 = room:askForUseCard(player, "slash", "slash", "#lianzhuw-slash::"..target.id, true,
        {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
      if use1 then
        room:useCard(use1)
        if not player.dead and not target.dead then
          local color = use1.card:getColorString()
          local prompt = "#lianzhuw1-slash::"..target.id..":"..color
          if color == "nocolor" then
            prompt = "#lianzhuw-slash::"..target.id
          end
          local use2 = room:askForUseCard(player, "slash", "slash", prompt, true,
            {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
          if use2 then
            room:useCard(use2)
            if player.dead then return end
            if color ~= "nocolor" then
              local color2 = use2.card:getColorString()
              if color2 ~= "nocolor" and color2 ~= color and player:getMaxCards() > 0 then
                room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
              end
            end
          end
        end
      end
    end
  end,
}
local lianzhuw_active = fk.CreateActiveSkill{
  name = "lianzhuw&",
  mute = true,
  prompt = function (self, selected_cards, selected_targets)
    local p = table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(lianzhuw) and p ~= Self
    end)
    if p then
      return "#lianzhuw_active-"..p:getSwitchSkillState("lianzhuw", false, true)..":"..p.id
    end
  end,
  card_num = function()
    local p = table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(lianzhuw) and p ~= Self
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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p:hasSkill(lianzhuw) and p ~= player
      end)
  end,
  card_filter = function(self, to_select, selected)
    local p = table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(lianzhuw) and p ~= Self
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
    local player = room:getPlayerById(effect.from)
    local src = table.find(room.alive_players, function (p)
      return p:hasSkill(lianzhuw) and p ~= player
    end)
    if not src then return end
    room:doIndicate(player.id, {src.id})
    room:setPlayerMark(src, MarkEnum.SwithSkillPreName .. "lianzhuw", src:getSwitchSkillState("lianzhuw", true))
    src:addSkillUseHistory("lianzhuw")
    src:broadcastSkillInvoke("lianzhuw")
    room:notifySkillInvoked(src, "lianzhuw", "switch")
    if src:getSwitchSkillState("lianzhuw", true) == fk.SwitchYang then
      room:recastCard(effect.cards, player, "lianzhuw")
      local color = Fk:getCardById(effect.cards[1]):getColorString()
      local prompt = "#lianzhuw1-card:::"..color
      if color == "nocolor" then
        prompt = "#lianzhuw2-card"
      end
      local card = room:askForCard(src, 1, 1, true, "lianzhuw", true, ".", prompt)
      if #card > 0 then
        room:recastCard(card, src, "lianzhuw")
        if src.dead then return end
        if color ~= "nocolor" then
          local color2 = Fk:getCardById(card[1]):getColorString()
          if color2 ~= "nocolor" and color2 == color then
            room:addPlayerMark(src, MarkEnum.AddMaxCards, 1)
          end
        end
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
        return (player:inMyAttackRange(p) or src:inMyAttackRange(p)) and p ~= src end), Util.IdMapper)
      if #targets == 0 then return end
      local target = room:askForChoosePlayers(src, targets, 1, 1, "#lianzhuw2-choose:"..player.id, "lianzhuw", false)
      if #target > 0 then
        target = room:getPlayerById(target[1])
      else
        target = room:getPlayerById(table.random(targets))
      end
      local use1 = room:askForUseCard(player, "slash", "slash", "#lianzhuw-slash::"..target.id, true,
        {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
      if use1 then
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
        local use2 = room:askForUseCard(src, "slash", "slash", prompt, true,
          {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
        if use2 then
          room:useCard(use2)
          if src.dead then return end
          if color ~= "nocolor" then
            local color2 = use2.card:getColorString()
            if color2 ~= "nocolor" and color2 ~= color and src:getMaxCards() > 0 then
              room:addPlayerMark(src, MarkEnum.MinusMaxCards, 1)
            end
          end
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["lianzhuw"] = "联诛",
  [":lianzhuw"] = "转换技，每名角色出牌阶段限一次，阳：其可以与你各重铸一张牌，若颜色相同，你的手牌上限+1；"..
  "阴：你选择一名在你或其攻击范围内的角色，其可以与你各对目标使用一张【杀】，若颜色不同，你的手牌上限-1。",
  ["#lianzhuw-yang"] = "联诛：你可以依次重铸两张牌，若颜色相同，你手牌上限+1",
  ["#lianzhuw-yin"] = "联诛：选择一名攻击范围内的角色，你可以依次对其使用两张【杀】，若颜色不同，你手牌上限-1",
  ["#lianzhuw_active-yang"] = "联诛：你可以与 %src 各重铸一张牌",
  ["#lianzhuw_active-yin"] = "联诛：%src 选择一名在你或其攻击范围内的角色，你与其依次可以对目标使用一张【杀】",
  ["#lianzhuw1-card"] = "联诛：你可以重铸一张牌，若为%arg，你手牌上限+1",
  ["#lianzhuw2-card"] = "联诛：你可以重铸一张牌",
  ["#lianzhuw1-choose"] = "联诛：选择一名你攻击范围内的角色",
  ["#lianzhuw2-choose"] = "联诛：选择一名你或 %src 攻击范围内的角色",
  ["#lianzhuw1-slash"] = "联诛：你可以对 %dest 使用一张【杀】，若不为%arg，你手牌上限-1",
  ["#lianzhuw-slash"] = "联诛：你可以对 %dest 使用一张【杀】",
  ["lianzhuw&"] = "联诛",
  [":lianzhuw&"] = "出牌阶段限一次，若吴匡的〖联诛〗为：阳：你可以与其各重铸一张牌，若颜色相同，其手牌上限+1；"..
  "阴：其选择一名在你或其攻击范围内的角色，你可以与吴匡各对目标使用一张【杀】，若颜色不同，其手牌上限-1。",

  ["$lianzhuw1"] = "奸宦作乱，当联兵伐之。",
  ["$lianzhuw2"] = "尽诛贼常侍，正在此时。",
}

local mingjiew = fk.CreateActiveSkill{
  name = "mingjiew",
  anim_type = "control",
  prompt = "#mingjiew",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and (not table.contains(target:getTableMark("@@mingjiew"), Self.id)
    or (to_select == Self.id and Self:getMark("mingjiew_Self-turn") == 0))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = target:getTableMark("@@mingjiew")
    if player == target then
      room:setPlayerMark(player, "mingjiew_Self-turn", 1)
      if table.contains(mark, player.id) then
        return
      else
        room:setPlayerMark(player, "mingjiew_disabled-turn", 1)
      end
    end
    table.insert(mark, player.id)
    room:setPlayerMark(target, "@@mingjiew", mark)
  end,
}

local mingjiew_delay = fk.CreateTriggerSkill{
  name = "#mingjiew_delay",
  mute = true,
  events = {fk.AfterCardTargetDeclared, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      if target == player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
        local mark
        local targets = table.filter(player.room:getUseExtraTargets(data), function (id)
          mark = room:getPlayerById(id):getMark("@@mingjiew")
          return type(mark) == "table" and table.contains(mark, player.id)
        end)
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      end
    elseif event == fk.TurnEnd then
      if player:getMark("mingjiew_disabled-turn") > 0 or not table.contains(target:getTableMark("@@mingjiew"), player.id) then
        return false
      end
      local events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      local end_id = target:getMark("mingjiew_record-turn")
      if end_id == 0 then
        end_id = room.logic:getCurrentEvent().id
      end
      room:setPlayerMark(target, "mingjiew_record-turn", room.logic.current_event_id)
      local ids = target:getTableMark("mingjiew_usecard-turn")
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= end_id then break end
        local use = e.data[1]
        if use.card.suit == Card.Spade or use.cardsResponded then
          table.insertTableIfNeed(ids, use.card:isVirtual() and use.card.subcards or {use.card.id})
        end
      end
      room:setPlayerMark(target, "mingjiew_usecard-turn", ids)
      return table.find(ids, function (id)
        local card = Fk:getCardById(id)
        return room:getCardArea(id) == Card.DiscardPile and player:canUse(card) and not player:prohibitUse(card)
      end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      local tos = room:askForChoosePlayers(player, self.cost_data, 1, #self.cost_data,
        "#mingjiew-choose:::"..data.card:toLogString(), "mingjiew", true)
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    elseif event == fk.TurnEnd then
      local ids = table.filter(target:getMark("mingjiew_usecard-turn"), function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      local to_use = {}
      while not player.dead do
        to_use = table.filter(ids, function (id)
          local card = Fk:getCardById(id)
          return room:getCardArea(id) == Card.DiscardPile and player:canUse(card) and not player:prohibitUse(card)
        end)
        if #to_use == 0 then break end
        local use = room:askForUseRealCard(player, to_use, self.name, "#mingjiew-use", {
          bypass_times = true,
          extraUse = true,
          expand_pile = to_use,
        }, true, true)
        if use then
          table.removeOne(ids, use.card:getEffectiveId())
          room:useCard(use)
        else
          break
        end
      end
    end
  end,

  late_refresh = true,
  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@mingjiew") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    if player:getMark("mingjiew_Self-turn") == 0 then
      player.room:setPlayerMark(player, "@@mingjiew", 0)
    else
      player.room:setPlayerMark(player, "@@mingjiew", {player.id})
    end
  end,
}
Fk:loadTranslationTable{
  ["mingjiew"] = "铭戒",
  [":mingjiew"] = "限定技，出牌阶段，你可以选择一名角色：直到其下回合结束，你使用牌可以额外指定其为目标；其下回合结束时，"..
  "你可以使用弃牌堆中此回合中被使用过的♠牌和被抵消过的牌。",

  ["#mingjiew"] = "铭戒：选择一名角色",
  ["@@mingjiew"] = "铭戒",
  ["#mingjiew-choose"] = "铭戒：你可以为此%arg额外指定任意名“铭戒”角色为目标",
  ["#mingjiew-use"] = "铭戒：你可以使用其中的牌",

  ["$mingjiew1"] = "大公至正，恪忠义于国。",
  ["$mingjiew2"] = "此生柱国之志，铭恪于胸。",
}

local qiuxin = fk.CreateActiveSkill{
  name = "qiuxin",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#qiuxin",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = room:askForChoice(target, {"slash", "trick"}, self.name, "#qiuxin-choice:"..player.id)
    room:addTableMarkIfNeed(target, "@qiuxin", choice)
  end,
}
local qiuxin_trigger = fk.CreateTriggerSkill{
  name = "#qiuxin_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(qiuxin) then return false end
    local qiuxin_type = ""
    if data.card.trueName == "slash" then
      qiuxin_type = "slash"
    elseif data.card:isCommonTrick() then
      qiuxin_type = "trick"
    else
      return false
    end
    local tos = TargetGroup:getRealTargets(data.tos)
    for _, p in ipairs(player.room.alive_players) do
      if table.contains(tos, p.id) and table.contains(p:getTableMark("@qiuxin"), qiuxin_type) then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = TargetGroup:getRealTargets(data.tos)
    if data.card.trueName == "slash" then
      for _, p in ipairs(player.room.alive_players) do
        if player.dead then break end
        if not p.dead and table.contains(tos, p.id) then
          local mark = p:getTableMark("@qiuxin")
          if table.contains(mark, "slash") then
            room:setPlayerMark(player, "qiuxin-tmp", p.id)
            local success, dat = room:askForUseActiveSkill(player, "qiuxin_viewas", "#qiuxin-trick::"..p.id, true)
            room:setPlayerMark(player, "qiuxin-tmp", 0)
            if success and dat then
              table.removeOne(mark, "slash")
              room:setPlayerMark(p, "@qiuxin", #mark > 0 and mark or 0)
              local trick = Fk:cloneCard(dat.interaction)
              trick.skillName = qiuxin.name
              local _tos = {{p.id}}
              for _, pid in ipairs(dat.targets) do
                table.insert(_tos, {pid})
              end
              room:useCard({
                from = player.id,
                tos = _tos,
                card = trick,
                extraUse = true,
              })
            end
          end
        end
      end
    elseif data.card:isCommonTrick() then
      for _, p in ipairs(player.room.alive_players) do
        local slash = Fk:cloneCard("slash")
        slash.skillName = "qiuxin"
        if player.dead or player:prohibitUse(slash) then break end
        if table.contains(tos, p.id) and not (p.dead or player:isProhibited(p, slash))  then
          local mark = p:getTableMark("@qiuxin")
          if table.contains(mark, "trick") and
          room:askForSkillInvoke(player, "qiuxin", nil, "#qiuxin-slash::" .. p.id) then
            table.removeOne(mark, "trick")
            room:setPlayerMark(p, "@qiuxin", #mark > 0 and mark or 0)
            room:useCard({
              from = player.id,
              tos = {{p.id}},
              card = slash,
              extraUse = true,
            })
          end
        end
      end
    end
  end,
}
local qiuxin_viewas = fk.CreateActiveSkill{
  name = "qiuxin_viewas",
  interaction = function()
    local mark = Self:getMark("qiuxin-tmp")
    local all_names = U.getAllCardNames("t")
    local to = Fk:currentRoom():getPlayerById(mark)
    local names = table.filter(all_names, function (card_name)
      local trick = Fk:cloneCard(card_name)
      trick.skillName = qiuxin.name
      return not (Self:prohibitUse(trick) or Self:isProhibited(to, trick)) and
      trick.skill:modTargetFilter(mark, {}, Self, trick, true)
    end)
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_names}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards, _, _, player)
    if not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = qiuxin.name
    if card.skill:getMinTargetNum() < 2 then return false end
    local _selected = {Self:getMark("qiuxin-tmp")}
    table.insertTable(_selected, selected)
    return card.skill:targetFilter(to_select, _selected, {}, card, nil, player)
  end,
  feasible = function(self, selected, selected_cards)
    if not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = qiuxin.name
    local x = card.skill:getMinTargetNum()
    return x < 2 or #selected + 1 == x
  end,
}
local jianyuan = fk.CreateTriggerSkill{
  name = "jianyuan",
  anim_type = "support",
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target and not target.dead and not target:isNude() and
      ((data:isInstanceOf(ActiveSkill) or data:isInstanceOf(ViewAsSkill)) and
      table.find({"出牌阶段限一次", "阶段技", "每阶段限一次"}, function(str) return Fk:translate(":"..data.name, "zh_CN"):startsWith(str) end)) and
      data:isPlayerSkill(target)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jianyuan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n = 0
    room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      if use and use.from == target.id then
        n = n + 1
      end
    end, Player.HistoryPhase)
    if n == 0 then return end
    room:setPlayerMark(target, "jianyuan-tmp", n)
    local success, dat = room:askForUseActiveSkill(target, "jianyuan_active", "#jianyuan-card:::"..n, true)
    room:setPlayerMark(target, "jianyuan-tmp", 0)
    if success then
      room:recastCard(dat.cards, target, self.name)
    end
  end,
}
local jianyuan_active = fk.CreateActiveSkill{
  name = "jianyuan_active",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return Self:getMark("jianyuan-tmp") == Fk:translate(card.trueName, "zh_CN"):len()
  end,
}
qiuxin.scope_type = Player.HistoryPhase
Fk:loadTranslationTable{
  ["qiuxin"] = "求心",
  [":qiuxin"] = "出牌阶段限一次，你可以令一名其他角色声明一项：1.当你对其使用一张【杀】后，你可以视为对其使用一张普通锦囊牌；"..
  "2.当你对其使用一张普通锦囊牌后，你可以视为对其使用一张无距离限制的【杀】。",
  ["jianyuan"] = "简远",
  [":jianyuan"] = "当一名角色发动“出牌阶段限一次”的技能后，你可以令其重铸任意张牌名字数为X的牌（X为其本阶段使用牌数）。",
  ["#qiuxin"] = "求心：令一名其他角色声明一项",
  ["@qiuxin"] = "求心",
  ["#qiuxin-choice"] = "求心：%src 对你发动“求心”，请声明一项",
  ["#qiuxin-slash"] = "求心：是否视为对 %dest 使用【杀】？",
  ["#qiuxin-trick"] = "求心：选择视为对 %dest 使用的锦囊？",
  ["qiuxin_viewas"] = "求心",
  ["#jianyuan-invoke"] = "简远：你可以令 %dest 重铸牌",
  ["jianyuan_active"] = "简远",
  ["#jianyuan-card"] = "简远：你可以重铸任意张牌名字数为%arg的牌",

  ["$qiuxin1"] = "此生所求者，顺心意尔。",
  ["$qiuxin2"] = "羡孔丘知天命之岁，叹吾生之不达。",
  ["$jianyuan1"] = "我视天地为三，其为众妙之门。",
  ["$jianyuan2"] = "昔年孔明有言，宁静方能致远。",
}

local jianjiw = fk.CreateTriggerSkill{
  name = "jianjiw",
  frequency = Skill.Limited,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not (target.dead or target:isRemoved()) and
    player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local targets = {}
      local next_alive = target:getNextAlive()
      if next_alive == nil or next_alive == target then return false end
      table.insert(targets, next_alive.id)
      next_alive = target:getLastAlive()
      if next_alive == nil or next_alive == target then return false end
      table.insertIfNeed(targets, next_alive.id)
      local jianjiw1, jianjiw2 = false, false
      local use
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        use = e.data[1]
        if use.from and table.contains(targets, use.from) then
          jianjiw1 = true
        end
        if not table.every(TargetGroup:getRealTargets(use.tos), function (id)
          return not table.contains(targets, id)
        end) then
          jianjiw2 = true
        end
        return jianjiw1 and jianjiw2
      end, turn_event.id)
      targets = {}
      if not jianjiw1 then
        table.insert(targets, "jianjiw1")
      end
      if not jianjiw2 then
        table.insert(targets, "jianjiw2")
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to_invoke = table.simpleClone(self.cost_data)
    if table.contains(to_invoke, "jianjiw1") then
      local prompt = "#jianjiw-draw::" .. target.id
      if #to_invoke > 1 then
        prompt = "#jianjiw-draw-slash::" .. target.id
      end
      if room:askForSkillInvoke(player, self.name, data, prompt) then
        room:doIndicate(player.id, {target.id})
        return true
      end
      if #to_invoke == 1 then return false end
    end
    local use = U.askForUseVirtualCard(room, player, "slash", {}, self.name, "#jianjiw-slash", true, true, false, true, {}, true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to_invoke = table.simpleClone(self.cost_data)
    local targets = {}
    if table.contains(to_invoke, "jianjiw1") then
      room:drawCards(player, 1, self.name)
      if not target.dead then
        room:drawCards(target, 1, self.name)
      end
      if player.dead or #to_invoke == 1 then return false end
      U.askForUseVirtualCard(room, player, "slash", {}, self.name, "#jianjiw-slash", true, true, false, true, {})
    else
      room:useCard(to_invoke)
    end
  end,
}
Fk:loadTranslationTable{
  ["jianjiw"] = "见机",
  [":jianjiw"] = "限定技，一名角色的回合结束时，若与其相邻的角色于此回合内均未使用过牌，你可以与其各摸一张牌；"..
  "若与其相邻的角色于此回合内均未成为过牌的目标，你可以视为使用【杀】。",

  ["#jianjiw-draw"] = "见机：是否与 %dest 各摸一张牌？",
  ["#jianjiw-draw-slash"] = "见机：是否与 %dest 各摸一张牌，然后可以视为使用【杀】？",
  ["#jianjiw-slash"] = "见机：是否视为使用【杀】？",

  ["$jianjiw1"] = "",
  ["$jianjiw2"] = "",
}

local wangmingshan = General(extension, "olz__wangmingshan", "wei", 3)
local tanque = fk.CreateTriggerSkill{
  name = "tanque",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) or data.card.number == 0 or player:usedSkillTimes(self.name) > 0 then return false end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local last_find = false
    for i = #events, 1, -1 do
      local e = events[i]
      if e.data[1].from == player.id then
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          local last_use = e.data[1]
          if last_use.card.number == 0 then return false end
          local x = math.abs(last_use.card.number - data.card.number)
          if x == 0 then return false end
          local targets = table.filter(room.alive_players, function (p)
            return p.hp == x
          end)
          if #targets > 0 then
            self.cost_data = {table.map(targets, Util.IdMapper), x}
            return true
          end
          return false
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = player.room:askForChoosePlayers(player, self.cost_data[1], 1, 1,
    "#tanque-choose:::" .. tostring(self.cost_data[2]), self.name, true)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage{
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player:hasSkill(self, true)
    elseif event == fk.EventLoseSkill then
      return data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:setPlayerMark(player, "@tanque", data.card:getNumberStr())
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@tanque", 0)
    end
  end,
}
local function getShengmoCards(player)
  local cards = player:getTableMark("shengmo_cards-turn")
  if #cards < 3 then return {} end
  local cardmap = {}
  for _ = 1, 13, 1 do
    table.insert(cardmap, {})
  end
  for _, id in ipairs(cards) do
    table.insert(cardmap[Fk:getCardById(id).number], id)
  end
  for i = 1, 13, 1 do
    if #cardmap[i] > 0 then
      cardmap[i] = {}
      break
    end
  end
  for i = 13, 1, -1 do
    if #cardmap[i] > 0 then
      cardmap[i] = {}
      break
    end
  end
  return table.connect(table.unpack(cardmap))
end
local shengmo = fk.CreateViewAsSkill{
  name = "shengmo",
  pattern = ".|.|.|.|.|basic",
  prompt = "#shengmo",
  expand_pile = function()
    return getShengmoCards(Self)
  end,
  interaction = function()
    local mark = Self:getTableMark("shengmo_used")
    local all_names = Fk:getAllCardNames("b")
    local names = table.filter(player:getViewAsCardNames("shengmo", all_names), function (name)
      return not table.contains(mark, Fk:cloneCard(name).trueName)
    end)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(Self:getTableMark("shengmo_cards-turn"), to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:setMark("shengmo_subcards", cards[1])
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "shengmo_used", use.card.trueName)
    room:removeTableMark(player, "@$shengmo", use.card.trueName)
    local card_id = use.card:getMark("shengmo_subcards")
    room:obtainCard(player, card_id, true, fk.ReasonPrey, player.id)
  end,
  enabled_at_play = function(self, player)
    if #getShengmoCards(player) > 0 then
      local mark = player:getTableMark("shengmo_used")
      return #table.filter(U.getViewAsCardNames(player, "shengmo", U.getAllCardNames("b")), function (name)
        return not table.contains(mark, Fk:cloneCard(name).trueName)
      end) > 0
    end
  end,
  enabled_at_response = function(self, player, response)
    if not response and #getShengmoCards(player) > 0 then
      local mark = player:getTableMark("shengmo_used")
      return #table.filter(U.getViewAsCardNames(player, "shengmo", U.getAllCardNames("b")), function (name)
        return not table.contains(mark, Fk:cloneCard(name).trueName)
      end) > 0
    end
  end,
}
local shengmo_refresh = fk.CreateTriggerSkill{
  name = "#shengmo_refresh",

  refresh_events = {fk.AfterCardsMove, fk.AfterDrawPileShuffle, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return event == fk.AfterCardsMove or event == fk.AfterDrawPileShuffle or (player == target and data == shengmo)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local ids = player:getTableMark("shengmo_cards-turn")
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
      ids = table.filter(ids, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      room:setPlayerMark(player, "shengmo_cards-turn", ids)
    elseif event == fk.AfterDrawPileShuffle then
      room:setPlayerMark(player, "shengmo_cards-turn", 0)
    elseif event == fk.EventAcquireSkill then
      local basics = U.getAllCardNames("b", true)
      room:setPlayerMark(player, "@$shengmo", basics)
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local ids = {}
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
        return false
      end, turn_event.id)
      ids = table.filter(ids, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      room:setPlayerMark(player, "shengmo_cards-turn", ids)
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@$shengmo", 0)
      room:setPlayerMark(player, "shengmo_used", 0)
    end
  end,
}
tanque.scope_type = Player.HistoryTurn
Fk:loadTranslationTable{
  ["tanque"] = "弹雀",
  [":tanque"] = "每回合限一次，当你使用的牌结算结束后，你可以对一名体力值为X的角色造成1点伤害（X为此牌的点数与你上一张使用的牌的点数之差且不能为0）。",
  ["shengmo"] = "剩墨",
  [":shengmo"] = "你可以获得于当前回合内移至弃牌堆的牌中的一张不为其中点数最大且不为其中点数最小的牌，视为使用未以此法使用过的基本牌。",
  ["#tanque-choose"] = "弹雀：你可以对一名体力值为%arg的角色造成1点伤害",
  ["@tanque"] = "弹雀",
  ["#shengmo"] = "剩墨：获得弃牌堆里的一张牌，并视为使用一张基本牌",
  ["@$shengmo"] = "剩墨",

  ["$tanque1"] = "",
  ["$tanque2"] = "",
  ["$shengmo1"] = "",
  ["$shengmo2"] = "",
}

local chengqi = fk.CreateViewAsSkill{
  name = "chengqi",
  prompt = "#chengqi",
  pattern = ".",
  interaction = function(self, player)
    local mark = player:getTableMark("chengqi-turn")
    local all_names = Fk:getAllCardNames("bt")
    local names = table.filter(player:getViewAsCardNames("chengqi", all_names), function (name)
      local card = Fk:cloneCard(name)
      return not table.contains(mark, card.trueName)
    end)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, cards)
    if #cards < 2 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    local n = Fk:translate(card.trueName, "zh_CN"):len()
    for _, id in ipairs(cards) do
      n = n - Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len()
    end
    if n > 0 then return end
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local n = Fk:translate(use.card.trueName, "zh_CN"):len()
    for _, id in ipairs(use.card.subcards) do
      n = n - Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len()
    end
    if n == 0 then
      use.extra_data = use.extra_data or {}
      use.extra_data.chengqi_draw = player.id
    end
  end,
  enabled_at_response = function(self, player, response)
    if response or #player:getHandlyIds() < 2 then return false end
    local mark = player:getTableMark("chengqi-turn")
    return #table.filter(U.getViewAsCardNames(player, self.name, U.getAllCardNames("bt")), function (name)
      return not table.contains(mark, Fk:cloneCard(name).trueName)
    end) > 0
  end,
  on_acquire = function (self, player, is_start)
    local mark = {}
    local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event == nil then return end
    player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(mark, use.card.trueName)
      end
    end, turn_event.id)
    player.room:setPlayerMark(player, "chengqi-turn", mark)
  end,
}
local chengqi_trigger = fk.CreateTriggerSkill{
  name = "#chengqi_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.chengqi_draw == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
    "#chengqi-choose", self.name, false)
    if #tos > 0 then
      room:drawCards(room:getPlayerById(tos[1]), 1, chengqi.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengqi, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "chengqi-turn", data.card.trueName)
  end,
}
local jieli = fk.CreateTriggerSkill{
  name = "jieli",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player == target and player.phase == Player.Finish and player:hasSkill(self) then
      local room = player.room
      local targets = table.filter(room.alive_players, function (p)
        return not p:isKongcheng()
      end)
      if #targets == 0 then return false end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return false end
      local x = 0
      local use
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        use = e.data
        if use.from == player then
          x = math.max(x, Fk:translate(use.card.trueName, "zh_CN"):len())
        end
        return false
      end, turn_event.id)
      if x > 0 then
        self.cost_data = {table.map(targets, Util.IdMapper), x}
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local x = self.cost_data[2]
    local to = player.room:askForChoosePlayers(player, self.cost_data[1], 1, 1,
    "#jieli-choose:::" .. tostring(x), self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to, x = x}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local x, y, z = self.cost_data.x, 0, 0
    local handcards = {}
    for _, id in ipairs(to:getCardIds(Player.Hand)) do
      z = Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len()
      if y < z then
        y = z
        handcards = {id}
      elseif y == z then
        table.insert(handcards, id)
      end
    end
    local cards = room:getNCards(x)
    local results = U.askForExchange(player, "Top", "$Hand", cards, handcards, "#jieli-exchange::" .. to.id, x)
    if #results == 0 then
    else
      local to_hand = {}
      for i = x, 1, -1 do
        if table.removeOne(results, cards[i]) then
          table.insert(to_hand, cards[i])
          table.remove(cards, i)
        end
      end
      table.insertTable(results, cards)
      U.swapCardsWithPile(to, results, to_hand, self.name, "Top", false, player.id)
    end
  end,
}
Fk:loadTranslationTable{
  ["chengqi"] = "承启",
  [":chengqi"] = "你可以将至少两张手牌当一张你本回合未使用过的基本牌或普通锦囊牌使用，"..
  "你以此法使用的牌名字数不能大于转化前的牌名字数之和，若相等，你令一名角色摸一张牌。",
  ["jieli"] = "诫厉",
  [":jieli"] = "结束阶段，你可以选择一名角色，观看其手牌中牌名字数最大的牌和牌堆顶的X张牌，"..
  "然后你可以交换其中等量的牌（X为你本回合使用过的牌名字数的最大值）。",

  ["#chengqi-viewas"] = "承启：将至少两张牌当字数不小于这些牌之和的牌使用",
  ["#chengqi-choose"] = "承启：令一名角色摸一张牌",
  ["#jieli-choose"] = "诫厉：选择一名角色，观看其手牌和牌堆顶的%arg张牌并交换等量的牌",
  ["#jieli-exchange"] = "诫厉：你可以交换 %dest 的手牌与牌堆顶的等量的牌",

  ["$chengqi1"] = "世有十万字形，亦当有十万字体。",
  ["$chengqi2"] = "笔画如骨，不可拘于一形。",
  ["$jieli1"] = "子不学难成其材，子不教难筑其器。",
  ["$jieli2"] = "此子顽劣如斯，必当严加管教。",
}

return extension
