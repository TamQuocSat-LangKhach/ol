
local quhuang = General(extension, "quhuang", "wu", 3)
local qiejian = fk.CreateTriggerSkill{
  name = "qiejian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local targets, targetRecorded = {}, player:getTableMark("qiejian_prohibit-round")
      for _, move in ipairs(data) do
        if move.from and not table.contains(targetRecorded, move.from) then
          local to = player.room:getPlayerById(move.from)
          if to:isKongcheng() and not to.dead and not table.every(move.moveInfo, function (info)
              return info.fromArea ~= Card.PlayerHand end) then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self) then break end
      if not table.contains(player:getTableMark("qiejian_prohibit-round"), target_id) then
        local skill_target = room:getPlayerById(target_id)
        if skill_target and not skill_target.dead then
          self:doCost(event, skill_target, player, data)
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qiejian-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:drawCards(player, 1, self.name)
    if not target.dead then
      room:drawCards(target, 1, self.name)
    end
    if player.dead or target.dead then return false end
    local tos = {}
    if #player:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(tos, player.id)
    end
    if player ~= target and #target:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(tos, target.id)
    end
    if #tos > 0 then
      tos = room:askForChoosePlayers(player, tos, 1, 1, "#qiejian-choose::" .. target.id, self.name, true, true)
    end
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      local id = room:askForCardChosen(player, to, 'ej', self.name)
      room:throwCard({id}, self.name, to, player)
    else
      room:addTableMarkIfNeed(player, "qiejian_prohibit-round", target.id)
    end
  end,
}
local nishouchoicefilter = function(player, id)
  local room = player.room
  local choices = {}
  if player:getMark("@@nishou_exchange-phase") == 0 and room.current and room.current.phase <= Player.Finish and
      room.current.phase >= Player.Start then
    table.insert(choices, "nishou_exchange")
  end
  if room:getCardArea(id) == Card.DiscardPile then
    local card = Fk:cloneCard("lightning")
    card:addSubcard(id)
    if not player:hasDelayedTrick("lightning") and not player:prohibitUse(card) and not player:isProhibited(player, card) then
      table.insert(choices, "nishou_lightning")
    end
  end
  return choices
end
local nishou = fk.CreateTriggerSkill{
  name = "nishou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and #nishouchoicefilter(player, info.cardId) > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local card_ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(card_ids, info.cardId)
          end
        end
      end
    end
    for _, id in ipairs(card_ids) do
      if not player:hasSkill(self) then break end
      if #nishouchoicefilter(player, id) > 0 then
        self.cost_data = id
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = self.cost_data
    local choices = nishouchoicefilter(player, id)
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, "#nishou-choice:::" .. Fk:getCardById(id):toLogString())
    if choice == "nishou_lightning" then
      local card = Fk:cloneCard("lightning")
      card:addSubcard(id)
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    else
      room:addPlayerMark(player, "@@nishou_exchange-phase", 1)
    end
  end,
}
local nishou_delay = fk.CreateTriggerSkill{
  name = "#nishou_delay",
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@nishou_exchange-phase") > 0 and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    local x = player:getHandcardNum()
    for _, p in ipairs(room.alive_players) do
      local y = p:getHandcardNum()
      if y < x then
        x = y
        tos = {}
        table.insert(tos, p.id)
      elseif y == x then
        table.insert(tos, p.id)
      end
    end
    local cancelable = table.removeOne(tos, player.id)
    if #tos == 0 then return false end
    tos = room:askForChoosePlayers(player, tos, 1, 1, "#nishou-choose", nishou.name, cancelable, true)
    if #tos == 0 then return false end
    room:swapAllCards(player, {player, tos[1]}, nishou.name)
  end,
}
nishou:addRelatedSkill(nishou_delay)
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["#quhuang"] = "泥头自缚",
  ["illustrator:quhuang"] = "夜小雨",
  ["designer:quhuang"] = "玄蝶既白",

  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去手牌后，若其没有手牌，你可以与其各摸一张牌，"..
  "然后选择一项：1.弃置你或其场上的一张牌；2.你本轮内不能对其发动此技能。",
  ["nishou"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将此牌当【闪电】使用；"..
  "2.本阶段结束时，你与一名全场手牌数最少的角色交换手牌且本阶段内你无法选择此项。",

  ["#qiejian-invoke"] = "是否对 %dest 使用 切谏",
  ["#qiejian-choose"] = "切谏：选择一名角色，弃置其场上一张牌，或点取消则本轮内不能再对 %dest 发动 切谏",
  ["#nishou-choice"] = "泥首：选择将%arg当做【闪电】使用，或在本阶段结束时与手牌数最少的角色交换手牌",
  ["nishou_lightning"] = "将此装备牌当【闪电】使用",
  ["nishou_exchange"] = "本阶段结束时与手牌数最少的角色交换手牌",
  ["#nishou_delay"] = "泥首",
  ["@@nishou_exchange-phase"] = "泥首",
  ["#nishou-choose"] = "泥首：你需与手牌数最少的角色交换手牌",

  ["$qiejian1"] = "东宫不稳，必使众人生异。",
  ["$qiejian2"] = "今三方鼎持，不宜擅动储君。",
  ["$nishou1"] = "臣以泥涂首，足证本心。",
  ["$nishou2"] = "人生百年，终埋一抔黄土。",
  ["~quhuang"] = "臣死谏于斯，死得其所……",
}

