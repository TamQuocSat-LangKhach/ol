local extension = Package("ol_mou")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_mou"] = "OL-上兵伐谋",
  ["olmou"] = "OL谋",
}

local jiangwei = General(extension, "olmou__jiangwei", "shu", 4)
local zhuri = fk.CreateTriggerSkill{
  name = "zhuri",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase > 1 and player.phase < 8 and not player:isKongcheng() then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            return true
          end
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0 and table.find(player.room:getOtherPlayers(player), function(p) return player:canPindian(p) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:canPindian(p) end), Util.IdMapper),
      1, 1, "#zhuri-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
      local to = room:getPlayerById(self.cost_data)
      local pindian = player:pindian({to}, self.name)
      if player.dead then return end
      if pindian.results[to.id].winner == player then
        local ids = {}
        for _, card in ipairs({pindian.fromCard, pindian.results[to.id].toCard}) do
          if room:getCardArea(card) == Card.DiscardPile then
            table.insertIfNeed(ids, card:getEffectiveId())
          end
        end
        local extra_data = { bypass_times = true }
        ids = table.filter(ids, function (id)
          local card = Fk:getCardById(id)
          return not player:prohibitUse(card) and player:canUse(card, extra_data)
        end)
        if #ids == 0 then return false end
        room:setPlayerMark(player, "zhuri_cards", ids)
        local success, dat = room:askForUseActiveSkill(player, "zhuri_viewas", "#zhuri-use", true, extra_data)
        room:setPlayerMark(player, "zhuri_cards", 0)
        
        if success then
          local card = Fk:getCardById(dat.cards[1])
          local use = {
            from = player.id,
            tos = table.map(dat.targets, function(id) return{id} end),
            card = card,
            extraUse = true,
          }
          room:useCard(use)
        end
      else
        local choice = room:askForChoice(player, {"loseHp", "lose_zhuri"}, self.name)
        if choice == "loseHp" then
          room:loseHp(player, 1, self.name)
        else
          local turn = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
          if turn ~= nil and player:hasSkill("zhuri", true) then
            room:handleAddLoseSkills(player, "-zhuri", nil, true, false)
            turn:addCleaner(function()
              room:handleAddLoseSkills(player, "zhuri", nil, true, false)
            end)
          end
        end
      end
  end,
}
local zhuri_viewas = fk.CreateViewAsSkill{
  name = "zhuri_viewas",
  expand_pile = function (self)
    return U.getMark(Self, "zhuri_cards")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(U.getMark(Self, "zhuri_cards"), to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:getCardById(cards[1])
    if Self:canUse(card) and not Self:prohibitUse(card) then
      return card
    end
  end,
}
local ranji = fk.CreateTriggerSkill{
  name = "ranji",
  anim_type = "special",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local phase_ids = {}
    room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
      table.insert(phase_ids, {e.id, e.end_id})
    end, Player.HistoryTurn)
    local record = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if use.from == player.id then
        for _, phase_id in ipairs(phase_ids) do
          if #phase_id == 2 and e.id > phase_id[1] and (e.id < phase_id[2] or phase_id[2] == -1) then
            table.insertIfNeed(record, phase_id[1])
          end
        end
      end
    end, Player.HistoryTurn)
    local prompt = 0
    if #record == player.hp then
      prompt = 3
    elseif #record > player.hp then
      prompt = 1
    elseif #record < player.hp then
      prompt = 2
    end
    if room:askForSkillInvoke(player, self.name, nil, "#ranji"..prompt.."-invoke") then
      self.cost_data = prompt
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if self.cost_data == 1 then
      room:handleAddLoseSkills(player, "kunfenEx", nil, true, false)
    elseif self.cost_data == 2 then
      room:handleAddLoseSkills(player, "ol_ex__zhaxiang", nil, true, false)
    elseif self.cost_data == 3 then
      room:handleAddLoseSkills(player, "kunfenEx|ol_ex__zhaxiang", nil, true, false)
    end
    local choices = {}
    if player:getHandcardNum() < player.maxHp then
      table.insert(choices, "ranji-draw")
    end
    if player:isWounded() then
      table.insert(choices, "ranji-recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "ranji-draw" then
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    else
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
    end
    room:setPlayerMark(player, self.name, 1)
  end,
}
local ranji_trigger = fk.CreateTriggerSkill{
  name = "#ranji_trigger",
  mute = true,
  events = {fk.PreHpRecover, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      return target == player and player:getMark("ranji") > 0
    elseif event == fk.Death then
      return player:getMark("ranji") > 0 and data.damage and data.damage.from and data.damage.from == player
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      return true
    elseif event == fk.Death then
      player.room:setPlayerMark(player, "ranji", 0)
    end
  end,
}
local ol_ex__zhaxiang = fk.CreateTriggerSkill{
  name = "ol_ex__zhaxiang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.HpLost},
  on_trigger = function(self, event, target, player, data)
    for _ = 1, data.num do
      if not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, self.name)
    if player.phase == Player.Play then
      local room = player.room
      room:setPlayerMark(player, "@@ol_ex__zhaxiang-turn", 1)
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn")
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return data.card.trueName == "slash" and data.card.color == Card.Red and player:getMark("@@ol_ex__zhaxiang-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
}
local ol_ex__zhaxiang_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__zhaxiang_targetmod",
  bypass_distances =  function(self, player, skill, card)
    return card.trueName == "slash" and card.color == Card.Red and player:getMark("@@ol_ex__zhaxiang-turn") > 0
  end,
}

