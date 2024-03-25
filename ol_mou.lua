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
      end, Player.HistoryPhase) > 0 and table.find(player.room.alive_players, function(p) return player:canPindian(p) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
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
        U.askForUseRealCard(room, player, ids, ".", self.name, "#zhuri-use", {expand_pile = ids})
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
    room:setPlayerMark(player, "@@ranji", 1)
  end,
}
local ranji_trigger = fk.CreateTriggerSkill{
  name = "#ranji_trigger",
  mute = true,
  events = {fk.PreHpRecover, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      return target == player and player:getMark("@@ranji") > 0
    elseif event == fk.Death then
      return player:getMark("@@ranji") > 0 and data.damage and data.damage.from and data.damage.from == player
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      return true
    elseif event == fk.Death then
      player.room:setPlayerMark(player, "@@ranji", 0)
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
  ["#zhuri-use"] = "逐日：你可以使用其中一张牌",
  ["lose_zhuri"] = "失去〖逐日〗直到回合结束",
  ["#ranji1-invoke"] = "燃己：是否获得〖困奋〗？",
  ["#ranji2-invoke"] = "燃己：是否获得〖诈降〗？",
  ["#ranji3-invoke"] = "燃己：是否获得〖困奋〗和〖诈降〗？",
  ["ranji-draw"] = "将手牌摸至手牌上限",
  ["ranji-recover"] = "回复体力至体力上限",
  ["@@ranji"] = "燃己",
  ["@@ol_ex__zhaxiang-turn"] = "诈降",

  ["$zhuri1"] = "效逐日之夸父，怀忠志而长存。",
  ["$zhuri2"] = "知天命而不顺，履穷途而强为。",
  ["$ranji1"] = "此身为薪，炬成灰亦昭大汉长明！",
  ["$ranji2"] = "维之一腔骨血，可驱驰来北马否？",
  ["$kunfenEx_olmou__jiangwei"] = "虽千万人，吾往矣！",
  ["$ol_ex__zhaxiang_olmou__jiangwei"] = "亡国之将姜维，请明公驱驰！",
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
    (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
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

local yuanshao = General(extension, "olmou__yuanshao", "qun", 4)

local hetao = fk.CreateTriggerSkill{
  name = "hetao",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude() and target ~= player and data.firstTarget and
    data.card.color ~= Card.NoColor and #U.getActualUseTargets(player.room, data, event) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("he"), function(id)
      local c = Fk:getCardById(id)
      return data.card:compareColorWith(c) and not player:prohibitDiscard(c)
    end)
    local to, card = room:askForChooseCardAndPlayers(player, AimGroup:getAllTargets(data.tos), 1, 1,
    tostring(Exppattern{ id = ids }), "#hetao-choose:::" .. data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = {to[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local dat = table.simpleClone(self.cost_data)
    local room = player.room
    room:throwCard({dat[2]}, self.name, player, player)
    data.additionalEffect = 1
    local targets = AimGroup:getAllTargets(data.tos)
    for _, pid in ipairs(targets) do
      if pid ~= dat[1] then
        table.insert(data.nullifiedTargets, pid)
      end
    end
  end,
}
local shenliy = fk.CreateTriggerSkill{
  name = "shenliy",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" and
    player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local targets = U.getUseExtraTargets(player.room, data, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(target, self.name, nil, "#shenliy-invoke:::"..data.card:toLogString()) then
      room:doIndicate(player.id, self.cost_data)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data)
    room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = targets,
      arg = self.name,
      arg2 = data.card:toLogString()
    }
    local tos = {}
    for _, pid in ipairs(targets) do
      TargetGroup:pushTargets(data.tos, pid)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.shenliy = data.extra_data.shenliy or {}
    table.insert(data.extra_data.shenliy, player.id)
  end,
}
local shenliy_delay = fk.CreateTriggerSkill{
  name = "#shenliy_delay",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.damageDealt and data.extra_data and data.extra_data.shenliy and
    table.contains(data.extra_data.shenliy, player.id) then
      local n = 0
      for _, damage in pairs(data.damageDealt) do
        n = n + damage
      end
      if n > player:getHandcardNum() or n > player.hp then
        self.cost_data = n
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shenliy")
    local n = self.cost_data
    if n > player:getHandcardNum() then
      player:drawCards(math.min(n, 5), "shenliy")
      if player.dead then return false end
    end
    if n > player.hp then
      local card = data.card
      local cardlist = card:isVirtual() and card.subcards or {card.id}
      if #cardlist == 0 or table.every(cardlist, function (id)
        return room:getCardArea(id) == Card.Processing
      end) then
        if not U.isPureCard(data.card) then
          card = Fk:cloneCard(data.card.name)
          card:addSubcard(data.card)
          card.skillName = "shenliy_delay"
        end
        if player:prohibitUse(card) then return false end
        local targets = TargetGroup:getRealTargets(data.tos)
        targets = table.filter(targets, function (pid)
          local p = room:getPlayerById(pid)
          return not (p.dead or player:isProhibited(p, card))
          --FIXME:暂不考虑对特殊目标【杀】的适配，否则则需判modtargetfilter
        end)
        if #targets > 0 then
          room:useCard{
            from = player.id,
            tos = table.map(targets, function (pid) return {pid} end),
            card = card,
            extraUse = true
          }
        end
      end
    end
  end,
}
local yufeng = fk.CreateTriggerSkill{
  name = "yufeng",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local room = player.room
    return player:hasEmptyEquipSlot(Card.SubtypeWeapon) and
    room:getCardArea(U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards")[1]) == Card.Void
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.moveCardIntoEquip(room, player, U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards"), self.name)
  end,
}
local shishouyTriggerable = function (player)
  if #player:getEquipments(Card.SubtypeWeapon) > 0 then return false end
  local room = player.room
  local id = U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards")[1]
  return table.contains({Card.PlayerEquip, Card.DrawPile, Card.DiscardPile, Card.Void}, room:getCardArea(id))
end
local shishouy = fk.CreateTriggerSkill{
  name = "shishouy$",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and shishouyTriggerable(player)) then return false end
    local targets = {}
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
    end
    local room = player.room
    for _, pid in ipairs(targets) do
      local to = room:getPlayerById(pid)
      if not to.dead and to ~= player and to.kingdom == "qun" then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = table.simpleClone(self.cost_data)
    local room = player.room
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local to = room:getPlayerById(pid)
      if not to.dead and to ~= player and to.kingdom == "qun" then
        self:doCost(event, to, player, data)
      end
      if not (player:hasSkill(self) and shishouyTriggerable(player)) then break end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(target, self.name, nil, "#shishouy-invoke:"..player.id) then
      room:doIndicate(target.id, {player.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.moveCardIntoEquip(room, player, U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards"), self.name)
  end,
}
shenliy:addRelatedSkill(shenliy_delay)
yuanshao:addSkill(hetao)
yuanshao:addSkill(shenliy)
yuanshao:addSkill(yufeng)
yuanshao:addSkill(shishouy)
Fk:loadTranslationTable{
  ["olmou__yuanshao"] = "谋袁绍",
  ["#olmou__yuanshao"] = "席卷八荒",
  --["illustrator:olmou__yuanshao"] = "西国红云",

  ["hetao"] = "合讨",
  [":hetao"] = "当其他角色使用牌指定大于一个目标后，你可以弃置一张与此牌颜色相同的牌，令此牌对其中一个目标生效两次且对其他目标无效。",
  ["shenliy"] = "神离",
  [":shenliy"] = "当你于出牌阶段内使用【杀】选择目标后，若你于此阶段内未发动过此技能，你可以令所有其他角色均成为此【杀】的目标。"..
  "此牌结算结束后，若此【杀】造成的伤害值：大于你的手牌数，你摸等同于伤害值数的牌（至多摸五张）；"..
  "大于你的体力值，你对相同目标再次使用此【杀】。",
  --实际上时机是指定目标后，非常离谱……
  ["yufeng"] = "玉锋",
  [":yufeng"] = "锁定技，游戏开始时，你将【思召剑】置入你的装备区。",
  ["shishouy"] = "士首",
  [":shishouy"] = "主公技，当其他群势力角色失去装备区里的牌后，若你的装备区里没有武器牌，其可以将【思召剑】置入你的装备区。",

  ["#hetao-choose"] = "是否发动 合讨，选择一名目标角色，令%arg改为仅对其结算两次",
  ["#shenliy-invoke"] = "是否发动 神离，选择所有其他角色成为此%arg的目标",
  ["#shenliy_delay"] = "神离",
  ["#shishouy-invoke"] = "是否发动%src的 士首，将【思召剑】置入其装备区",

  ["$hetao1"] = "合诸侯之群力，扶大汉之将倾。",
  ["$hetao2"] = "猛虎啸于山野，群士执戈相待。",
  ["$hetao3"] = "合兵讨贼，其利断金！",
  ["$hetao4"] = "众将一心，战无不胜！",
  ["$hetao5"] = "秣马厉兵，今乃报国之时！",
  ["$hetao6"] = "齐心协力，第三造大汉之举！",
  ["$shenliy1"] = "沧海之水难覆，将倾之厦难扶。",
  ["$shenliy2"] = "诸君心怀苟且，安能并力西向？",
  ["$shenliy3"] = "联军离心，各逐其利。",
  ["$shenliy4"] = "什么国恩大义，不过弊履而已！",
  ["$shenliy5"] = "本盟主的话，你听还是不听？",
  ["$shenliy6"] = "尔等皆为墙头草，随风而摆。",
  ["$yufeng1"] = "梦神人授剑，怀神兵济世。",
  ["$yufeng2"] = "士者怎可徒手而战？",
  ["$yufeng3"] = "哼！我剑也未尝不利！",
  ["$shishouy1"] = "今执牛耳，当为天下之先。",
  ["$shishouy2"] = "士者不徒手而战，况其首乎。",
  ["$shishouy3"] = "吾居群士之首，可配剑履否？",
  ["$shishouy4"] = "剑来！",
  ["$shishouy5"] = "今秉七尺之躯，不负三尺之剑！",
  ["$shishouy6"] = "拔剑四顾，诸位识得我袁本初？",
  ["~olmou__yuanshao"] = "众人合而无力，徒负大义也……",
  --["~olmou__yuanshao2"] = "",
}











return extension