local zhanghua = General(extension, "zhanghua", "jin", 3)
local bihun = fk.CreateTriggerSkill{
  name = "bihun",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getHandcardNum() > player:getMaxCards() and data.to ~= player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if not to.dead and U.isOnlyTarget(to, data, event) and data.firstTarget and U.hasFullRealCard(room, data.card) then
      room:obtainCard(to, data.card, true, fk.ReasonJustMove, player.id, self.name)
    end
    AimGroup:cancelTarget(data, data.to)
    return true
  end,
}
local jianhe = fk.CreateActiveSkill{
  name = "jianhe",
  anim_type = "offensive",
  prompt = "#jianhe-active",
  min_card_num = 2,
  target_num = 1,
  can_use = Util.TrueFunc,
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
    room:setPlayerMark(target, "jianhe-turn", 1)
    local n = #effect.cards
    room:recastCard(effect.cards, player, self.name)
    if #target:getCardIds("he") >= n then
      local type_name = Fk:getCardById(effect.cards[1]):getTypeString()
      local cards = room:askForCard(target, n, n, true, self.name, true,
      ".|.|.|.|.|"..type_name, "#jianhe-choose:::"..n..":"..type_name)
      if #cards > 0 then
        room:recastCard(cards, target, self.name)
        return
      end
    end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = self.name,
    }
  end
}
local chuanwu = fk.CreateTriggerSkill{
  name = "chuanwu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:getAttackRange() > 0 then
      local skills = Fk.generals[player.general]:getSkillNameList(true)
      if player.deputyGeneral ~= "" then
        table.insertTableIfNeed(skills, Fk.generals[player.deputyGeneral]:getSkillNameList(true))
      end
      skills = table.filter(skills, function(s) return player:hasSkill(s, true) end)
      if #skills > 0 then
        self.cost_data = skills
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local skills = table.simpleClone(self.cost_data)
    local n = math.min(player:getAttackRange(), #skills)
    if n == 0 then return false end
    skills = table.slice(skills, 1, n + 1)
    local mark = player:getTableMark("chuanwu")
    table.insertTable(mark, skills)
    player.room:setPlayerMark(player, "chuanwu", mark)
    player.room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
    player:drawCards(n, self.name)
  end,
}
local chuanwu_delay = fk.CreateTriggerSkill{
  name = "#chuanwu_delay",
  events = {fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:getMark("chuanwu") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("chuanwu")
    room:notifySkillInvoked(player, "chuanwu")
    local skills = player:getTableMark("chuanwu")
    room:setPlayerMark(player, "chuanwu", 0)
    room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
  end,
}
chuanwu:addRelatedSkill(chuanwu_delay)
zhanghua:addSkill(bihun)
zhanghua:addSkill(jianhe)
zhanghua:addSkill(chuanwu)
Fk:loadTranslationTable{
  ["zhanghua"] = "张华",
  ["#zhanghua"] = "双剑化龙",
  ["designer:zhanghua"] = "玄蝶既白",
  ["illustrator:zhanghua"] = "匠人绘",
  ["cv:zhanghua"] = "苏至豪",

  ["bihun"] = "弼昏",
  [":bihun"] = "锁定技，当你使用牌指定其他角色为目标时，若你的手牌数大于手牌上限，你取消之并令唯一目标获得此牌。",
  ["jianhe"] = "剑合",
  [":jianhe"] = "出牌阶段每名角色限一次，你可以重铸至少两张同名牌或至少两张装备牌，令一名角色选择一项：1.重铸等量张与之类型相同的牌；2.受到你造成的1点雷电伤害。",
  ["chuanwu"] = "穿屋",
  [":chuanwu"] = "锁定技，当你造成或受到伤害后，你失去你武将牌上前X个技能直到回合结束（X为你的攻击范围），然后摸等同失去技能数张牌。",
  ["#jianhe-active"] = "发动 剑合，选择至少两张同名牌重铸，并选择一名角色",
  ["#jianhe-choose"] = "剑合：你需重铸%arg张%arg2，否则受到1点雷电伤害",
  ["#chuanwu_delay"] = "穿屋",

  ["$bihun1"] = "辅弼天家，以扶朝纲。",
  ["$bihun2"] = "为国治政，尽忠匡辅。",
  ["$jianhe1"] = "身临朝阙，腰悬太阿。",
  ["$jianhe2"] = "位登三事，当配龙泉。",
  ["$chuanwu1"] = "斩蛇穿屋，其志绥远。",
  ["$chuanwu2"] = "祝融侵库，剑怀远志。",
  ["~zhanghua"] = "桑化为柏，此非不祥乎？",
}

local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local users, names, to = {}, {}, nil
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        if use.card.type == Card.TypeBasic then
          table.insert(users, use.from)
          table.insertIfNeed(names, use.card.name)
          return true
        end
      end, Player.HistoryTurn)
      if #users < 2 then return false end
      local n = 0
      if users[1] == player.id then
        n = n + 1
        to = users[2]
      end
      if users[2] == player.id then
        n = n + 1
        to = users[1]
      end
      self.cost_data = nil
      if n == 2 then
        self.cost_data = names
      elseif n == 1 then
        self.cost_data = to
      end
      return n > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "table" then
      U.askForUseVirtualCard(room, player, self.cost_data, nil, self.name, nil, false, true, false, true)
    else
      local to = room:getPlayerById(self.cost_data)
      if not to.dead and not to:isNude() then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:throwCard({id}, self.name, to, player)
      end
    end
  end,
}
dongtuna:addSkill(jianman)
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["#dongtuna"] = "铅刀拿云",
  ["designer:dongtuna"] = "大宝",
  ["illustrator:dongtuna"] = "monkey",
  ["jianman"] = "鹣蛮",
  [":jianman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均为你，你视为使用其中的一张牌；仅其中之一为你，你弃置另一名使用者一张牌。",

  ["$jianman1"] = "鹄巡山野，见腐羝而聒鸣！",
  ["$jianman2"] = "我蛮夷也，进退可无矩。",
  ["~dongtuna"] = "孟获小儿，安敢杀我！",
}

