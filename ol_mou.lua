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
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
      local to = room:getPlayerById(self.cost_data.tos[1])
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
          if turn ~= nil and player:hasSkill(self, true) then
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
    if #choices > 0 then
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
    return player == target and data.card.trueName == "slash" and data.card.color == Card.Red and
    player:getMark("@@ol_ex__zhaxiang-turn") > 0
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
      local card = Fk:getCardById(id, true)
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
  before_use = function(self, player, use)
    local room = player.room
    use.extra_data = use.extra_data or {}
    use.extra_data.weilingy_user = player.id
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
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.weilingy_user == player.id and data.card.color ~= Card.NoColor
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to
    local color = data.card:getColorString()
    for _, pid in ipairs(TargetGroup:getRealTargets(data.tos)) do
      to = room:getPlayerById(pid)
      if not to.dead then
        local mark = to:getTableMark("@weilingy-turn")
        if table.insertIfNeed(mark, color) then
          room:setPlayerMark(to, "@weilingy-turn", mark)
          to:filterHandcards()
        end
      end
    end
  end,
}
local weilingy_filter = fk.CreateFilterSkill{
  name = "#weilingy_filter",
  card_filter = function(self, to_select, player)
    if not table.contains(player.player_cards[Player.Hand], to_select.id) then return false end
    local mark = player:getTableMark("@weilingy-turn")
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
    table.contains(player:getTableMark("@duoshou-turn"), "sanshou_damage")
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getTableMark("@duoshou-turn")
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
      local mark = player:getTableMark("@duoshou-turn")
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
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
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
      room.logic:getActualDamageEvents(1, function (e)
        use = e.data[1]
        if use.from == player then
          c = false
          return true
        end
        return false
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
    table.contains(player:getTableMark("@duoshou-turn"), "sanshou_red")
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
      self.cost_data = {tos = to, cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data.cards, self.name, player, player)
    data.additionalEffect = 1
    local targets = AimGroup:getAllTargets(data.tos)
    for _, pid in ipairs(targets) do
      if pid ~= self.cost_data.tos[1] then
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
      local targets = player.room:getUseExtraTargets(data, true)
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
    room:moveCardIntoEquip(player, U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards"), self.name)
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
    room:moveCardIntoEquip(player, U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards"), self.name)
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
  [":shenliy"] = "每阶段限一次，当你于出牌阶段内使用【杀】选择目标后，你可以令所有其他角色均成为此【杀】的目标。"..
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
}

local pangtong = General(extension, "olmou__pangtong", "shu", 3)
local hongtu = fk.CreateTriggerSkill{
  name = "hongtu",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase > 1 and target.phase < 8 then
      local x = 0
      local room = player.room
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            x = x + #move.moveInfo
            if x > 1 then return true end
          end
        end
      end, phase_event.id)
      return x > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, self.name)
    if player.dead or player:getHandcardNum() < 3 or #room.alive_players < 2 then return false end
    local tos, ids = room:askForChooseCardsAndPlayers(player, 3, 3, table.map(room:getOtherPlayers(player, false),
    Util.IdMapper), 1, 1, ".|.|.|hand", "#hongtu-give", self.name, false)
    player:showCards(ids)
    --不判位置了，展示牌后发动的技能还是去死好了
    local to = room:getPlayerById(tos[1])
    local use = U.askForUseRealCard(room, to, ids, ".", self.name, "#hongtu-use",
    {expand_pile = ids, bypass_times = true}, true, true)
    if use then
      table.sort(ids, function (a, b)
        return Fk:getCardById(a).number > Fk:getCardById(b).number
      end)
      local hongtuBig = (Fk:getCardById(ids[1]).number ~= Fk:getCardById(ids[2]).number)
      local hongtuSmall = (Fk:getCardById(ids[2]).number ~= Fk:getCardById(ids[3]).number)
      room:useCard(use)
      if not player.dead then
        local handcards = player:getCardIds(Player.Hand)
        local to_discard = table.filter(ids, function (id)
          return table.contains(handcards, id) and not player:prohibitDiscard(id)
        end)
        if #to_discard > 0 then
          room:throwCard(table.random(to_discard), self.name, player)
        end
      end
      if to.dead then return false end
      if ids[1] == use.card.id and hongtuBig then
        if room.current == to then
          room:setPlayerMark(to, "hongtu1-turn", 1)
        end
        if not to:hasSkill("feijun", true) then
          room:setPlayerMark(to, "hongtu1", 1)
          room:handleAddLoseSkills(to, "feijun", nil, true, false)
        end
      elseif ids[3] == use.card.id and hongtuSmall then
        room:setPlayerMark(to, "hongtu2", 1)
        if room.current == to then
          room:setPlayerMark(to, "hongtu2-turn", 1)
        end
      elseif ids[2] == use.card.id and hongtuBig and hongtuSmall then
        if room.current == to then
          room:setPlayerMark(to, "hongtu3-turn", 1)
        end
        if not to:hasSkill("re__qianxi", true) then
          room:setPlayerMark(to, "hongtu3", 1)
          room:handleAddLoseSkills(to, "re__qianxi", nil, true, false)
        end
      end
    else
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      }
      if not player.dead then
        room:damage{
          from = player,
          to = player,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and not target.dead
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    if player:getMark("hongtu1") > 0 and player:getMark("hongtu1-turn") == 0 then
      room:setPlayerMark(player, "hongtu1", 0)
      if player:hasSkill("feijun", true) then
        table.insert(skills, "-feijun")
      end
    end
    if player:getMark("hongtu2") > 0 and player:getMark("hongtu2-turn") == 0 then
      room:setPlayerMark(player, "hongtu2", 0)
    end
    if player:getMark("hongtu3") > 0 and player:getMark("hongtu3-turn") == 0 then
      room:setPlayerMark(player, "hongtu3", 0)
      if player:hasSkill("re__qianxi", true) then
        table.insert(skills, "-re__qianxi")
      end
    end
    if #skills > 0 then
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    end
  end,
}
local hongtu_maxcards = fk.CreateMaxCardsSkill{
  name = "#hongtu_maxcards",
  correct_func = function(self, player)
    if player:getMark("hongtu2") > 0 then
      return 2
    end
  end,
}
local qiwu = fk.CreateTriggerSkill{
  name = "qiwu",
  events = {fk.DamageInflicted},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 and not player:isNude() and
    data.from and (data.from == player or player:inMyAttackRange(data.from)) and player:getMark("qiangwu_record-turn") == 0 and
    #player.room.logic:getActualDamageEvents(1, function(e)
      if e.data[1].to == player then
        player.room:setPlayerMark(player, "qiangwu_record-turn", 1)
        return true
      end
    end) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|heart,diamond", "#qiwu-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    return true
  end,
}
hongtu:addRelatedSkill(hongtu_maxcards)
pangtong:addSkill(hongtu)
pangtong:addSkill(qiwu)
pangtong:addRelatedSkill("feijun")
pangtong:addRelatedSkill("re__qianxi")
Fk:loadTranslationTable{
  ["olmou__pangtong"] = "谋庞统",
  ["#olmou__pangtong"] = "定鼎巴蜀",
  ["illustrator:olmou__pangtong"] = "黯荧岛工作室",
  ["hongtu"] = "鸿图",
  [":hongtu"] = "一名角色的阶段结束时，若你于此阶段内得到过的牌数大于1，你可以摸三张牌，展示三张手牌并选择一名其他角色。"..
  "其可以使用其中一张牌，随机弃置另一张牌，若其以此法使用的牌：为这三张牌中唯一点数最大的牌，其于其的下个回合结束之前拥有〖飞军〗；"..
  "不为这三张牌中点数最大的牌且不为这三张牌中点数最小的牌，其于其的下个回合结束之前拥有〖潜袭〗；"..
  "为这三张牌中唯一点数最小的牌，其于其的下个回合结束之前手牌上限+2。若其未以此法使用牌，你对其与你各造成1点火焰伤害。",
  ["qiwu"] = "栖梧",
  [":qiwu"] = "每回合限一次，当你受到伤害时，若你于当前回合内未受到过伤害且来源为你或来源在你的攻击范围内，"..
  "你可以弃置一张红色牌，你防止此伤害。",

  ["#hongtu-give"] = "鸿图：选择三张手牌并选择一名其他角色，其可以使用其中一张",
  ["#hongtu-use"] = "鸿图：选择一张牌使用",
  ["#qiwu-invoke"] = "是否发动 栖梧，弃置一张红色牌来防止伤害",

  ["$hongtu1"] = "当下春风正好，君可扶摇而上。",
  ["$hongtu2"] = "得卧龙凤雏相助，主公大业可成。",
  ["$qiwu1"] = "诶~没打着~",
  ["$qiwu2"] = "除了飞来的暗箭，无物可伤我。",
  ["~olmou__pangtong"] = "未与孔明把酒锦官城，恨也，恨也……",
}