Fk:addSkill(zhuri_viewas)
ranji:addRelatedSkill(ranji_trigger)
ol_ex__zhaxiang:addRelatedSkill(ol_ex__zhaxiang_targetmod)
jiangwei:addSkill(zhuri)
jiangwei:addSkill(ranji)
jiangwei:addRelatedSkill("kunfenEx")
jiangwei:addRelatedSkill(ol_ex__zhaxiang)

Fk:loadTranslationTable{
  ["olmou__jiangwei"] = "谋姜维",
  ["#olmou__jiangwei"] = "炎志灼心",
  ["designer:olmou__jiangwei"] = "王秀丽",
  ["illustrator:olmou__jiangwei"] = "西国红云",

  ["zhuri"] = "逐日",
  [":zhuri"] = "你的阶段结束时，若你本阶段手牌数变化过，你可以拼点：若你赢，你可以使用一张拼点牌；若你没赢，你失去1点体力或本技能直到回合结束。",
  ["ranji"] = "燃己",
  [":ranji"] = "限定技，结束阶段，若你本回合使用过牌的阶段数：不小于体力值，你可以获得〖困奋〗；不大于体力值，你可以获得〖诈降〗。若如此做，"..
  "你将手牌数或体力值调整至体力上限，然后你不能回复体力，直到你杀死角色。",
  ["ol_ex__zhaxiang"] = "诈降",
  [":ol_ex__zhaxiang"] = "锁定技，当你失去1点体力后，你摸三张牌，若在你的出牌阶段，"..
  "你本回合你使用【杀】次数上限+1、使用红色【杀】无距离限制且不可被响应。",
  ["#zhuri-choose"] = "逐日：你可以拼点，若赢，你可以使用一张拼点牌；若没赢，你失去1点体力或本回合失去〖逐日〗",
  ["zhuri_viewas"] = "逐日",
  ["#zhuri-use"] = "逐日：你可以使用其中一张牌",
  ["lose_zhuri"] = "失去〖逐日〗直到回合结束",
  ["#ranji1-invoke"] = "燃己：是否获得〖困奋〗？",
  ["#ranji2-invoke"] = "燃己：是否获得〖诈降〗？",
  ["#ranji3-invoke"] = "燃己：是否获得〖困奋〗和〖诈降〗？",
  ["ranji-draw"] = "将手牌摸至手牌上限",
  ["ranji-recover"] = "回复体力至体力上限",
  ["@@ol_ex__zhaxiang-turn"] = "诈降",

  ["$zhuri1"] = "效逐日之夸父，怀忠志而长存。",
  ["$zhuri2"] = "知天命而不顺，履穷途而强为。",
  ["$ranji1"] = "此身为薪，炬成灰亦昭大汉长明！",
  ["$ranji2"] = "维之一腔骨血，可驱驰来北马否？",
  ["$kunfenEx_olmou__jiangwei1"] = "",
  ["$kunfenEx_olmou__jiangwei2"] = "",
  ["$ol_ex__zhaxiang_olmou__jiangwei1"] = "",
  ["$ol_ex__zhaxiang_olmou__jiangwei2"] = "",
  ["~olmou__jiangwei"] = "姜维姜维……又将何为？",
}

