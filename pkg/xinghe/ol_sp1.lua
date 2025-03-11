
local cuiyan = General(extension, "cuiyan", "wei", 3)
local yawang = fk.CreateTriggerSkill{
  name = "yawang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p.hp == player.hp then
        n = n + 1
      end
    end
    player:drawCards(n, self.name)
    player.room:addPlayerMark(player, "yawang-turn", n)
    return true
  end,

  refresh_events ={fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@yawang-turn", 1)
  end,
}
local yawang_prohibit = fk.CreateProhibitSkill{
  name = "#yawang_prohibit",
  prohibit_use = function(self, player, card)
    return player:usedSkillTimes("yawang", Player.HistoryTurn) > 0 and player.phase == Player.Play and
      player:getMark("@yawang-turn") >= player:getMark("yawang-turn")
  end,
}
local xunzhi = fk.CreateTriggerSkill{
  name = "xunzhi",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
        if (player:getNextAlive() == p or p:getNextAlive() == player) and player.hp == p.hp then return end
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
  end,
}
yawang:addRelatedSkill(yawang_prohibit)
cuiyan:addSkill(yawang)
cuiyan:addSkill(xunzhi)
Fk:loadTranslationTable{
  ["cuiyan"] = "崔琰",
  ["#cuiyan"] = "伯夷之风",
  ["designer:cuiyan"] = "凌天翼",
  ["yawang"] = "雅望",
  [":yawang"] = "锁定技，摸牌阶段开始时，你放弃摸牌，改为摸X张牌，然后你于出牌阶段内至多使用X张牌（X为与你体力值相等的角色数）。",
  ["xunzhi"] = "殉志",
  [":xunzhi"] = "准备阶段开始时，若你的上家和下家与你的体力值均不相等，你可以失去1点体力。若如此做，你的手牌上限+2。",
  ["@yawang-turn"] = "雅望",

  ["$yawang1"] = "君子，当以正气立于乱世。",
  ["$yawang2"] = "琰，定不负诸位雅望！",
  ["$xunzhi1"] = "春秋大义，自在我心！",
  ["$xunzhi2"] = "成大义者，这点牺牲算不得什么！",
  ["~cuiyan"] = "尔等，皆是欺世盗名之辈！",
}

local guansuo = General(extension, "guansuo", "shu", 4)
local zhengnan = fk.CreateTriggerSkill{
  name = "zhengnan",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, self.name)
    local choices = {"wusheng", "dangxian", "zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askForChoice(player, choices, self.name, "#zhengnan-choice", true)
      player.room:handleAddLoseSkills(player, choice, nil)
    end
  end,
}
local xiefang = fk.CreateDistanceSkill{
  name = "xiefang",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p:isFemale() then
          n = n + 1
        end
      end
      return -n
    end
    return 0
  end,
}
guansuo:addSkill(zhengnan)
guansuo:addSkill(xiefang)
guansuo:addRelatedSkill("wusheng")
guansuo:addRelatedSkill("dangxian")
guansuo:addRelatedSkill("zhiman")
Fk:loadTranslationTable{
  ["guansuo"] = "关索",
  ["#guansuo"] = "倜傥孑侠",
  ["designer:guansuo"] = "千幻",
  ["illustrator:guansuo"] = "depp",
  ["zhengnan"] = "征南",
  [":zhengnan"] = "当其他角色死亡后，你可以摸三张牌，若如此做，你获得下列技能中的任意一个：〖武圣〗，〖当先〗和〖制蛮〗。",
  ["xiefang"] = "撷芳",
  [":xiefang"] = "锁定技，你计算与其他角色的距离-X（X为女性角色数）。",
  ["#zhengnan-choice"] = "征南：选择获得的技能",

  ["$zhengnan1"] = "索全凭丞相差遣，万死不辞！",
  ["$zhengnan2"] = "末将愿承父志，随丞相出征！",
  ["$wusheng_guansuo"] = "逆贼，可识得关氏之勇？",
  ["$dangxian_guansuo"] = "各位将军，且让小辈先行出战！",
  ["$zhiman_guansuo"] = "蛮夷可抚，不可剿！",
  ["~guansuo"] = "只恨天下未平，空留遗志。",
}

local mazhong = General(extension, "mazhong", "shu", 4)
local fuman = fk.CreateActiveSkill{
  name = "fuman",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("fuman-turn") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    room:addPlayerMark(target, "fuman-turn", 1)
    room:setPlayerMark(target, self.name, effect.cards[1])
  end,
}
local fuman_record = fk.CreateTriggerSkill{
  name = "#fuman_record",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self, true) and target:getMark("fuman") ~= 0 then
      if data.card:isVirtual() then
        if #data.card.subcards > 0 then
          for _, id in ipairs(data.card.subcards) do
            if target:getMark("fuman") == id then
              return true
            end
          end
        end
      else
        return data.card:getEffectiveId() == target:getMark("fuman")
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "fuman", 0)
    player:drawCards(1, "fuman")
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("fuman") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fuman", 0)
  end,
}
fuman:addRelatedSkill(fuman_record)
mazhong:addSkill(fuman)
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["#mazhong"] = "笑合南中",
  ["designer:mazhong"] = "Virgopaladin",
  ["illustrator:mazhong"] = "Thinking",
  ["fuman"] = "抚蛮",
  [":fuman"] = "出牌阶段，你可以将一张【杀】交给一名本回合未获得过“抚蛮”牌的其他角色，然后其于下个回合结束之前使用“抚蛮”牌时，你摸一张牌。",
  ["#fuman_record"] = "抚蛮",

  ["$fuman1"] = "恩威并施，蛮夷可为我所用！",
  ["$fuman2"] = "发兵器啦！",
  ["~mazhong"] = "丞相不在，你们竟然……",
}