local kongrong = General(extension, "olmou__kongrong", "qun", 4)
local liwen = fk.CreateTriggerSkill{
  name = "liwen",
  events = {fk.GameStart, fk.CardUsing, fk.CardResponding, fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return player:getMark("@kongrong_virtuous") < 5
      elseif target == player then
        if event == fk.CardUsing or event == fk.CardResponding then
          return data.extra_data and data.extra_data.liwen_triggerable and player:getMark("@kongrong_virtuous") < 5
        else
          return player:getMark("@kongrong_virtuous") > 0 and
            table.find(player.room:getOtherPlayers(player, false), function (p)
              return p:getMark("@kongrong_virtuous") < 5
            end)
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "special")
      room:addPlayerMark(player, "@kongrong_virtuous", math.min(3, 5 - player:getMark("@kongrong_virtuous")))
    elseif event == fk.CardUsing or event == fk.CardResponding then
      room:notifySkillInvoked(player, self.name, "special")
      room:addPlayerMark(player, "@kongrong_virtuous", 1)
    else
      local avilTar = table.map(table.filter(room:getOtherPlayers(player, false), function (p)
        return p:getMark("@kongrong_virtuous") < 5
      end), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, avilTar, 1, player:getMark("@kongrong_virtuous"), "#liwen-choose", self.name, true)
      if #tos > 0 then
        room:sortPlayersByAction(tos)
      end
      room:notifySkillInvoked(player, self.name, "support", tos)
      for _, id in ipairs(tos) do
        local to = room:getPlayerById(id)
        room:removePlayerMark(player, "@kongrong_virtuous", 1)
        room:addPlayerMark(to, "@kongrong_virtuous", 1)
      end
      local targets = {}
      for i = 5, 1, -1 do
        for _, p in ipairs(room:getAlivePlayers(false)) do
          if p:getMark("@kongrong_virtuous") == i then
            table.insert(targets, p)
          end
        end
      end
      for _, p in ipairs(targets) do
        if not p.dead then
          local use = nil
          if not p:isKongcheng() then
            use = U.askForUseRealCard(room, p, p:getCardIds("h"), nil, self.name,
              "#liwen-use:"..player.id, {bypass_times = true}, true, true)
          end
          if use then
            use.extraUse = true
            room:useCard(use)
          else
            local n = p:getMark("@kongrong_virtuous")
            room:setPlayerMark(p, "@kongrong_virtuous", 0)
            if not player.dead then
              player:drawCards(n, self.name)
            end
          end
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.CardResponding},  --FIXME: 该改成记录器了
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString() == player:getMark("liwen_suit") or data.card.type == player:getMark("liwen_type") then
      data.extra_data = data.extra_data or {}
      data.extra_data.liwen_triggerable = true
    end
    if data.card.suit == Card.NoSuit then
      room:setPlayerMark(player, "liwen_suit", 0)
    else
      room:setPlayerMark(player, "liwen_suit", data.card:getSuitString())
    end
    room:setPlayerMark(player, "liwen_type", data.card.type)
    room:setPlayerMark(player, "@liwen_record", {data.card:getSuitString(true), data.card:getTypeString()})
  end,
}
local ol__zhengyi = fk.CreateTriggerSkill{
  name = "ol__zhengyi",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target:getMark("@kongrong_virtuous") > 0 and data.damageType == fk.NormalDamage and
      table.find(player.room:getOtherPlayers(target), function (p)
        return p:getMark("@kongrong_virtuous") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(target, false), function (p)
      return p:getMark("@kongrong_virtuous") > 0
    end)
    local result = U.askForJointChoice(targets, {"yes", "no"}, self.name,
      "#ol__zhengyi-choice::"..target.id..":"..data.damage, true)
    local n = 0
    for _, p in ipairs(targets) do
      if result[p.id] == "yes" and p.hp > n then
        n = p.hp
      end
    end
    if n == 0 then return end
    for _, p in ipairs(room:getAlivePlayers(false)) do
      if result[p.id] == "yes" and p.hp == n then
        self.cost_data = p
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(self.cost_data.id, {target.id})
    room:loseHp(self.cost_data, data.damage, self.name)
    return true
  end,
}
kongrong:addSkill(liwen)
kongrong:addSkill(ol__zhengyi)
Fk:loadTranslationTable{
  ["olmou__kongrong"] = "谋孔融",
  ["#olmou__kongrong"] = "豪气贯长虹",
  ["illustrator:olmou__kongrong"] = "alien",

  ["liwen"] = "立文",
  [":liwen"] = "游戏开始时，你获得三枚“贤”标记；当你使用或打出牌时，若此牌与你使用或打出的上一张牌花色或类别相同，你获得一枚“贤”标记；"..
  "回合结束时，你需将任意个“贤”标记分配给等量的角色（每名角色“贤”标记上限为5个），然后有“贤”标记的角色按照标记从多到少的顺序，依次使用一张手牌，"..
  "若其不使用，移去其“贤”标记，你摸等量的牌。",
  ["ol__zhengyi"] = "争义",
  [":ol__zhengyi"] = "当有“贤”标记的角色受到非属性伤害时，其他有“贤”标记的角色同时选择是否失去体力，若有角色同意，则防止此伤害，同意的"..
  "角色中体力值最大的角色失去等同于此伤害值的体力。",
  ["@kongrong_virtuous"] = "贤",
  ["@liwen_record"] = "立文",
  ["#liwen-choose"] = "立文：你可以将“贤”标记交给其他角色各一枚（每名角色至多5枚）",
  ["#liwen-use"] = "立文：请使用一张手牌，否则你弃置所有“贤”标记，%src 摸牌",
  ["#ol__zhengyi-choice"] = "争义：是否失去%arg点体力，防止 %dest 受到的伤害？（只有选“是”的体力值最大的角色会失去体力）",

  ["$liwen1"] = "伐竹筑学宫，大庇天下士子。",
  ["$liwen2"] = "学而不厌，诲人不倦，何有于我哉。",
  ["$ol__zhengyi1"] = "保纳舍藏者，融也，当坐之。",
  ["$ol__zhengyi2"] = "子曰当仁不让，当义，亦不能让。",
  ["~olmou__kongrong"] = "为父将去，子何以不辞？",
}