local wangguan = General(extension, "wangguan", "wei", 3)
local miuyan = fk.CreateViewAsSkill{
  name = "miuyan",
  anim_type = "switch",
  switch_skill_name = "miuyan",
  pattern = "fire_attack",
  prompt = function ()
    return "miuyan-prompt-".. Self:getSwitchSkillState("miuyan", false, true)
  end,
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = Util.TrueFunc,
}
local miuyan_trigger = fk.CreateTriggerSkill{
  name = "#miuyan_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(miuyan) and table.contains(data.card.skillNames, "miuyan")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("miuyan", true) == fk.SwitchYang and data.damageDealt then
      local moveInfos = {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then break end
        if not p:isKongcheng() then
          local cards = {}
          for _, id in ipairs(p.player_cards[Player.Hand]) do
            if Fk:getCardById(id):getMark("miuyan-phase") > 0 then
              table.insertIfNeed(cards, id)
            end
          end
          if #cards > 0 then
            table.insert(moveInfos, {
              from = p.id,
              ids = cards,
              to = player.id,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonPrey,
              proposer = player.id,
              skillName = "miuyan",
            })
          end
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    elseif player:getSwitchSkillState("miuyan", true) == fk.SwitchYin and not data.damageDealt then
      room:invalidateSkill(player, "miuyan", "-round")
    end
  end,

  refresh_events = {fk.CardShown},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(data.cardIds) do
      if table.contains(player.player_cards[Player.Hand], id) then
        room:setCardMark(Fk:getCardById(id), "miuyan-phase", 1)
      end
    end
  end,
}
local shilu = fk.CreateTriggerSkill{
  name = "shilu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.hp, self.name)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p) and not p:isKongcheng() end), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#shilu-choose", self.name, false)
    local to = room:getPlayerById(tos[1])
    local id = room:askForCardChosen(player, to, "h", self.name)
    to:showCards(id)
    if room:getCardArea(id) == Card.PlayerHand then
      room:setCardMark(Fk:getCardById(id), "@@shilu-inhand", 1)
      to:filterHandcards()
    end
  end,
}
local shilu_filter = fk.CreateFilterSkill{
  name = "#shilu_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@shilu-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
miuyan:addRelatedSkill(miuyan_trigger)
shilu:addRelatedSkill(shilu_filter)
wangguan:addSkill(miuyan)
wangguan:addSkill(shilu)
Fk:loadTranslationTable{
  ["wangguan"] = "王瓘",
  ["#wangguan"] = "假降误撞",
  ["designer:wangguan"] = "zzcclll朱苦力",
  ["illustrator:wangguan"] = "匠人绘",

  ["miuyan"] = "谬焰",
  [":miuyan"] = "转换技，阳：你可以将一张黑色牌当【火攻】使用，若此牌造成伤害，你获得本阶段展示过的所有手牌；"..
  "阴：你可以将一张黑色牌当【火攻】使用，若此牌未造成伤害，本轮本技能失效。",
  ["shilu"] = "失路",
  [":shilu"] = "锁定技，当你受到伤害后，你摸等同体力值张牌并展示攻击范围内一名其他角色的一张手牌，令此牌视为【杀】。",

  ["miuyan-prompt-yang"] = "将一张黑色牌当【火攻】使用，若造成伤害，获得本阶段展示过的所有手牌",
  ["miuyan-prompt-yin"] = "将一张黑色牌当【火攻】使用，若未造成伤害，本轮“谬焰”失效",
  ["#shilu-choose"] = "失路：展示一名角色的一张手牌，此牌视为【杀】",
  ["@@shilu-inhand"] = "失路",
  ["#shilu_filter"] = "失路",

  ["$miuyan1"] = "未时引火，必大败蜀军。",
  ["$miuyan2"] = "我等诈降，必欺姜维于不意。",
  ["$shilu1"] = "吾计不成，吾命何归？",
  ["$shilu2"] = "烟尘四起，无处寻路。",
  ["~wangguan"] = "我本魏将，将军救我！！",
}

local sunhong = General(extension, "sunhong", "wu", 3)
local xianbi = fk.CreateActiveSkill{
  name = "xianbi",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #Self.player_cards[Player.Hand] ~= #target.player_cards[Player.Equip] and target:getMark("zenrun") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #player.player_cards[Player.Hand] - #target.player_cards[Player.Equip]
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      local cards = room:askForDiscard(player, n, n, false, self.name, false, ".", "#xianbi-discard:::"..n)
      for _, id in ipairs(cards) do
        local get = {}
        local card = Fk:getCardById(id, true)
        table.insertTable(get, room:getCardsFromPileByRule(".|.|.|.|.|"..card:getTypeString().."|^"..id, 1, "discardPile"))
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
          })
        end
      end
    end
  end,
}
local zenrun = fk.CreateTriggerSkill{
  name = "zenrun",
  events = {fk.BeforeDrawCard},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = data.num
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return p:getMark(self.name) == 0 and #p:getCardIds{Player.Hand, Player.Equip} >= n end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zenrun-choose:::"..n, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = data.num
    data.num = 0
    local cards = room:askForCardsChosen(player, to, n, n, "he", self.name)
    room:obtainCard(player.id, cards, false, fk.ReasonPrey, player.id, self.name)
    local choice = room:askForChoice(to, {"zenrun_draw", "zenrun_forbid"}, self.name, "#zenrun-choice:"..player.id)
    if choice == "zenrun_draw" then
      to:drawCards(n, self.name)
    else
      room:addPlayerMark(to, self.name, 1)
    end
  end,
}
sunhong:addSkill(xianbi)
sunhong:addSkill(zenrun)
Fk:loadTranslationTable{
  ["sunhong"] = "孙弘",
  ["#sunhong"] = "谮诉构争",
  ["designer:sunhong"] = "zzcclll朱苦力",
  ["illustrator:sunhong"] = "匠人绘",

  ["xianbi"] = "险诐",
  [":xianbi"] = "出牌阶段限一次，你可以将手牌调整至与一名角色装备区里的牌数相同，然后每因此弃置一张牌，你随机获得弃牌堆中另一张类型相同的牌。",
  ["zenrun"] = "谮润",
  [":zenrun"] = "每阶段限一次，当你摸牌时，你可以改为获得一名其他角色等量张牌，然后其选择一项："..
  "1.摸等量的牌；2.本局游戏中你发动〖险诐〗和〖谮润〗不能指定其为目标。",
  ["#xianbi-discard"] = "险诐：弃置%arg张手牌，然后随机获得弃牌堆中相同类别的牌",
  ["#zenrun-choose"] = "谮润：你可以将摸牌改为获得一名其他角色%arg张牌，然后其选择摸等量牌或你本局不能对其发动技能",
  ["#zenrun-choice"] = "谮润：选择 %src 令你执行的一项",
  ["zenrun_draw"] = "你摸等量牌",
  ["zenrun_forbid"] = "其本局不能对你发动〖险诐〗和〖谮润〗",

  ["$xianbi1"] = "宦海如薄冰，求生逐富贵。",
  ["$xianbi2"] = "吾不欲为鱼肉，故为刀俎。",
  ["$zenrun1"] = "据图谋不轨，今奉诏索命。",
  ["$zenrun2"] = "休妄论芍陂之战，当诛之。",
  ["~sunhong"] = "诸葛公何至于此……",
}