local guanyu = General(extension, "olmou__guanyu", "shu", 4)
local weilingy = fk.CreateViewAsSkill{
  name = "weilingy",
  prompt = "#weilingy-viewas",
  pattern = "slash,analeptic",
  interaction = function()
    local names, all_names = {} , {}
    local pat = Fk.currentResponsePattern
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.trueName == "slash" or card.trueName == "analeptic") and
      not card.is_derived and not table.contains(all_names, card.name) then
        table.insert(all_names, card.name)
        local to_use = Fk:cloneCard(card.name)
        if not Self:prohibitUse(to_use) then
          if pat == nil then
            if Self:canUse(card) then
              table.insert(names, card.name)
            end
          else
            if Exppattern:Parse(pat):matchExp(card.name) then
              table.insert(names, card.name)
            end
          end
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(self.name) == 0
  end,
}
local weilingy_trigger = fk.CreateTriggerSkill{
  name = "#weilingy_trigger",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weilingy)
    and table.contains(data.card.skillNames, "weilingy") and data.card.color ~= Card.NoColor
    and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local mark = U.getMark(to, "@weilingy-turn")
    table.insertIfNeed(mark, data.card:getColorString())
    room:setPlayerMark(to, "@weilingy-turn", mark)
    to:filterHandcards()
  end,
}
local weilingy_filter = fk.CreateFilterSkill{
  name = "#weilingy_filter",
  card_filter = function(self, to_select, player)
    if not table.contains(player.player_cards[Player.Hand], to_select.id) then return false end
    local mark = U.getMark(player, "@weilingy-turn")
    return table.contains(mark, to_select:getColorString())
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
local duoshou = fk.CreateTriggerSkill{
  name = "duoshou",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
    table.contains(U.getMark(player, "@duoshou-turn"), "sanshou_damage")
  end,
  on_use = function(self, event, target, player, data)
    local mark = U.getMark(player, "@duoshou-turn")
    table.removeOne(mark, "sanshou_damage")
    player.room:setPlayerMark(player, "@duoshou-turn", #mark > 0 and mark or 0)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.PreCardUse, fk.TurnStart, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function (self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return player == target and data == self
    else
      return player:hasSkill(self, true) and (event == fk.TurnStart or player == target)
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardUse then
      local mark = U.getMark(player, "@duoshou-turn")
      local update = false
      if data.card.color == Card.Red and table.removeOne(mark, "sanshou_red") then
        update = true
      end
      if data.card.type == Card.TypeBasic and table.removeOne(mark, "sanshou_basic") then
        update = true
        if player:hasSkill(self) then
          data.extraUse = true
        end
      end
      if update then
        room:setPlayerMark(player, "@duoshou-turn", #mark > 0 and mark or 0)
      end
    elseif event == fk.TurnStart then
      room:setPlayerMark(player, "@duoshou-turn", {"sanshou_red", "sanshou_basic", "sanshou_damage"})
    elseif event == fk.EventAcquireSkill then
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local a, b, c = true, true, true
      local use = nil
      U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        use = e.data[1]
        if use.from == player.id then
          if use.card.color == Card.Red then
            a = false
          end
          if use.card.type == Card.TypeBasic then
            b = false
          end
          return not (a or b)
        end
      end, turn_event.id)
      local mark = {}
      if a then
        table.insert(mark, "sanshou_red")
      end
      if b then
        table.insert(mark, "sanshou_basic")
      end
      U.getActualDamageEvents(room, 1, function (e)
        use = e.data[1]
        if use.from == player then
          c = false
          return true
        end
      end, nil, turn_event.id)
      if c then
        table.insert(mark, "sanshou_damage")
      end
      room:setPlayerMark(player, "@duoshou-turn", #mark > 0 and mark or 0)
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@duoshou-turn", 0)
    end
  end,
}
local duoshou_targetmod = fk.CreateTargetModSkill{
  name = "#duoshou_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(duoshou) and card and card.color == Card.Red and
    table.contains(U.getMark(player, "@duoshou-turn"), "sanshou_red")
  end,
}

weilingy:addRelatedSkill(weilingy_trigger)
weilingy:addRelatedSkill(weilingy_filter)
duoshou:addRelatedSkill(duoshou_targetmod)
guanyu:addSkill(weilingy)
guanyu:addSkill(duoshou)

Fk:loadTranslationTable{
  ["olmou__guanyu"] = "谋关羽",
  ["#olmou__guanyu"] = "威震华夏",
  --["illustrator:olmou__guanyu"] = "",
  ["weilingy"] = "威临",
  [":weilingy"] = "每回合限一次，你可以将一张牌当任意一种【杀】或【酒】使用。"..
  "以此法使用的牌指定目标后，你令其与此牌颜色相同的手牌均视为【杀】直到回合结束。",
  ["duoshou"] = "夺首",--三首（雾）
  [":duoshou"] = "锁定技，每回合你首次使用红色牌无距离关系的限制、首次使用基本牌不计入限制的次数、首次造成伤害后摸一张牌。",

  ["#weilingy-viewas"] = "发动 威临，将一张牌当任意属性的【杀】或【酒】使用",
  ["#weilingy_trigger"] = "威临",
  ["#weilingy_filter"] = "威临",
  ["@weilingy-turn"] = "威临",
  ["@duoshou-turn"] = "夺首",
  ["sanshou_red"] = "红",
  ["sanshou_basic"] = "基",
  ["sanshou_damage"] = "伤",

  ["$weilingy1"] = "汝等鼠辈，岂敢与某相抗！",
  ["$weilingy2"] = "义襄千里，威震华夏！",
  ["$duoshou1"] = "今日之敌，必死于我刀下！",
  ["$duoshou2"] = "青龙所向，战无不胜！",
  ["~olmou__guanyu"] = "玉碎不改白，竹焚不毁节……",
}

local taishici = General(extension, "olmou__taishici", "wu", 4)
local ol__dulie = fk.CreateTriggerSkill{
  name = "ol__dulie",
  events = {fk.TargetConfirming},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 and
    (data.card.trueName == "slash" or data.card:isCommonTrick()) and
    data.from ~= player.id and U.isOnlyTarget(player, data, event)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
    "#ol__dulie-invoke:" .. data.from .. "::" .. data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = 1
    data.extra_data = data.extra_data or {}
    data.extra_data.ol__dulie = data.extra_data.ol__dulie or {}
    table.insert(data.extra_data.ol__dulie, player.id)
  end,
}
local ol__dulie_delay = fk.CreateTriggerSkill{
  name = "#ol__dulie_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:getAttackRange() > 0 and
    data.extra_data and data.extra_data.ol__dulie and table.contains(data.extra_data.ol__dulie, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local x = player:getAttackRange()
    if x > 0 then
      player:drawCards(math.min(5, x), ol__dulie.name)
    end
  end,
}
local douchan = fk.CreateTriggerSkill{
  name = "douchan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      local room = player.room
      return player:getMark("@douchan") < #room.players or table.find(room.draw_pile, function (id)
        return Fk:getCardById(id).trueName == "duel"
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("duel")
    if #cards > 0 then
      room:obtainCard(player, cards[1], true, fk.ReasonPrey)
    else
      local x = player:getMark("@douchan")
      if x < #room.players then
        room:setPlayerMark(player, "@douchan", x + 1)
        room:addPlayerMark(player, MarkEnum.SlashResidue)
      end
    end
  end,
}
local douchan_attackrange = fk.CreateAttackRangeSkill{
  name = "#douchan_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@douchan")
  end,
}
ol__dulie:addRelatedSkill(ol__dulie_delay)
douchan:addRelatedSkill(douchan_attackrange)
taishici:addSkill(ol__dulie)
taishici:addSkill(douchan)

Fk:loadTranslationTable{
  ["olmou__taishici"] = "谋太史慈",
  ["#olmou__taishici"] = "矢志全忠孝",
  --["illustrator:olmou__taishici"] = "",
  ["ol__dulie"] = "笃烈",
  [":ol__dulie"] = "每回合限一次，当你成为其他角色使用基本牌或普通锦囊牌的唯一目标时，"..
  "你可以令此牌的效果结算两次，然后此牌结算结束后，你摸X张牌（X为你的攻击范围且至多为5）。",
  ["douchan"] = "斗缠",
  [":douchan"] = "锁定技，准备阶段，若牌堆中：有【决斗】，你从牌堆中获得一张【决斗】；"..
  "没有【决斗】，你的攻击范围和出牌阶段使用【杀】的次数上限+1（增加次数至多为游戏人数）。",

  ["#ol__dulie-invoke"] = "是否发动 笃烈，令%src对你使用的%arg结算两次",
  ["#ol__dulie_delay"] = "笃烈",
  ["@douchan"] = "斗缠",

  ["$ol__dulie1"] = "秉同难共患之义，莫敢辞也。",
  ["$ol__dulie2"] = "慈赴府君之急，死又何惧尔？",
  ["$douchan1"] = "此时不捉孙策，更待何时！",
  ["$douchan2"] = "有胆气者，都随我来！",
  ["~olmou__taishici"] = "人生得遇知己，死又何憾……",
}



return extension