local sunjian = General(extension, "olmou__sunjian", "wu", 4, 5)
local hulie = fk.CreateTriggerSkill{
  name = "hulie",
  anim_type = "offensive",
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.trueName == "duel") and
      #AimGroup:getAllTargets(data.tos) == 1 and player:getMark("hulie_"..data.card.trueName.."-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#hulie-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "hulie_"..data.card.trueName.."-turn", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.hulie = player.id
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
local hulie_delay = fk.CreateTriggerSkill{
  name = "#hulie_delay",
  mute = true,
  events ={fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and not data.damageDealt and data.extra_data and data.extra_data.hulie == player.id and
      table.find(TargetGroup:getRealTargets(data.tos), function (id)
        local p = player.room:getPlayerById(id)
        return not p.dead and not p:isProhibited(player, Fk:cloneCard("slash")) and p ~= player
      end)
  end,
  on_trigger = function (self, event, target, player, data)
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      if player.dead then break end
      local p = player.room:getPlayerById(id)
      if not p.dead and not p:isProhibited(player, Fk:cloneCard("slash")) and p ~= player then
        self:doCost(event, p, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "hulie", nil, "#hulie-slash::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, target, player, self.name, true)
  end,
}
local yipo = fk.CreateTriggerSkill{
  name = "yipo",
  events = {fk.HpChanged},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.hp > 0 and
      data.extra_data and data.extra_data.yipo
  end,
  on_cost = function (self, event, target, player, data)
    local n = math.max(player:getLostHp(), 1)
    local success, dat = player.room:askForUseActiveSkill(player, "yipo_active", "#yipo-invoke:::"..n, true, nil, false)
    if success and dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.targets[1])
    local n = math.max(player:getLostHp(), 1)
    if self.cost_data.interaction[11] == "r" then
      to:drawCards(n, self.name)
      if not to.dead then
        room:askForDiscard(to, 1, 1, true, self.name, false)
      end
    else
      to:drawCards(1, self.name)
      if not to.dead then
        room:askForDiscard(to, n, n, true, self.name, false)
      end
    end
  end,

  refresh_events = {fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and player.hp > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getTableMark(self.name)
    if not table.contains(mark, player.hp) then
      data.extra_data = data.extra_data or {}
      data.extra_data.yipo = true
      table.insert(mark, player.hp)
      player.room:setPlayerMark(player, self.name, mark)
    end
  end,
}
local yipo_active = fk.CreateActiveSkill{
  name = "yipo_active",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local n = math.max(Self:getLostHp(), 1)
    local choices = {"#yinghun-draw:::"..n}
    if n > 1 then
      choices = {"#yinghun-draw:::"..n, "#yinghun-discard:::"..n}
    end
    return UI.ComboBox { choices = choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
}
hulie:addRelatedSkill(hulie_delay)
Fk:addSkill(yipo_active)
sunjian:addSkill(hulie)
sunjian:addSkill(yipo)
Fk:loadTranslationTable{
  ["olmou__sunjian"] = "谋孙坚",
  ["#olmou__sunjian"] = "乌程侯",
  ["illustrator:olmou__sunjian"] = "",
  ["~olmou__sunjian"] = "江东子弟们，我先走一步了……",

  ["hulie"] = "虎烈",
  [":hulie"] = "每回合各限一次，当你使用【杀】或【决斗】指定唯一目标后，你可以令此牌伤害+1。此牌结算后，若未造成伤害，你可以令目标角色视为"..
  "对你使用一张【杀】。",
  ["yipo"] = "毅魄",
  [":yipo"] = "当你的体力值变化后，若当前体力值大于0且为本局游戏首次变化到，你可以选择一名角色并选择一项：1.其摸X张牌，然后弃置一张牌；"..
  "2.其摸一张牌，然后弃置X张牌。（X为你已损失体力值，至少为1）",
  ["#hulie-invoke"] = "虎烈：是否令此%arg伤害+1？",
  ["#hulie-slash"] = "虎烈：是否令 %dest 视为对你使用【杀】？",
  ["yipo_active"] = "毅魄",
  ["#yipo-invoke"] = "毅魄：你可以令一名角色：摸%arg张牌然后弃一张牌，或摸一张牌然后弃%arg张牌",

  ["$hulie1"] = "匹夫犯我，吾必斩之。",
  ["$hulie2"] = "鼠辈，这一刀下去定让你看不到明天的太阳。",
  ["$yipo1"] = "乱臣贼子，天地不容。",
  ["$yipo2"] = "年少束发从羽林，纵死不改报国志。",
  ["$yipo3"] = "身既死兮神以灵，魂魄毅兮为鬼雄！",
}

local yuanshu = General(extension, "olmou__yuanshu", "qun", 4)
local jinming = fk.CreateTriggerSkill{
  name = "jinming",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.TurnStart then
        return player:hasSkill(self) and #player:getTableMark(self.name) < 4
      elseif event == fk.TurnEnd then
        return player:getMark("@jinming") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local all_choices = {"jinming1", "jinming2", "jinming3", "jinming4"}
      local choices = table.simpleClone(all_choices)
      for _, n in ipairs(player:getTableMark(self.name)) do
        table.removeOne(choices, "jinming"..n)
      end
      local choice = room:askForChoice(player, choices, self.name, "#jinming-choice", false, all_choices)
      room:setPlayerMark(player, "@jinming", tonumber(choice[8]))
    elseif event == fk.TurnEnd then
      local n = player:getMark("@jinming")
      player:drawCards(n, self.name)
      if not table.contains(player:getTableMark(self.name), n) then
        local count = 0
        if n == 1 then
          room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e)
            local recover = e.data[1]
            if recover.who.id == player.id then
              count = count + recover.num
              return true
            end
          end, Player.HistoryTurn)
        elseif n == 2 then
          room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from == player.id and move.moveReason == fk.ReasonDiscard then
                count = count + #move.moveInfo
                if count > 1 then
                  return true
                end
              end
            end
          end, Player.HistoryTurn)
        elseif n == 3 then
          local types = {}
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data[1]
            if use.from == player.id then
              table.insertIfNeed(types, use.card.type)
              if #types > 2 then
                return true
              end
            end
          end, Player.HistoryTurn)
          count = #types
        elseif n == 4 then
          player.room.logic:getActualDamageEvents(1, function(e)
            local damage = e.data[1]
            if damage.from == player then
              count = count + damage.damage
              if count > 3 then
                return true
              end
            end
          end)
        end
        if count < n then
          room:addTableMark(player, self.name, n)
        end
      end
    end
  end,
}
local xiaoshi = fk.CreateTriggerSkill{
  name = "xiaoshi",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      #player.room:getUseExtraTargets(data, true) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, room:getUseExtraTargets(data, true), 1, 1,
      "#xiaoshi-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insert(data.tos, self.cost_data)
    data.extra_data = data.extra_data or {}
    data.extra_data.xiaoshi = player.id
  end,
}
local xiaoshi_delay = fk.CreateTriggerSkill{
  name = "#xiaoshi_delay",
  anim_type = "negative",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.xiaoshi == player.id and
      not data.damageDealt and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function (id)
      return not room:getPlayerById(id).dead
    end)
    if #targets == 0 or player:getMark("@jinming") == 0 then
      room:loseHp(player, 1, "xiaoshi")
    else
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xiaoshi-draw:::"..player:getMark("@jinming"), "xiaoshi", true)
      if #to > 0 then
        room:getPlayerById(to[1]):drawCards(player:getMark("@jinming"), "xiaoshi")
      else
        room:loseHp(player, 1, "xiaoshi")
      end
    end
  end,
}
local yanliangy = fk.CreateTriggerSkill{
  name = "yanliangy$",
  attached_skill_name = "yanliangy&",

  refresh_events = {fk.AfterPropertyChange},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(self, true)
    end) then
      room:handleAddLoseSkills(player, self.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. self.attached_skill_name, nil, false, true)
    end
  end,

  on_acquire = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.kingdom == "qun" then
        room:handleAddLoseSkills(p, self.attached_skill_name, nil, false, true)
      end
    end
  end
}
local yanliangy_active = fk.CreateActiveSkill{
  name = "yanliangy&",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#yanliangy&",
  can_use = function(self, player)
    return player.kingdom == "qun" and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      player:canUse(Fk:cloneCard("analeptic"))
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function (self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):hasSkill("yanliangy")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, "yanliangy", nil, true, player.id)
    room:useVirtualCard("analeptic", nil, player, player, "yanliangy")
  end,
}
xiaoshi:addRelatedSkill(xiaoshi_delay)
Fk:addSkill(yanliangy_active)
yuanshu:addSkill(jinming)
yuanshu:addSkill(xiaoshi)
yuanshu:addSkill(yanliangy)
Fk:loadTranslationTable{
  ["olmou__yuanshu"] = "谋袁术",
  ["#olmou__yuanshu"] = "画脂镂冰",
  ["illustrator:olmou__yuanshu"] = "",

  ["jinming"] = "矜名",
  [":jinming"] = "锁定技，回合开始时，你选择一项条件：1.回复过1点体力；2.弃置过两张牌；3.使用过三种类型的牌；4.造成过4点伤害。"..
  "回合结束时，你摸X张牌，然后若你本回合未满足条件，你删除此选项（X为你上次发动〖矜名〗选择项的序号）。",
  ["xiaoshi"] = "枭噬",
  [":xiaoshi"] = "出牌阶段内限一次，当你使用基本牌或普通锦囊牌指定目标时，可以额外指定一个目标（无距离限制），若此牌未造成伤害，你失去1点体力或"..
  "令其中一个目标摸X张牌（X为你上次发动〖矜名〗选择项的序号）。",
  ["yanliangy"] = "厌粱",
  [":yanliangy"] = "主公技，其他群势力角色出牌阶段限一次，其可以交给你一张装备牌，视为使用一张【酒】。",
  ["#jinming-choice"] = "矜名：选择一项条件，回合结束时摸序号数的牌，若未达到条件则删除选项",
  ["jinming1"] = "[1]回复过1点体力",
  ["jinming2"] = "[2]弃置过两张牌",
  ["jinming3"] = "[3]使用过三张类型的牌",
  ["jinming4"] = "[4]造成过4点伤害",
  ["@jinming"] = "矜名",
  ["#xiaoshi-choose"] = "枭噬：你可以为%arg额外指定一个目标",
  ["#xiaoshi_delay"] = "枭噬",
  ["#xiaoshi-draw"] = "枭噬：你须令其中一名目标角色摸%arg张牌，或点“取消”失去1点体力！",
  ["yanliangy&"] = "厌粱",
  [":yanliangy&"] = "出牌阶段限一次，你可以交给谋袁术一张装备牌，视为使用一张【酒】。",
  ["#yanliangy&"] = "厌粱：你可以交给谋袁术一张装备牌，视为使用一张【酒】",
}