local caoxi = General(extension, "caoxi", "wei", 3)
local function gangshuTimesCheck(player, card)
  local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
  for _, skill in ipairs(status_skills) do
    if skill:bypassTimesCheck(player, card.skill, Player.HistoryPhase, card) then return true end
  end
  return false
end
Fk:addQmlMark{
  name = "gangshu",
  qml_path = "",
  how_to_show = function(name, value, p)
    local card = Fk:cloneCard("slash")
    local x1 = ""
    if p:getAttackRange() > 499 then
      --FIXME:暂无无限攻击范围机制
      x1 = "∞"
    else
      x1 = tostring(p:getAttackRange())
    end
    local x2 = tostring(p:getMark("gangshu2_fix")+2)
    local x3 = ""
    if gangshuTimesCheck(p, card) then
      x3 = "∞"
    else
      x3 = tostring(card.skill:getMaxUseTime(p, Player.HistoryPhase, card, nil) or "∞")
    end
    return x1 .. " " .. x2 .. " " .. x3
  end,
}
local gangshu = fk.CreateTriggerSkill{
  name = "gangshu",
  events = {fk.CardUseFinished, fk.CardEffecting, fk.DrawNCards},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUseFinished then
      if target == player and data.card.type ~= Card.TypeBasic then
        if player:getMark("gangshu2_fix") < 3 then return true end
        if player:getAttackRange() < 5 then return true end
        local card = Fk:cloneCard("slash")
        return not gangshuTimesCheck(player, card) and (card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) or 5) < 5
      end
    elseif event == fk.CardEffecting then
      --你使用的以牌为目标的牌生效时，非常抽象的时机
      return data.toCard and data.from == player.id and
      (player:getMark("gangshu1_fix") > 0 or player:getMark("gangshu2_fix") > 0 or player:getMark("gangshu3_fix") > 0)
    elseif event == fk.DrawNCards then
      return target == player and player:getMark("gangshu2_fix") > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local choices = {"Cancel"}
      if player:getAttackRange() < 5 then
        table.insert(choices, "gangshu1")
      end
      if player:getMark("gangshu2_fix") < 3 then
        table.insert(choices, "gangshu2")
      end
      local card = Fk:cloneCard("slash")
      if not gangshuTimesCheck(player, card) and (card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) or 5) < 5 then
        table.insert(choices, "gangshu3")
      end
      if #choices == 1 then return false end
      local choice = player.room:askForChoice(player, choices, self.name, "#gangshu-choice", false, {"gangshu1", "gangshu2", "gangshu3", "Cancel"})
      if choice == "Cancel" then return false end
      self.cost_data = choice
      return true
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name)
      room:addPlayerMark(player, self.cost_data .. "_fix", 1)
    elseif event == fk.CardEffecting then
      room:notifySkillInvoked(player, self.name, "negative")
      room:setPlayerMark(player, "gangshu1_fix", 0)
      room:setPlayerMark(player, "gangshu2_fix", 0)
      room:setPlayerMark(player, "gangshu3_fix", 0)
    elseif event == fk.DrawNCards then
      room:notifySkillInvoked(player, self.name, "drawcard")
      data.n = data.n + player:getMark("gangshu2_fix")
      room:setPlayerMark(player, "gangshu2_fix", 0)
    end
  end,

  on_acquire = function (self, player)
    player.room:setPlayerMark(player, "@[gangshu]", 1)
  end,
  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "@[gangshu]", 0)
    room:setPlayerMark(player, "gangshu1_fix", 0)
    room:setPlayerMark(player, "gangshu2_fix", 0)
    room:setPlayerMark(player, "gangshu3_fix", 0)
  end,
}
local gangshu_attackrange = fk.CreateAttackRangeSkill{
  name = "#gangshu_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("gangshu1_fix")
  end,
}
local gangshu_targetmod = fk.CreateTargetModSkill{
  name = "#gangshu_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("gangshu3_fix") > 0 and scope == Player.HistoryPhase then
      return player:getMark("gangshu3_fix")
    end
  end,
}
local jianxuan = fk.CreateTriggerSkill{
  name = "jianxuan",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper),
      1, 1, "#jianxuan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local n = 0
    local card = Fk:cloneCard("slash")
    repeat
      to:drawCards(1, self.name)
      if to.dead or player.dead or not player:hasSkill(gangshu, true) then break end
      n = to:getHandcardNum()
    until (n ~= player:getAttackRange() and n ~= player:getMark("gangshu2_fix") + 2 and
    (gangshuTimesCheck(player, card) or
    n ~= card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)))
  end,
}
gangshu:addRelatedSkill(gangshu_attackrange)
gangshu:addRelatedSkill(gangshu_targetmod)
caoxi:addSkill(gangshu)
caoxi:addSkill(jianxuan)
Fk:loadTranslationTable{
  ["caoxi"] = "曹羲",
  ["#caoxi"] = "魁立倾厦",
  ["designer:caoxi"] = "玄蝶既白",
  ["illustrator:caoxi"] = "匠人绘",
  ["gangshu"] = "刚述",
  [":gangshu"] = "当你使用非基本牌后，你可以令你以下一项数值+1直到你抵消牌（至多增加至5）：攻击范围；下个摸牌阶段摸牌数；出牌阶段使用【杀】次数上限。",
  ["jianxuan"] = "谏旋",
  [":jianxuan"] = "当你受到伤害后，你可以令一名角色摸一张牌，若其手牌数与〖刚述〗中的任意项相同，其重复此流程。",
  ["gangshu1"] = "攻击范围",
  ["gangshu2"] = "下个摸牌阶段摸牌数",
  ["gangshu3"] = "出牌阶段使用【杀】次数",
  ["#gangshu-choice"] = "刚述：选择你要增加的一项",
  ["@[gangshu]"] = "刚述",
  ["#jianxuan-choose"] = "谏旋：你可以令一名角色摸一张牌",

  ["$gangshu1"] = "羲而立之年，当为立身之事。",
  ["$gangshu2"] = "总六军之要，秉选举之机。",
  ["$jianxuan1"] = "司马氏卧虎藏龙，大兄安能小觑。",
  ["$jianxuan2"] = "兄长以兽为猎，殊不知己亦为猎乎？",
  ["~caoxi"] = "曹氏亡矣，大魏亡矣！",
}