local godsunquan = General(extension, "godsunquan", "god", 4)
local yuheng_skills = {
  -- OL original skills
  "ex__zhiheng", "dimeng", "anxu", "ol__bingyi", "shenxing",
  "xingxue", "anguo", "jiexun", "xiashu", "ol__hongyuan",
  "lanjiang", "sp__youdi", "guanwei", "ol__diaodu", "bizheng"
}
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
      local skills = table.filter(yuheng_skills, function (skill_name)
        return not player:hasSkill(skill_name, true)
      end)
      if #skills == 0 then return false end
      skills = table.random(skills, #cards)
      local mark = player:getTableMark("yuheng")
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
local ol__diaodu = fk.CreateTriggerSkill{
  name = "ol__diaodu",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUsing then
      if target.kingdom == player.kingdom and data.card.type == Card.TypeEquip then
        local _event = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          return use.card.type == Card.TypeEquip and player.room:getPlayerById(use.from).kingdom == player.kingdom
        end, Player.HistoryTurn)
        return #_event > 0 and _event[1].data[1] == data
      end
    else
      return target == player and player.phase == Player.Play and
        table.find(player.room.alive_players, function(p)
          return p.kingdom == player.kingdom and #p:getCardIds("e") > 0
        end) end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      return room:askForSkillInvoke(target, self.name, nil, "#diaodu-invoke")
    else
      local targets = table.map(table.filter(room.alive_players, function(p)
        return p.kingdom == player.kingdom and #p:getCardIds("e") > 0
      end), Util.IdMapper)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#diaodu-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUsing then
      target:drawCards(1, self.name)
    else
      local room = player.room
      local to = room:getPlayerById(self.cost_data)
      local cid = room:askForCardChosen(player, to, "e", self.name)
      room:obtainCard(player, cid, true, fk.ReasonPrey)
      if not table.contains(player:getCardIds(Player.Hand), cid) then return end
      local card = Fk:getCardById(cid)
      local targets = table.filter(room.alive_players, function(p) return p ~= player and p ~= to end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#diaodu-give:::" .. card:toLogString(), self.name, true)
      if #tos > 0 then
        room:moveCardTo(card, Card.PlayerHand, room:getPlayerById(tos[1]), fk.ReasonGive, self.name, nil, true, player.id)
      end
    end
  end,
}
Fk:addSkill(ol__diaodu)
Fk:loadTranslationTable{
  ["ol__diaodu"] = "调度",
  [":ol__diaodu"] = "当每回合首次有与你势力相同的角色使用装备牌时，其可以摸一张牌。出牌阶段开始时，你可以获得与你势力相同的一名角色装备区里的一张牌，然后你可将此牌交给另一名角色。",
}
local dili = fk.CreateTriggerSkill{
  name = "dili",
  anim_type = "special",
  events = {fk.EventAcquireSkill, fk.MaxHpChanged},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and
    player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
    (event == fk.EventAcquireSkill or data.num < 0) and
    player.room:getBanner("RoundCount")
  end,
  can_wake = function(self, event, target, player, data)
    local n = 0
    for _, s in ipairs(player.player_skills) do
      if s:isPlayerSkill(player) then
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
      if s:isPlayerSkill(player) and s ~= self then
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
  mute = true,
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.SkillEffect, fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("") == 0 and
    data.frequency ~= Skill.Compulsory and data.frequency ~= Skill.Wake and
    not (data.cardSkill or data.global) and data:isPlayerSkill(target)
    --FIXME："&"后缀技需要能区分规则技和其他角色发动的主动技
    --FIXME：重量级发动技能后的技能，转化类的技能根本没有办法判定
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shengzhi-turn", 1)
  end,

  --不会和〖权道〗自选，暂定refresh吧
  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@shengzhi-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name)
    player.room:setPlayerMark(player, "@@shengzhi-turn", 0)
    if not data.extraUse then
      target:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
  end,
}
local shengzhi_targetmod = fk.CreateTargetModSkill{
  name = "#shengzhi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("@@shengzhi-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:getMark("@@shengzhi-turn") > 0
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
    if not player:isKongcheng() then
      local slash = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == "slash" end)
      local trick = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):isCommonTrick() end)
      if #slash ~= #trick then
        local n = #slash - #trick
        if n > 0 then
          room:askForDiscard(player, n, n, false, self.name, false, "slash")
        else
          room:askForDiscard(player, -n, -n, false, self.name, false, tostring(Exppattern{ id = trick }))
        end
      end
    end
    if not player.dead then
      player:drawCards(1, self.name)
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
  ["#godsunquan"] = "坐断东南",
  ["designer:godsunquan"] = "玄蝶既白",
  ["illustrator:godsunquan"] = "鬼画府",
  ["yuheng"] = "驭衡",
  [":yuheng"] = "锁定技，回合开始时，你弃置任意张花色不同的牌，随机获得等量吴势力武将的技能。回合结束时，你失去以此法获得的技能，摸等量张牌。",
  ["dili"] = "帝力",
  [":dili"] = "觉醒技，当你的技能数超过体力上限后，你减少1点体力上限，失去任意个其他技能并获得〖圣质〗〖权道〗〖持纲〗中的前等量个。"..
  "<br/><font color='red'><b>注</b>：请不要反馈此技能相关的任何问题。</font>",
  ["shengzhi"] = "圣质",
  [":shengzhi"] = "锁定技，当你发动非锁定技后，你本回合使用的下一张牌无距离和次数限制。"..
  "<br/><font color='red'><b>注</b>：请不要反馈此技能相关的任何问题。</font>",
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