local huaxiong = General(extension, "olmou__huaxiong", "qun", 6)
local bojue = fk.CreateActiveSkill{
  name = "bojue",
  anim_type = "offensive",
  prompt = "#bojue",
  card_num = 0,
  target_num = 1,
  times = function(self)
    return Self.phase == Player.Play and 2 - Self:usedSkillTimes(self.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    local extra_data = {
      num = 1,
      min_num = 1,
      include_equip = true,
      skillName = self.name,
      pattern = ".",
    }
    local req = Request:new({player, target}, "AskForUseActiveSkill")
    req.focus_text = self.name
    req:setData(player, { "discard_skill", "#bojue-ask:"..target.id, true, extra_data })
    req:setData(target, { "discard_skill", "#bojue-ask:"..player.id, true, extra_data })
    -- player.request_data = json.encode({ "discard_skill", "#bojue-ask:"..target.id, true, extra_data })
    -- target.request_data = json.encode({ "discard_skill", "#bojue-ask:"..player.id, true, extra_data })
    -- room:notifyMoveFocus({player, target}, self.name)
    -- room:doBroadcastRequest("AskForUseActiveSkill", {player, target})

    local moves, n = {}, 0
    for _, p in ipairs(req.players) do
      local result = req:getResult(p)
      if result then
        if result == "" then
          n = n + 1
          if not p.dead then
            p:drawCards(1, self.name)  --FIXME: 万恶的BeforeDrawCard时机
          end
        else
          n = n - 1
          local replyCard = result.card
          table.insert(moves, {
            ids = replyCard.subcards,
            from = p.id,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonDiscard,
            proposer = p.id,
            skillName = self.name,
          })
        end
      end
    end
    if #moves > 0 then
      room:moveCards(table.unpack(moves))
    end
    if n == 0 then
      if not player.dead and not target.dead and not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name, "#bojue-discard::"..target.id)
        room:throwCard(card, self.name, target, player)
      end
      if not player.dead and not target.dead and not player:isNude() then
        local card = room:askForCardChosen(target, player, "he", self.name, "#bojue-discard::"..player.id)
        room:throwCard(card, self.name, player, target)
      end
    elseif n == 2 then
      if not target.dead then
        room:useVirtualCard("slash", nil, player, target, self.name, true)
      end
      if not player.dead then
        room:useVirtualCard("slash", nil, target, player, self.name, true)
      end
    end
  end,
}
local yangwei = fk.CreateTriggerSkill{
  name = "yangwei",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw and
          player:getMark("yangwei1_count-turn") > 1 and player:getMark("yangwei1-turn") == 0 then
          return true
        end
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard and
          player:getMark("yangwei2_count-turn") > 1 and player:getMark("yangwei2-turn") == 0 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw and
        player:getMark("yangwei1_count-turn") > 1 and player:getMark("yangwei1-turn") == 0 then
        room:setPlayerMark(player, "yangwei1-turn", 1)
        room:addPlayerMark(player, "@yangwei1", 1)
      end
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard and
        player:getMark("yangwei2_count-turn") > 1 and player:getMark("yangwei2-turn") == 0 then
        room:setPlayerMark(player, "yangwei2-turn", 1)
        room:addPlayerMark(player, "@yangwei2", 1)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event == nil then return end
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw then
        room:addPlayerMark(player, "yangwei1_count-turn", #move.moveInfo)
      end
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard then
        room:addPlayerMark(player, "yangwei2_count-turn", #move.moveInfo)
      end
    end
  end,
}
local yangwei_trigger = fk.CreateTriggerSkill{
  name = "#yangwei_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DamageCaused then
        return player:getMark("@yangwei1") > 0
      else
        return player:getMark("@yangwei2") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yangwei")
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, "yangwei", "offensive")
      data.damage = data.damage + player:getMark("@yangwei1")
      room:setPlayerMark(player, "@yangwei1", 0)
    else
      room:notifySkillInvoked(player, "yangwei", "negative")
      data.damage = data.damage + player:getMark("@yangwei2")
      room:setPlayerMark(player, "@yangwei2", 0)
    end
  end,
}
yangwei:addRelatedSkill(yangwei_trigger)
huaxiong:addSkill(bojue)
huaxiong:addSkill(yangwei)
Fk:loadTranslationTable{
  ["olmou__huaxiong"] = "谋华雄",
  ["#olmou__huaxiong"] = "汜水关死神",
  ["illustrator:olmou__huaxiong"] = "",
  ["~olmou__huaxiong"] = "我已连战三场，匹夫胜之不武！",

  ["bojue"] = "搏决",
  [":bojue"] = "出牌阶段限两次，你可以与一名其他角色同时选择摸或弃置一张牌，若你与其牌数因此变化之和为：0，你与其弃置对方一张牌；2，你与其"..
  "视为对对方使用一张【杀】。",
  ["yangwei"] = "扬威",
  [":yangwei"] = "锁定技，当你一回合于摸牌阶段外摸至少两张牌后，你下一次造成伤害+1；当你一回合于弃牌阶段外弃置至少两张牌后，你下一次受到伤害+1。",
  ["#bojue"] = "搏决：与一名角色同时选择摸或弃一张牌，根据双方选择执行效果",
  ["#bojue-ask"] = "搏决：与 %src 同时选择摸或弃一张牌",
  ["#bojue-discard"] = "搏决：弃置 %dest 一张牌",
  ["@yangwei1"] = "伤害+",
  ["@yangwei2"] = "受伤+",
  ["#yangwei_trigger"] = "扬威",

  ["$bojue1"] = "匹夫，今日便让你尝尝我大刀之利！",
  ["$bojue2"] = "孙坚！你若有胆，便与我一对一！",
  ["$yangwei1"] = "本将军刀下，不分强弱，只问生死。",
  ["$yangwei2"] = "敌将何在？速来受死！",
}

local dongzhuo = General(extension, "olmou__dongzhuo", "qun", 4)
local guanbian = fk.CreateTriggerSkill{
  name = "guanbian",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(player, "@guanbian-round", #room.players)
  end,

  refresh_events = {fk.RoundEnd, fk.AfterSkillEffect},
  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(self, true) then
      if event == fk.RoundEnd then
        return true
      else
        return target == player and (data.name == "xiongni" or data.name == "fengshang")
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-guanbian", nil, true, false)
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@guanbian-round", 0)
  end,
}
local guanbian_distance = fk.CreateDistanceSkill{
  name = "#guanbian_distance",
  correct_func = function(self, from, to)
    return from:getMark("@guanbian-round") + to:getMark("@guanbian-round")
  end,
}
local guanbian_maxcards = fk.CreateMaxCardsSkill{
  name = "#guanbian_maxcards",
  correct_func = function(self, player)
    return player:getMark("@guanbian-round")
  end,
}
local xiongni = fk.CreateTriggerSkill{
  name = "xiongni",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, nil, "#xiongni-invoke", true)
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player, false), Util.IdMapper))
    local suit = Fk:getCardById(self.cost_data.cards[1]):getSuitString()
    room:throwCard(self.cost_data.cards, self.name, player, player)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        if suit == "log_nosuit" or p:isNude() or
          #room:askForDiscard(p, 1, 1, true, self.name, true, ".|.|"..suit, "#xiongni-discard:"..player.id.."::"..suit) == 0 then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = self.name,
          }
        end
      end
    end
  end,
}
local fengshang = fk.CreateActiveSkill{
  name = "fengshang",
  anim_type = "support",
  prompt = "#fengshang",
  card_num = 0,
  target_num = 0,
  expand_pile = function()
    return Self:getTableMark("fengshang")
  end,
  can_use = function(self, player)
    return player:getMark("fengshang-phase") == 0 and
      table.find(player:getTableMark("fengshang"), function (id)
        return table.find(player:getTableMark("fengshang"), function (id2)
          return id ~= id2 and Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2)) and
            not table.contains(Self:getTableMark("fengshang-round"), Fk:getCardById(id).suit)
        end)
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addPlayerMark(player, "fengshang-phase", 1)
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    cards = table.filter(cards, function (id)
      return table.find(cards, function (id2)
        return id ~= id2 and Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2)) and
          not table.contains(player:getTableMark("fengshang-round"), Fk:getCardById(id).suit)
      end)
    end)

    local targets = table.map(room.alive_players, Util.IdMapper)
    local toStr = function(int) return string.format("%d", int) end
    local residueMap = {}
    for _, pid in ipairs(targets) do
      residueMap[toStr(pid)] = 1
    end
    local data = {
      cards = cards,
      max_num = 1,
      targets = targets,
      residued_list = residueMap,
      expand_pile = cards,
    }

    local list = {}
    local success, dat = room:askForUseActiveSkill(player, "distribution_select_skill",
      "#fengshang-choose", false, data, true)
    if success and dat then
      table.removeOne(targets, dat.targets[1])
      list[dat.targets[1]] = dat.cards
      room:setCardMark(Fk:getCardById(dat.cards[1]), "@DistributionTo", Fk:translate(room:getPlayerById(dat.targets[1]).general))
      room:addTableMark(player, "fengshang-round", Fk:getCardById(dat.cards[1]).suit)
    end
    if #targets > 0 then
      local all_cards = table.filter(cards, function (c)
        return Fk:getCardById(c):compareSuitWith(Fk:getCardById(dat.cards[1]))
      end)
      cards = table.simpleClone(all_cards)
      table.removeOne(cards, dat.cards[1])
      data = {
        cards = cards,
        max_num = 1,
        targets = targets,
        residued_list = residueMap,
        expand_pile = all_cards,
      }
      success, dat = room:askForUseActiveSkill(player, "distribution_select_skill",
        "#fengshang-choose", false, data, true)
      if success and dat then
        list[dat.targets[1]] = dat.cards
      end
    end
    for _, ids in pairs(list) do
      for _, id in ipairs(ids) do
        room:setCardMark(Fk:getCardById(id), "@DistributionTo", 0)
      end
    end
    room:doYiji(list, player.id, self.name)
    if not player.dead and not list[player.id] then
      local card = Fk:cloneCard("analeptic")
      card.skillName = self.name
      if not player:prohibitUse(Fk:cloneCard("analeptic")) and not player:isProhibited(player, Fk:cloneCard("analeptic")) then
        room:useCard({
          card = card,
          from = player.id,
          tos = {{player.id}},
          extra_data = {
            analepticRecover = player.dying
          },
          extraUse = true,
        })
      end
    end
  end,
}
local fengshang_trigger = fk.CreateTriggerSkill{
  name = "#fengshang_trigger",
  events = {fk.EnterDying},
  mute = true,
  main_skill = fengshang,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fengshang) and player:getMark("fengshang_trigger-turn") == 0 then
      local cards = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryTurn)
      return table.find(cards, function (id)
        return table.find(cards, function (id2)
          return id ~= id2 and Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2)) and
            not table.contains(player:getTableMark("fengshang-round"), Fk:getCardById(id).suit)
        end)
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fengshang")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("fengshang")
    room:setPlayerMark(player, "fengshang_trigger-turn", 1)
    fengshang:onUse(room, {
      from = player.id,
      cards = {},
      tos = {},
    })
    room:removePlayerMark(player, "fengshang-phase", 1)
  end,

  refresh_events = {fk.StartPlayCard},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengshang)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "fengshang", cards)
  end,
}
local zhibing = fk.CreateTriggerSkill{
  name = "zhibing$",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      if player:getMark("@zhibing") > 2 and not table.contains(player:getTableMark(self.name), 1) then
        return true
      end
      if player:getMark("@zhibing") > 5 and not table.contains(player:getTableMark(self.name), 2) then
        return not player:hasSkill("ty_ex__fencheng", true)
      end
      if player:getMark("@zhibing") > 8 and not table.contains(player:getTableMark(self.name), 3) then
        return not player:hasSkill("benghuai", true)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@zhibing") > 2 and not table.contains(player:getTableMark(self.name), 1) then
      room:addTableMark(player, self.name, 1)
      room:changeMaxHp(player, 1)
      if not player.dead and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
    if player:getMark("@zhibing") > 5 and not table.contains(player:getTableMark(self.name), 2) and
      not player:hasSkill("ty_ex__fencheng", true) then
      room:addTableMark(player, self.name, 2)
      room:handleAddLoseSkills(player, "ty_ex__fencheng", nil, true, false)
    end
    if player:getMark("@zhibing") > 8 and not table.contains(player:getTableMark(self.name), 3) and
      not player:hasSkill("benghuai", true) then
      room:addTableMark(player, self.name, 3)
      room:handleAddLoseSkills(player, "benghuai", nil, true, false)
    end
    if #player:getTableMark(self.name) == 3 then
      room:setPlayerMark(player, "@zhibing", 0)
    end
  end,

  --[[on_acquire = function (self, player)  --盲猜其实不会触发
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if room:getPlayerById(use.from).kingdom == "qun" and use.card.color == Card.Black then
        room:addPlayerMark(player, "@zhibing", 1)
      end
    end, Player.HistoryGame)
  end,]]--

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@zhibing", 0)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self, true) and target ~= player and
      target.kingdom == "qun" and data.card.color == Card.Black and
      table.find({1, 2, 3}, function (i)
        return not table.contains(player:getTableMark(self.name), i)
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhibing", 1)
  end,
}
guanbian:addRelatedSkill(guanbian_distance)
guanbian:addRelatedSkill(guanbian_maxcards)
fengshang:addRelatedSkill(fengshang_trigger)
dongzhuo:addSkill(guanbian)
dongzhuo:addSkill(xiongni)
dongzhuo:addSkill(fengshang)
dongzhuo:addSkill(zhibing)
dongzhuo:addRelatedSkill("ty_ex__fencheng")
dongzhuo:addRelatedSkill("benghuai")
Fk:loadTranslationTable{
  ["olmou__dongzhuo"] = "谋董卓",
  ["#olmou__dongzhuo"] = "翦覆四海",
  --["illustrator:olmou__dongzhuo"] = "",

  ["guanbian"] = "观变",
  [":guanbian"] = "锁定技，游戏开始时，你的手牌上限、其他角色与你的距离、你与其他角色的距离+X。首轮结束后或你发动〖凶逆〗或〖封赏〗后，"..
  "你失去此技能。（X为游戏人数）",
  ["xiongni"] = "凶逆",
  [":xiongni"] = "出牌阶段开始时，你可以弃置一张牌，所有其他角色需弃置一张与花色相同的牌，否则你对其造成1点伤害。",
  ["fengshang"] = "封赏",
  [":fengshang"] = "出牌阶段限一次，或有角色进入濒死状态时（每回合限一次），你可以将本回合弃牌堆中两张花色相同的牌分配给等量角色"..
  "（每轮每种花色限一次），若你未以此法获得牌，你视为使用一张不计入次数的【酒】。",
  ["zhibing"] = "执柄",
  [":zhibing"] = "主公技，锁定技，准备阶段，若其他群雄势力角色累计使用黑色牌达到：3张，你加1点体力上限并回复1体力；6张，你获得〖焚城〗；"..
  "9张，你获得〖崩坏〗",
  ["@guanbian-round"] = "观变",
  ["#xiongni-invoke"] = "凶逆：你可以弃一张牌，所有其他角色选择弃一张相同花色的牌或你对其造成1点伤害",
  ["#xiongni-discard"] = "凶逆：弃置一张%arg牌，否则 %src 对你造成1点伤害！",
  ["#fengshang"] = "封赏：你可以将本回合弃牌堆中两张花色相同的牌分配给等量角色",
  ["#fengshang-choose"] = "封赏：分配其中两张花色相同的牌",
  ["#fengshang_trigger"] = "封赏",
  ["@zhibing"] = "执柄",

  ["$guanbian1"] = "今日，老夫也想尝尝这鹿血的滋味！",
  ["$guanbian2"] = "这水搅得越浑，这鱼便越好捉。",
  ["$xiongni1"] = "不愿做我殿上宾客？哼哼！那便做我刀下鬼！",
  ["$xiongni2"] = "尔等，要试试我宝剑锋利否？",
  ["$fengshang1"] = "干了这杯酒，你便是老夫生死弟兄！",
  ["$fengshang2"] = "来来来！金杯共汝饮，荣华共汝享！",
  ["$zhibing1"] = "老夫为这大汉江山是操碎了心呐。",
  ["$zhibing2"] = "老夫言尽于此，哪个敢说半个不字？",
  ["$ty_ex__fencheng_olmou__dongzhuo"] = "焚城为焰，炙脍犒三军！",
  ["~olmou__dongzhuo"] = "关东鼠辈，怎敢忤逆天命！",
}