local lukai = General(extension, "ol__lukai", "wu", 3)
local xuanzhu = fk.CreateViewAsSkill{
  name = "xuanzhu",
  anim_type = "switch",
  switch_skill_name = "xuanzhu",
  derived_piles = "xuanzhu",
  pattern = ".",
  interaction = function()
    local all_names = {}
    if Self:getSwitchSkillState("xuanzhu", false) == fk.SwitchYang then
      all_names = U.getAllCardNames("b")
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
          table.insertIfNeed(all_names, card.name)
        end
      end
    end
    local names = U.getViewAsCardNames(Self, "xuanzhu", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:setMark("xuanzhu_subcards", cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local cards = use.card:getMark("xuanzhu_subcards")
    if Fk:getCardById(cards[1]).type == Card.TypeEquip then
      use.extra_data = use.extra_data or {}
      use.extra_data.xuanzhu_equip = true
    end
    player:addToPile(self.name, cards, true, self.name)
  end,
  after_use = function(self, player, use)
    if player.dead then return end
    if use.extra_data and use.extra_data.xuanzhu_equip then
      local cards = player:getPile(self.name)
      if #cards > 0 then
        player.room:recastCard(cards, player)
      end
    else
      player.room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  enabled_at_response = function(self, player, response)
    if not response and player:usedSkillTimes(self.name) == 0 and Fk.currentResponsePattern then
      local all_names = {}
      if player:getSwitchSkillState("xuanzhu", false) == fk.SwitchYang then
        all_names = U.getAllCardNames("b")
      else
        for _, id in ipairs(Fk:getAllCardIds()) do
          local card = Fk:getCardById(id)
          if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
            table.insertIfNeed(all_names, card.name)
          end
        end
      end
      return #U.getViewAsCardNames(player, "xuanzhu", all_names) > 0
    end
  end,
}
local jiane = fk.CreateTriggerSkill{
  name = "jiane",
  events = {fk.CardEffecting, fk.CardEffectCancelledOut},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardEffecting then
      if data.from == player.id then
        local tos = TargetGroup:getRealTargets(data.tos)
        return table.find(player.room.alive_players, function (p)
          return p ~= player and p:getMark("@@jiane_debuff-turn") == 0 and table.contains(tos, p.id)
        end)
      end
    else
      if player:getMark("@@jiane_buff-turn") > 0 then return false end
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local is_from = false
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.responseToEvent == data then
          if use.from == player.id then
            is_from = true
          end
          return true
        end
      end, use_event.id)
      return is_from
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffecting then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      local tos = TargetGroup:getRealTargets(data.tos)
      local tos2 = {}
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p:getMark("@@jiane_debuff-turn") == 0 and table.contains(tos, p.id) then
          room:setPlayerMark(p, "@@jiane_debuff-turn", 1)
          table.insert(tos2, p.id)
        end
      end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        table.insertTableIfNeed(e.data[1].unoffsetableList, tos2)
        return false
      end, turn_event.id)
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(player, "@@jiane_buff-turn", 1)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    data.unoffsetableList = data.unoffsetableList or {}
    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("@@jiane_debuff-turn") > 0 then
        table.insert(data.unoffsetableList, p.id)
      end
    end
  end,
}
local jiane_prohibit = fk.CreateProhibitSkill{
  name = "#jiane_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("@@jiane_buff-turn") > 0
  end,
}
jiane:addRelatedSkill(jiane_prohibit)
lukai:addSkill(xuanzhu)
lukai:addSkill(jiane)
Fk:loadTranslationTable{
  ["ol__lukai"] = "陆凯",
  ["#ol__lukai"] = "节概梗梗",
  ["illustrator:ol__lukai"] = "空山MBYK",
  ["designer:ol__lukai"] = "扬林",

  ["xuanzhu"] = "玄注",
  [":xuanzhu"] = "转换技，每回合限一次，阳：你可以将一张牌移出游戏，视为使用任意基本牌；"..
  "阴：你可以将一张牌移出游戏，视为使用仅指定唯一角色为目标的普通锦囊牌。"..
  "若移出游戏的牌：不为装备牌，你弃置一张牌；为装备牌，你重铸以此法移出游戏的牌。",
  ["jiane"] = "謇谔",
  [":jiane"] = "锁定技，当你使用的牌对一名角色生效后，你令所有是此牌的目标的其他角色于当前回合内不能抵消牌；"..
  "当一名角色使用的牌被你抵消后，你令你于当前回合内不是牌的合法目标。",

  ["@@jiane_buff-turn"] = "謇谔",
  ["@@jiane_debuff-turn"] = "謇谔",

  ["$xuanzhu1"] = "提笔注太玄，佐国定江山。",
  ["$xuanzhu2"] = "总太玄之要，纵弼国之实。",
  ["$jiane1"] = "臣者，未死于战，则死于谏。",
  ["$jiane2"] = "君有弊，坐视之辈甚于外贼。",
  ["~ol__lukai"] = "注经之人，终寄身于土……",
}

local guotu = General(extension, "guotu", "qun", 3)
local qushi = fk.CreateActiveSkill{
  name = "qushi",
  anim_type = "control",
  prompt = "#qushi-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:drawCards(player, 1, self.name)
    if player:isKongcheng() then return false end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets == 0 then return false end
    local target, card = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|hand", "#qushi-choose", self.name, false)
    if #target > 0 and card then
      target = room:getPlayerById(target[1])
      local targetRecorded = target:getTableMark("qushi_source")
      if not table.contains(targetRecorded, player.id) then
        table.insert(targetRecorded, player.id)
        room:setPlayerMark(target, "qushi_source", targetRecorded)
      end
      target:addToPile("$qushi_pile", card, false, self.name, player.id, {})
    end
  end
}
local qushi_delay = fk.CreateTriggerSkill{
  name = "#qushi_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
    #player:getPile("$qushi_pile") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getTableMark("qushi_source")
    room:setPlayerMark(player, "qushi_source", 0)
    local cards = player:getPile("$qushi_pile")
    local card_types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(card_types, Fk:getCardById(id).type)
    end
    room:moveCards{
      from = player.id,
      ids = cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "qushi",
      proposer = player.id,
    }
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local players = {}
    local cant_trigger = true
    --FIXME:可能需要根据放置此牌的角色单独判定类别，暂不作考虑
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.from == player.id then
        if table.contains(card_types, use.card.type) then
          cant_trigger = false
        end
        table.insertTableIfNeed(players, TargetGroup:getRealTargets(use.tos))
      end
      return false
    end, turn_event.id)
    local n = math.min(#players, 5)
    if cant_trigger or n == 0 then return false end
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        p:drawCards(n, "qushi")
      end
    end
  end,
}
local qushi_visibility = fk.CreateVisibilitySkill{
  name = "#qushi_visibility",
  card_visible = function(self, player, card)
    if player:getPileNameOfId(card.id) == "$qushi_pile" then
      return false
    end
  end
}
local weijie = fk.CreateViewAsSkill{
  name = "weijie",
  anim_type = "defensive",
  prompt = "#weijie-viewas",
  pattern = ".|.|.|.|.|basic",
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "weijie", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and not p:isNude() and player:distanceTo(p) == 1
    end)
    if #targets == 0 then return "" end
    local name = Fk:cloneCard(self.interaction.data).trueName
    targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
    "#weijie-choose:::" .. name, self.name, false)
    local target = room:getPlayerById(targets[1])
    local card = Fk:getCardById(room:askForCardChosen(player, target, "he", self.name))
    room:throwCard({card.id}, self.name, target, player)
    if card.trueName ~= name then return "" end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    if player:usedSkillTimes(self.name) > 0 then return false end
    local a, b = false, false
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p ~= player then
        if p.phase ~= Player.NotActive then
          a = true
        end
        if not p:isKongcheng() and player:distanceTo(p) == 1 then
          b = true
        end
      end
    end
    return a and b
  end,
}
qushi:addRelatedSkill(qushi_delay)
qushi:addRelatedSkill(qushi_visibility)
guotu:addSkill(qushi)
guotu:addSkill(weijie)
Fk:loadTranslationTable{
  ["guotu"] = "郭图",
  ["#guotu"] = "凶臣",
  ["illustrator:guotu"] = "厦门塔普",
  ["cv:guotu"] = "杨超然",

  ["qushi"] = "趋势",
  [":qushi"] = "出牌阶段限一次，你可以摸一张牌，然后将一张手牌扣置于一名其他角色的武将牌旁（称为“趋”）。"..
  "武将牌旁有“趋”的角色的结束阶段，其移去所有“趋”，若其于此回合内使用过与移去的“趋”类别相同的牌，"..
  "你摸X张牌（X为于本回合内成为过其使用的牌的目标的角色数且至多为5）。",
  ["weijie"] = "诿解",
  [":weijie"] = "每回合限一次，当你于其他角色的回合内需要使用/打出基本牌时，你可以弃置距离为1的一名角色的一张牌，"..
  "若此牌与你需要使用/打出的牌牌名相同，你视为使用/打出此牌名的牌。",

  ["#qushi-active"] = "发动 趋势，你可以摸一张牌，然后放置一张手牌作为“趋”",
  ["#qushi-choose"] = "趋势：选择作为“趋”的一张手牌以及一名其他角色",
  ["$qushi_pile"] = "趋",
  ["#qushi_delay"] = "趋势",
  ["#weijie-viewas"] = "发动 诿解，视为使用或打出一张基本牌",
  ["#weijie-choose"] = "诿解：弃置与你距离为1的一名角色的一张牌，若此牌为【%arg】，视为你使用或打出之",

  ["$qushi1"] = "将军天人之姿，可令四海归心。",
  ["$qushi2"] = "小小锦上之花，难表一腔敬意。",
  ["$weijie1"] = "败战之罪在你，休要多言！",
  ["$weijie2"] = "纵汝舌灿莲花，亦难逃死罪。",
  ["~guotu"] = "工于心计而不成事，匹夫怀其罪……",
}