local dengai = General(extension, "olmou__dengai", "wei", 4, 5)
local jigud = fk.CreateTriggerSkill{
  name = "jigud",
  anim_type = "special",
  frequency = Skill.Compulsory,
  derived_piles = "dengai_grain",
  events = {fk.AfterCardsMove, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove and #player:getPile("dengai_grain") < player.maxHp then
        local room = player.room
        local cards = {}
        for _, move in ipairs(data) do
          if move.from == nil and move.moveReason == fk.ReasonUse then
            local move_event = room.logic:getCurrentEvent()
            local use_event = move_event.parent
            if use_event ~= nil and use_event.event == GameEvent.UseCard then
              local use = use_event.data[1]
              if room:getPlayerById(use.from).phase ~= Player.Play then
                local card_ids = room:getSubcardsByRule(use.card)
                for _, info in ipairs(move.moveInfo) do
                  if table.contains(card_ids, info.cardId) and table.contains(room.discard_pile, info.cardId) then
                    table.insertIfNeed(cards, info.cardId)
                  end
                end
              end
            end
          end
        end
        cards = U.moveCardsHoldingAreaCheck(room, cards)
        cards = table.filter(cards, function (id)
          return Fk:getCardById(id).suit ~= Card.Heart
        end)
        if #cards > 0 then
          self.cost_data = cards
          return true
        end
      elseif event == fk.TurnStart then
        self.cost_data = nil
        return target.maxHp == player.maxHp and #player:getPile("dengai_grain") > 0 and not player:isKongcheng()
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    if event == fk.AfterCardsMove then
      player:addToPile("dengai_grain", self.cost_data, true, self.name, player.id)
    elseif event == fk.TurnStart then
      local room = player.room
      local cids = room:askForArrangeCards(player, self.name,
      {
        player:getPile("dengai_grain"), player:getCardIds("h"),
        "dengai_grain", "$Hand"
      }, "#jigud-exchange", true)
      U.swapCardsWithPile(player, cids[1], cids[2], self.name, "dengai_grain")
    end
  end,
}
local jiewan = fk.CreateTriggerSkill{
  name = "jiewan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if target.phase == Player.Start then
        return not player:isKongcheng()
      elseif target.phase == Player.Finish then
        return player:getHandcardNum() == #player:getPile("dengai_grain") and
          table.find(player.room:getOtherPlayers(player, false), function (p)
            return player.maxHp <= p.maxHp
          end)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if target.phase == Player.Start then
      local success, dat = player.room:askForUseActiveSkill(player, "jiewan_active", "#jiewan-invoke", true)
      if success and dat then
        self.cost_data = {cards = dat.cards}
        return true
      end
    elseif target.phase == Player.Finish then
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if target.phase == Player.Start then
      if #self.cost_data.cards > 0 then
        room:moveCardTo(self.cost_data.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
      else
        room:changeMaxHp(player, -1)
      end
      if player.dead or player:isKongcheng() then return end
      local success, dat = room:askForUseActiveSkill(player, "jiewan_viewas", "#jiewan-use", true, {bypass_distances = true})
      if success and dat then
        room:sortPlayersByAction(dat.targets)
        local targets = table.map(dat.targets, Util.Id2PlayerMapper)
        room:useVirtualCard("snatch", dat.cards, player, targets, self.name)
      end
    elseif target.phase == Player.Finish then
      room:changeMaxHp(player, 1)
    end
  end,
}
local jiewan_active = fk.CreateActiveSkill{
  name = "jiewan_active",
  min_card_num = 0,
  max_card_num = 2,
  target_num = 0,
  expand_pile = "dengai_grain",
  card_filter = function(self, to_select, selected)
    return #selected < 2 and table.contains(Self:getPile("dengai_grain"), to_select)
  end,
  feasible = function (self, selected, selected_cards)
    return #selected_cards == 0 or #selected_cards == 2
  end,
}
local jiewan_viewas = fk.CreateViewAsSkill{
  name = "jiewan_viewas",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(Self:getCardIds("h"), to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("snatch")
    card.skillName = "jiewan"
    card:addSubcard(cards[1])
    return card
  end,
}
Fk:addSkill(jiewan_active)
Fk:addSkill(jiewan_viewas)
dengai:addSkill(jigud)
dengai:addSkill(jiewan)
Fk:loadTranslationTable{
  ["olmou__dengai"] = "谋邓艾",
  ["#olmou__dengai"] = "壮士解腕",

  ["jigud"] = "积谷",
  [":jigud"] = "锁定技，一名角色于其出牌阶段外使用的牌置入弃牌堆后，若“谷”数小于你的体力上限，将其中的非<font color='red'>♥</font>牌置于"..
  "你的武将牌上，称为“谷”。体力上限与你相同的角色回合开始时，你用任意张手牌替换等量“谷”。",
  ["jiewan"] = "解腕",
  [":jiewan"] = "每个准备阶段，你可以减1点体力上限或移除两张“谷”，然后你可以将一张手牌当无距离限制的【顺手牵羊】使用。每个结束阶段，"..
  "若你的“谷”数与手牌数相同且你的体力上限不为全场唯一最多，你加1点体力上限。",
  ["dengai_grain"] = "谷",
  ["#jigud-exchange"] = "积谷：用任意张手牌交换等量的“谷”",
  ["jiewan_active"] = "解腕",
  ["#jiewan-invoke"] = "解腕：移去两张“谷”，或不选“谷”减1点体力上限，然后将一张手牌当无距离限制的【顺手牵羊】使用",
  ["jiewan_viewas"] = "解腕",
  ["#jiewan-use"] = "解腕：将一张手牌当无距离限制的【顺手牵羊】使用",
}

local gongsunzan = General(extension, "olmou__gongsunzan", "qun", 4)
local jiaodi = fk.CreateTriggerSkill{
  name = "jiaodi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if player:getAttackRange() >= to:getAttackRange() then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      if not to:isKongcheng() then
        local card = room:askForCardChosen(player, to, "h", self.name, "#jiaodi-prey::"..to.id)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
        if player.dead or to.dead then return end
      end
    end
    if player:getAttackRange() <= to:getAttackRange() then
      if not to:isAllNude() then
        local card = room:askForCardChosen(player, to, "hej", self.name, "#jiaodi-discard::"..to.id)
        room:throwCard(card, self.name, to, player)
        if player.dead then return end
      end
      local targets = room:getUseExtraTargets(data, false, true)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, 1, "#jiaodi-choose:::"..data.card:toLogString(), self.name, false)
        AimGroup:addTargets(room, data, tos[1])
      end
    end
  end,
}
local jiaodi_attackrange = fk.CreateAttackRangeSkill{
  name = "#jiaodi_attackrange",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    if from:hasSkill(jiaodi) then
      local baseValue = 1
      local weapons = from:getEquipments(Card.SubtypeWeapon)
      if #weapons > 0 then
        baseValue = 0
        for _, id in ipairs(weapons) do
          local weapon = Fk:getCardById(id)
          baseValue = math.max(baseValue, weapon:getAttackRange(from) or 1)
        end
      end

      local status_skills = Fk:currentRoom().status_skills[AttackRangeSkill] or Util.DummyTable
      local max_fixed, correct = nil, 0
      for _, skill in ipairs(status_skills) do
        if skill ~= self then
          local f = skill:getFixed(from)
          if f ~= nil then
            max_fixed = max_fixed and math.max(max_fixed, f) or f
          end
          local c = skill:getCorrect(from)
          correct = correct + (c or 0)
        end
      end

      return from.hp - math.max(math.max(baseValue, (max_fixed or 0)) + correct, 0)
    end
  end,
}
local baojing = fk.CreateActiveSkill{
  name = "baojing",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#baojing",
  interaction = UI.ComboBox {choices = {"+1", "-1"}},
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
    if self.interaction.data == "+1" then
      room:addPlayerMark(target, "@baojing_add", 1)
    else
      room:addPlayerMark(target, "@baojing_minus", 1)
    end
    room:setPlayerMark(player, self.name, {target.id, self.interaction.data})
  end,
}
local baojing_trigger = fk.CreateTriggerSkill{
  name = "#baojing_trigger",

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("baojing") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local info = player:getMark("baojing")
    room:setPlayerMark(player, "baojing", 0)
    local to = room:getPlayerById(info[1])
    if not to.dead then
      local mark = info[2] == "+1" and "@baojing_add" or "@baojing_minus"
      room:removePlayerMark(to, mark, 1)
    end
  end,
}
local baojing_attackrange = fk.CreateAttackRangeSkill{
  name = "#baojing_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@baojing_add") - from:getMark("@baojing_minus")
  end,
}
jiaodi:addRelatedSkill(jiaodi_attackrange)
baojing:addRelatedSkill(baojing_attackrange)
baojing:addRelatedSkill(baojing_trigger)
gongsunzan:addSkill(jiaodi)
gongsunzan:addSkill(baojing)
Fk:loadTranslationTable{
  ["olmou__gongsunzan"] = "谋公孙瓒",
  ["#olmou__gongsunzan"] = "辽海龙吟",
  ["illustrator:olmou__gongsunzan"] = "西国红云",

  ["jiaodi"] = "剿狄",
  [":jiaodi"] = "锁定技，你的攻击范围始终等于你的当前体力值。当你使用【杀】指定唯一目标时，若目标的攻击范围不大于你，你令此【杀】伤害+1，"..
  "然后获得该角色一张手牌；若目标的攻击范围不小于你，你弃置该角色区域内一张牌，选择一名角色成为此【杀】的额外目标。",
  ["baojing"] = "保京",
  [":baojing"] = "出牌阶段限一次，你可以令一名其他角色的攻击范围+1/-1，直到你的下个出牌阶段开始。",
  ["#jiaodi-prey"] = "剿狄：获得 %dest 一张手牌",
  ["#jiaodi-discard"] = "剿狄：弃置 %dest 区域内一张牌",
  ["#jiaodi-choose"] = "剿狄：选择一名角色成为此%arg额外目标",
  ["#baojing"] = "保京：令一名角色攻击范围+1/-1直到你下个出牌阶段开始",
  ["@baojing_add"] = "攻击范围+",
  ["@baojing_minus"] = "攻击范围-",
}

local huangyueying = General(extension, "olmou__huangyueying", "shu", 3, 3, General.Female)
local bingcai = fk.CreateTriggerSkill{
  name = "bingcai",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.type == Card.TypeBasic and not player:isKongcheng() then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        return use.card.type == Card.TypeBasic
      end, Player.HistoryTurn)
      return #events == 1 and events[1] == player.room.logic:getCurrentEvent()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local i = data.card.is_damage_card and 1 or 2
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|.|.|trick",
      "#bingcai"..i.."-invoke:::"..data.card:toLogString())
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(self.cost_data.cards[1])
    room:recastCard(self.cost_data.cards, player, self.name)
    if (card.is_damage_card and data.card.is_damage_card) or
      (not card.is_damage_card and not data.card.is_damage_card) then
      data.additionalEffect = (data.additionalEffect or 0) + 1
    end
  end,
}
local lixian = fk.CreateViewAsSkill{
  name = "lixian",
  frequency = Skill.Compulsory,
  pattern = "slash,jink",
  prompt = "#lixian",
  interaction = function(self)
    local all_names = {"slash", "jink"}
    local names = U.getViewAsCardNames(Self, self.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@lixian-inhand") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
}
local lixian_trigger = fk.CreateTriggerSkill{
  name = "#lixian_trigger",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lixian) and target.phase == Player.Finish then
      local cards = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.card.type == Card.TypeTrick and not use.card:isVirtual() and table.contains(player.room.discard_pile, use.card.id) and
          use.tos and table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
          table.insertIfNeed(cards, use.card.id)
        end
      end, Player.HistoryTurn)
      if #cards > 0 then
        self.cost_data = {cards = cards}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(self.cost_data.cards, Card.PlayerHand, player, fk.ReasonJustMove, "lixian", nil, true, player.id,
      "@@lixian-inhand")
  end,
}
local lixian_prohibit = fk.CreateProhibitSkill{
  name = "#lixian_prohibit",
  prohibit_use = function(self, player, card)
    return card:getMark("@@lixian-inhand") > 0
  end
}
lixian:addRelatedSkill(lixian_trigger)
lixian:addRelatedSkill(lixian_prohibit)
huangyueying:addSkill(bingcai)
huangyueying:addSkill(lixian)
Fk:loadTranslationTable{
  ["olmou__huangyueying"] = "谋黄月英",
  ["#olmou__huangyueying"] = "才惠双绝",

  ["bingcai"] = "并才",
  [":bingcai"] = "每回合第一张基本牌被使用时，你可以重铸一张锦囊牌。若这两张牌均为伤害类或非伤害类，则此牌额外结算一次。",
  ["lixian"] = "理贤",
  [":lixian"] = "锁定技，每个结束阶段，你获得弃牌堆中所有本回合使用的目标包含你的锦囊牌。你以此法获得的牌仅可当作【杀】或【闪】使用。",
  ["#bingcai1-invoke"] = "并才：是否重铸一张锦囊牌？若为伤害类，此%arg额外结算一次",
  ["#bingcai2-invoke"] = "并才：是否重铸一张锦囊牌？若不为伤害类，此%arg额外结算一次",
  ["#lixian_trigger"] = "理贤",
  ["#lixian"] = "理贤：将“理贤”牌当【杀】或【闪】使用",
  ["@@lixian-inhand"] = "理贤",
}