local peixiu = General(extension, "ol__peixiu", "wei", 4)
Fk:loadTranslationTable{
  ["ol__peixiu"] = "裴秀",
  ["#ol__peixiu"] = "勋德茂著",
  ["~ol__peixiu"] = "",
}

local maozhuo = fk.CreateTriggerSkill{
  name = "maozhuo",
  events = {fk.DamageCaused},
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
    player == target and
    player:hasSkill(self) and
    player.phase == Player.Play and
    player:usedSkillTimes(self.name) == 0 and
    player:getMark("maozhuo_record-turn") == 0 and
    #table.filter(player.player_skills, function(skill) return skill:isPlayerSkill(player) end) >
      #table.filter(data.to.player_skills, function(skill) return skill:isPlayerSkill(data.to) end) and
    #player.room.logic:getActualDamageEvents(
      1,
      function(e)
        if e.data[1].from == player then
          player.room:setPlayerMark(player, "maozhuo_record-turn", 1)
          return true
        end
        return false
      end,
      Player.HistoryPhase
    ) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local maozhuoTargetMod = fk.CreateTargetModSkill{
  name = "#maozhuo_targetmod",
  frequency = Skill.Compulsory,
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(maozhuo) and skill.trueName == "slash_skill" then
      return
        #table.filter(
          player.player_skills,
          function(skill) return skill:isPlayerSkill(player) and skill.visible end
        )
    end
  end,
}
local maozhuoMaxCards = fk.CreateMaxCardsSkill{
  name = "#maozhuo_maxcards",
  frequency = Skill.Compulsory,
  correct_func = function(self, player)
    if player:hasSkill(maozhuo) then
      return
        #table.filter(
          player.player_skills,
          function(skill) return skill:isPlayerSkill(player) and skill.visible end
        )
    end
  end,
}
Fk:loadTranslationTable{
  ["maozhuo"] = "茂著",
  [":maozhuo"] = "锁定技，你使用【杀】的次数上限和手牌上限+X（X为你的技能数）；当你于出牌阶段内首次造成伤害时，" ..
  "若受伤角色的技能数少于你，则此伤害+1。",
}