local jvshou = General(extension, "olmou__jvshou", "qun", 3)
local guliang = fk.CreateTriggerSkill{
  name = "guliang",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#guliang-invoke::"..data.from..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    if data.card.sub_type == Card.SubtypeDelayedTrick then
      AimGroup:cancelTarget(data, player.id)
    else
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
    player.room:setPlayerMark(player, "@@guliang-turn", data.from)
  end,
}
local guliang_delay = fk.CreateTriggerSkill{
  name = "#guliang_delay",
  anim_type = "negative",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@guliang-turn") == target.id and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player.id)
  end,
}
local xutu = fk.CreateTriggerSkill{
  name = "xutu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  derived_piles = "xutu_supplies",
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart and target.phase == Player.Finish and #player:getPile("xutu_supplies") > 0 then
        local cards = {}
        player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            if move.toArea == Card.DiscardPile then
              for _, info in ipairs(move.moveInfo) do
                if table.contains(player.room.discard_pile, info.cardId) then
                  table.insertIfNeed(cards, info.cardId)
                end
              end
            end
          end
        end, Player.HistoryTurn)
        if #cards > 0 then
          self.cost_data = cards
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:addToPile("xutu_supplies", room:getNCards(3), true, self.name, player.id)
    elseif event == fk.EventPhaseStart then
      local card_data = {
        {"xutu_supplies", player:getPile("xutu_supplies")},
        {"pile_discard", self.cost_data},
      }
      local cards = room:askForPoxi(player, self.name, card_data, nil, false)
      local cards1, cards2 = {cards[1]}, {cards[2]}
      if table.contains(player:getPile("xutu_supplies"), cards[2]) then
        cards1, cards2 = {cards[2]}, {cards[1]}
      end
      room:moveCards({
        ids = cards1,
        from = player.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonExchange,
        skillName = self.name,
        proposer = player.id,
        moveVisible = true,
      },
      {
        ids = cards2,
        to = player.id,
        toArea = Card.PlayerSpecial,
        specialName = "xutu_supplies",
        moveReason = fk.ReasonExchange,
        skillName = self.name,
        proposer = player.id,
        moveVisible = true,
      })
      if player.dead then return end
      local pile = player:getPile("xutu_supplies")
      if #pile == 3 and
        (table.every(pile, function (id)
          return Fk:getCardById(id).number == Fk:getCardById(pile[1]).number
        end) or
        table.every(pile, function (id)
          return Fk:getCardById(id):compareSuitWith(Fk:getCardById(pile[1]))
        end)) then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#xutu-give", self.name, false)
        to = room:getPlayerById(to[1])
        room:moveCardTo(player:getPile("xutu_supplies"), Card.PlayerHand, to, fk.ReasonJustMove, self.name, nil, true, to.id)
        if player:hasSkill(self) and #player:getPile("xutu_supplies") < 3 then
          player:addToPile("xutu_supplies", room:getNCards(3 - #player:getPile("xutu_supplies")), true, self.name, player.id)
        end
      end
    end
  end,
}
Fk:addPoxiMethod{
  name = "xutu",
  prompt = function (data, extra_data)
    return "#xutu"
  end,
  card_filter = function (to_select, selected, data, extra_data)
    if data and #selected < 2 then
      for _, id in ipairs(selected) do
        for _, v in ipairs(data) do
          if table.contains(v[2], id) and table.contains(v[2], to_select) then
            return false
          end
        end
      end
      return true
    end
  end,
  feasible = function(selected, data)
    return data and #selected == 2
  end,
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}
guliang:addRelatedSkill(guliang_delay)
jvshou:addSkill(guliang)
jvshou:addSkill(xutu)
Fk:loadTranslationTable{
  ["olmou__jvshou"] = "谋沮授",
  ["#olmou__jvshou"] = "三军监统",

  ["guliang"] = "固粮",
  [":guliang"] = "每回合限一次，其他角色对你使用牌时，你可令此牌对你无效，若如此做，你无法响应其对你使用的牌直到回合结束。",
  ["xutu"] = "徐图",
  [":xutu"] = "锁定技，游戏开始时，你将牌堆顶三张牌置于你的武将牌上，称为“资”。每个结束阶段，你将本回合弃牌堆的一张牌与一张“资”交换，然后"..
  "令一名角色获得三张花色或点数相同的“资”，若如此做，你将“资”补至三张。",
  ["#guliang-invoke"] = "固粮：是否令 %dest 对你使用的%arg无效，本回合你不能响应其对你使用的牌？",
  ["@@guliang-turn"] = "固粮",
  ["#guliang_delay"] = "固粮",
  ["xutu_supplies"] = "资",
  ["#xutu"] = "徐图：将本回合弃牌堆的一张牌与一张“资”交换",
  ["#xutu-give"] = "徐图：令一名角色获得“资”",
}

local zhangfei = General(extension, "olmou__zhangfei", "shu", 4)
local jingxian = fk.CreateActiveSkill{
  name = "jingxian",
  anim_type = "support",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  prompt = "#jingxian",
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not table.contains(Self:getTableMark("jingxian-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "jingxian-phase", target.id)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead or target.dead then return end
    if #effect.cards == 2 then
      target:drawCards(1, self.name)
      if player.dead then return end
      player:drawCards(1, self.name)
      if player.dead then return end
      local cards = room:getCardsFromPileByRule("slash", 1, "drawPile")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      end
    else
      local choice = room:askForChoice(target, {"jingxian1:"..player.id, "jingxian2:"..player.id}, self.name)
      if choice[9] == "1" then
        target:drawCards(1, self.name)
        if player.dead then return end
        player:drawCards(1, self.name)
      end
    end
  end,
}
local xiayong = fk.CreateActiveSkill{
  name = "xiayong",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#xiayong",
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
    room:addTableMark(player, self.name, target.id)
    if player.drank == 0 then
      player.drank = 1
      room:broadcastProperty(player, "drank")
    end
  end,
}
local xiayong_delay = fk.CreateTriggerSkill{
  name = "#xiayong_delay",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return table.contains(player:getTableMark("xiayong"), target.id) and data.tos and not target.dead and
      table.find(TargetGroup:getRealTargets(data.tos), function (id)
        return id ~= target.id
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = room:askForUseCard(player, "xiayong", "slash", "#xiayong-invoke::"..target.id, true,
      {
        must_targets = {target.id},
        bypass_distances = true,
      })
    if use then
      use.extraUse = true
      use.extra_data = use.extra_data or {}
      use.extra_data.xiayongUser = player.id
      room:useCard(use)
    end
  end,

  refresh_events = {fk.TargetSpecified, fk.AfterTurnEnd, fk.AfterCardUseDeclared, fk.EventTurnChanging},
  can_refresh = function (self, event, target, player, data)
    if event == fk.TargetSpecified then
      return target == player and (data.extra_data or {}).xiayongUser == player.id
    elseif event == fk.AfterTurnEnd then
      return table.contains(player:getTableMark("xiayong"), target.id)
    elseif player:getMark("xiayong") ~= 0 and player.drank == 0 then
      if event == fk.AfterCardUseDeclared then
        return target == player
      elseif event == fk.EventTurnChanging then
        return true
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      if not to.dead then
        to:addQinggangTag(data)
      end
    elseif event == fk.AfterTurnEnd then
      local mark = player:getTableMark("xiayong")
      for i = #mark, 1, -1 do
        if mark[i] == target.id then
          table.remove(mark, i)
        end
      end
      if #mark == 0 then
        room:setPlayerMark(player, "xiayong", 0)
      else
        room:setPlayerMark(player, "xiayong", mark)
      end
    else
      player.drank = 1
      room:broadcastProperty(player, "drank")
    end
  end,
}
xiayong:addRelatedSkill(xiayong_delay)
zhangfei:addSkill(jingxian)
zhangfei:addSkill(xiayong)
Fk:loadTranslationTable{
  ["olmou__zhangfei"] = "谋张飞",
  ["#olmou__zhangfei"] = "虎烈匡国",

  ["jingxian"] = "敬贤",
  [":jingxian"] = "出牌阶段每名角色限一次，你可以交给其至多两张非基本牌，然后其选择等量项：1.其与你各摸一张牌；2.令你从牌堆中获得一张【杀】。",
  ["xiayong"] = "狭勇",
  [":xiayong"] = "出牌阶段限一次，你可以选择一名其他角色，直到其下个回合结束：你处于【酒】的状态；其对除其以外的角色使用牌后，你可以对其使用"..
  "一张无视防具的【杀】。",
  ["#jingxian"] = "敬贤：交给一名角色至多两张非基本牌，其选择等量项",
  ["jingxian1"] = "与 %src 各摸一张牌",
  ["jingxian2"] = "%src 获得一张【杀】",
  ["#xiayong"] = "狭勇：选择一名角色，直到其回合结束，你始终处于“酒”状态且当其使用牌后可以对其使用【杀】",
  ["#xiayong_delay"] = "狭勇",
  ["#xiayong-invoke"] = "狭勇：是否对 %dest 使用一张无视防具的【杀】？",
}

local zhaoyun = General(extension, "olmou__zhaoyun", "shu", 4)
local nilan = fk.CreateTriggerSkill{
  name = "nilan",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.skillName ~= self.name
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"draw2", "Cancel"}
    if table.find(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      table.insert(choices, 1, "nilan1")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#nilan-choice", false, {"nilan1", "draw2", "Cancel"})
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not (self.cost_data and self.cost_data.extra_data and self.cost_data.nilan_delay) then
      if self.cost_data.choice == "nilan1" then
        room:addTableMark(player, self.name, "draw2")
      else
        room:addTableMark(player, self.name, "nilan1")
      end
    end
    if self.cost_data.choice == "nilan1" then
      local yes = table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id) and Fk:getCardById(id).trueName == "slash"
      end)
      player:throwAllCards("h")
      if not player.dead and yes and #room:getOtherPlayers(player, false) > 0 then
        local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
          "#nilan-damage", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          room:damage{
            from = player,
            to = to,
            damage = 1,
            skillName = self.name,
          }
        end
      end
    else
      player:drawCards(2, self.name)
    end
  end,
}
local nilan_delay = fk.CreateTriggerSkill{
  name = "#nilan_delay",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("nilan") ~= 0
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local choices = player:getTableMark("nilan")
    room:setPlayerMark(player, "nilan", 0)
    for _, choice in ipairs(choices) do
      if player.dead then return end
      if choice == "draw2" or
        table.find(player:getCardIds("h"), function (id)
          return not player:prohibitDiscard(id)
        end) then
        self.cost_data = {choice = choice}
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "nilan", nil, "#nilan-invoke:::"..self.cost_data.choice)
  end,
  on_use = function (self, event, target, player, data)
    nilan.cost_data = {choice = self.cost_data.choice, extra_data = {nilan_delay = true}}
    nilan:use(event, target, player, data)
  end,
}
local jueya = fk.CreateViewAsSkill{
  name = "jueya",
  pattern = ".|.|.|.|.|basic",
  prompt = "#jueya",
  interaction = function(self)
    local all_names = U.getAllCardNames("b")
    return U.CardNameBox {
      choices = U.getViewAsCardNames(Self, self.name, all_names, nil, Self:getTableMark(self.name)),
      all_choices = all_names,
    }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function (self, player, use)
    player.room:addTableMark(player, self.name, use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return player:isKongcheng() and
      #U.getViewAsCardNames(player, self.name, U.getAllCardNames("b"), nil, player:getTableMark(self.name)) > 0
  end,
  enabled_at_response = function(self, player, response)
    if response or not player:isKongcheng() then return end
    return #U.getViewAsCardNames(player, self.name, U.getAllCardNames("b"), nil, player:getTableMark(self.name)) > 0
  end,
}
nilan:addRelatedSkill(nilan_delay)
zhaoyun:addSkill(nilan)
zhaoyun:addSkill(jueya)
Fk:loadTranslationTable{
  ["olmou__zhaoyun"] = "谋赵云",
  ["#olmou__zhaoyun"] = "白首之心",

  ["nilan"] = "逆澜",
  [":nilan"] = "当你不因此技能造成伤害后，你可以执行一项：1.弃置所有手牌，若其中有【杀】，则你可以对一名其他角色造成1点伤害；2.摸两张牌。"..
  "若如此做，你下一次受到伤害后可以执行另一项。",
  ["jueya"] = "绝崖",
  [":jueya"] = "若你没有手牌，你可以于需要时视为使用一张基本牌（每种牌名限一次）。",
  ["#nilan-choice"] = "逆澜：你可以执行一项，下次受到伤害后可以执行另一项",
  ["nilan1"] = "弃置所有手牌，若其中有【杀】，可以对一名角色造成1点伤害",
  ["#nilan-damage"] = "逆澜：你可以对一名其他角色造成1点伤害",
  ["#nilan_delay"] = "逆澜",
  ["#nilan-invoke"] = "逆澜：是否%arg",
  ["#jueya"] = "绝崖：视为使用一张基本牌",
}

local zhangxiu = General(extension, "olmou__zhangxiu", "qun", 4)
local zhuijiao = fk.CreateTriggerSkill{
  name = "zhuijiao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" then
      local dat = nil
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id ~= player.room.logic:getCurrentEvent().id then
          local use = e.data[1]
          if use.from == player.id then
            dat = use
            return true
          end
        end
      end, 1)
      return dat and not dat.damageDealt
    end
  end,
  on_use = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.zhuijiao = true
    player:drawCards(1, self.name)
  end,
}
local zhuijiao_delay = fk.CreateTriggerSkill{
  name = "#zhuijiao_delay",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and not data.damageDealt and data.extra_data and data.extra_data.zhuijiao and
      not player.dead and not player:isNude()
  end,
  on_use = function (self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, "zhuijiao", false)
  end,
}
local choulie = fk.CreateTriggerSkill{
  name = "choulie",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
      "#choulie-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    room:setPlayerMark(to, "@@choulie-turn", 1)
    room:setPlayerMark(player, "choulie-turn", to.id)
  end,
}
local choulie_delay = fk.CreateTriggerSkill{
  name = "#choulie_delay",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes("choulie", Player.HistoryTurn) > 0 and
      player.phase >= Player.Start and player.phase <= Player.Finish and not player:isNude() then
      local to = player.room:getPlayerById(player:getMark("choulie-turn"))
      return not to.dead and player:canUseTo(Fk:cloneCard("slash"), to, {bypass_distances = true, bypass_times = true})
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForDiscard(player, 1, 1, true, "choulie", true, nil, "#choulie-slash::"..player:getMark("choulie-turn"), true)
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("choulie-turn"))
    room:throwCard(self.cost_data.cards, "choulie", player, player)
    if not to.dead then
      local card = Fk:cloneCard("slash")
      card.skillName = "choulie"
      local use = {
        from = player.id,
        tos = {{to.id}},
        card = card,
      }
      use.extraUse = true
      use.extra_data = use.extra_data or {}
      use.extra_data.choulieUser = player.id
      room:useCard(use)
    end
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function (self, event, target, player, data)
    return target == player and (data.extra_data or {}).choulieUser == player.id
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if not to.dead then
      to:addQinggangTag(data)
    end
  end,
}
local choulie_trigger = fk.CreateTriggerSkill{
  name = "#choulie_trigger",
  mute = true,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "choulie") and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForDiscard(player, 1, 1, true, "choulie", true, ".|.|.|.|.|basic,weapon", "#choulie-discard", true)
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data.cards, "choulie", player, player)
    data.nullifiedTargets = data.nullifiedTargets or {}
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
choulie:addRelatedSkill(choulie_delay)
--choulie:addRelatedSkill(choulie_trigger)
zhuijiao:addRelatedSkill(zhuijiao_delay)
zhangxiu:addSkill(choulie)
zhangxiu:addSkill(zhuijiao)
Fk:loadTranslationTable{
  ["olmou__zhangxiu"] = "谋张绣",

  ["choulie"] = "仇猎",
  [":choulie"] = "限定技，回合开始时，你可以选择一名其他角色，本回合你的每个阶段开始时，你可以弃置一张牌视为对其使用一张【杀】，"..
  "其可以弃置一张基本牌或武器牌令此【杀】无效。",
  ["zhuijiao"] = "追剿",
  [":zhuijiao"] = "锁定技，你使用【杀】时，若你使用的上一张牌未造成伤害，则你摸一张牌并令此【杀】伤害+1，此【杀】结算后，若仍未造成伤害，"..
  "你弃置一张牌。",
  ["#choulie-choose"] = "仇猎：选择一名其他角色，本回合每个阶段开始时，你可以弃一张牌视为对其使用【杀】！",
  ["@@choulie-turn"] = "仇猎",
  ["#choulie_delay"] = "仇猎",
  ["#choulie-slash"] = "仇猎：是否弃置一张牌，视为对 %dest 使用一张【杀】？",
  ["#choulie_trigger"] = "仇猎",
  ["#choulie-discard"] = "仇猎：是否弃置一张基本牌或武器牌，令此【杀】对你无效？",
}

return extension