maozhuo:addRelatedSkill(maozhuoTargetMod)
maozhuo:addRelatedSkill(maozhuoMaxCards)
peixiu:addSkill(maozhuo)

local jinlan = fk.CreateActiveSkill{
  name = "jinlan",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = function()
    local mostSkillNum = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local skillNum = #table.filter(
        p.player_skills,
        function(skill) return skill:isPlayerSkill(p) and skill.visible end
      )
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    return "#jinlan:::" .. mostSkillNum
  end,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 then
      return false
    end

    local mostSkillNum = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local skillNum = #table.filter(
        p.player_skills,
        function(skill) return skill:isPlayerSkill(p) and skill.visible end
      )
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    return player:getHandcardNum() < mostSkillNum
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)

    local mostSkillNum = 0
    for _, p in ipairs(room.alive_players) do
      local skillNum = #table.filter(p.player_skills, function(skill) return skill:isPlayerSkill(p) end)
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    player:drawCards(mostSkillNum - player:getHandcardNum(), self.name)
  end,
}
Fk:loadTranslationTable{
  ["jinlan"] = "尽览",
  [":jinlan"] = "出牌阶段限一次，你可以将手牌摸至X张（X为存活角色中技能最多角色的技能数）。",
  ["#jinlan"] = "尽览：你可将手牌摸至%arg张",
}

peixiu:addSkill(jinlan)
