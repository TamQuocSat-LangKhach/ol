
local U = require "packages/utility/utility"


local chengyu = General(extension, "chengyu", "wei", 3)
local shefu = fk.CreateTriggerSkill{
  name = "shefu",
  anim_type = "control",
  derived_piles = "$shefu",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isKongcheng()
      else
        return target ~= player and player.phase == Player.NotActive and
          (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#shefu-cost")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      self.cost_data = 0
      local tag = player.tag[self.name]
      if type(tag) ~= "table" then return end
      for i = 1, #tag, 1 do
        if data.card.trueName == tag[i][2] then
          self.cost_data = tag[i][1]
          break
        end
      end
      if self.cost_data > 0 then
        return room:askForSkillInvoke(player, self.name)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:addToPile("$shefu", self.cost_data, false, self.name)
      local names ={}
      local tag = player.tag[self.name]
      if type(tag) ~= "table" then tag ={} end
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeBasic or card.type == Card.TypeTrick then
          table.insertIfNeed(names, card.trueName)
        end
      end
      for i = #names, 1, -1 do
        for j = 1, #tag, 1 do
          if names[i] == tag[j][2] then
            table.remove(names, i)
          end
        end
      end
      if #names > 0 then
        local name = room:askForChoice(player, names, self.name)
        table.insert(tag,{self.cost_data[1], name})
        player.tag[self.name] = tag
      end
    else
      local tag = player.tag[self.name]
      for i = 1, #tag, 1 do
        if data.card.trueName == tag[i][2] then
          table.remove(tag, i)
          break
        end
      end
      player.tag[self.name] = tag
      room:moveCards({
        from = player.id,
        ids ={self.cost_data},
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      data.tos ={}
    end
  end,
}
local benyu = fk.CreateTriggerSkill{
  name = "benyu",
  anim_type = "masochism",
  events ={fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and
      (player:getHandcardNum() > data.from:getHandcardNum() or player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > data.from:getHandcardNum() then
      local num = data.from:getHandcardNum() + 1
      local cards = room:askForDiscard(player, num, 999, false, self.name, true, ".",
        "#benyu-discard::"..data.from.id..":"..num, true)
      if #cards >= num then
        self.cost_data = {tos = {data.from.id}, cards = cards}
        return true
      end
    elseif room:askForSkillInvoke(player, self.name, nil, "#benyu-draw:::"..math.min(data.from:getHandcardNum(), 5)) then
      self.cost_data = {tos = {data.from.id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data.cards then
      local room = player.room
      room:throwCard(self.cost_data.cards, self.name, player, player)
      if not data.from.dead then
        room:damage{
          from = player,
          to = data.from,
          damage = 1,
          skillName = self.name,
        }
      end
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum(), self.name)
    end
  end,
}
chengyu:addSkill(shefu)
chengyu:addSkill(benyu)
Fk:loadTranslationTable{
  ["chengyu"] = "程昱",
  ["#chengyu"] = "泰山捧日",
  ["illustrator:chengyu"] = "GH",
  ["shefu"] = "设伏",
  [":shefu"] = "结束阶段开始时，你可将一张手牌扣置于武将牌上，称为“伏兵”。若如此做，你为“伏兵”记录一个基本牌或锦囊牌的名称"..
  "（须与其他“伏兵”记录的名称均不同）。当其他角色于你的回合外使用手牌时，你可将记录的牌名与此牌相同的一张“伏兵”置入弃牌堆，然后此牌无效。",
  ["benyu"] = "贲育",
  [":benyu"] = "当你受到伤害后，若你的手牌数不大于伤害来源手牌数，你可以将手牌摸至与伤害来源手牌数相同（最多摸至5张）；"..
  "否则你可以弃置大于伤害来源手牌数的手牌，然后对其造成1点伤害。",
  ["#shefu-cost"] = "设伏：你可以将一张手牌扣置为“伏兵”",
  ["$shefu"] = "伏兵",
  ["#benyu-discard"] = "贲育：你可以弃置至少%arg张手牌，对 %dest 造成1点伤害",
  ["#benyu-draw"] = "贲育：你可以将手牌摸至 %arg 张",

  ["$shefu1"] = "圈套已设，埋伏已完，只等敌军进来。",
  ["$shefu2"] = "如此天网，量你插翅也难逃。",
  ["$benyu1"] = "曹公智略乃上天所授！",
  ["$benyu2"] = "天下大乱，群雄并起，必有命事。",
  ["~chengyu"] = "此诚报效国家之时，吾却休矣。",
}

local sunhao = General(extension, "sunhao", "wu", 5)
local canshi = fk.CreateTriggerSkill{
  name = "canshi",
  anim_type = "drawcard",
  events ={fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not table.every(player.room:getAlivePlayers(false), function (p)
      return not p:isWounded() and not (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player) then
        n = n + 1
      end
    end
    data.n = data.n + n
  end,
}
local canshi_delay = fk.CreateTriggerSkill{
  name = "#canshi_delay",
  anim_type = "negative",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
      player:usedSkillTimes(canshi.name) > 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name, false)
  end,
}
local chouhai = fk.CreateTriggerSkill{
  name = "chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local guiming = fk.CreateTriggerSkill{
  name = "guiming$",
  frequency = Skill.Compulsory,
}
canshi:addRelatedSkill(canshi_delay)
sunhao:addSkill(canshi)
sunhao:addSkill(chouhai)
sunhao:addSkill(guiming)
Fk:loadTranslationTable{
  ["sunhao"] = "孙皓",
  ["#sunhao"] = "时日曷丧",
  ["illustrator:sunhao"] = "LiuHeng",
  ["canshi"] = "残蚀",
  [":canshi"] = "摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用基本牌或锦囊牌时，你弃置一张牌。",
  ["chouhai"] = "仇海",
  [":chouhai"] = "锁定技，当你受到伤害时，若你没有手牌，你令此伤害+1。",
  ["guiming"] = "归命",
  [":guiming"] = "主公技，锁定技，其他吴势力角色于你的回合内视为已受伤的角色。",

  ["#canshi_delay"] = "残蚀",

  ["$canshi1"] = "众人与蝼蚁何异？哈哈哈……",
  ["$canshi2"] = "难道一切不在朕手中？",
  ["$chouhai1"] = "哼，树敌三千又如何？",
  ["$chouhai2"] = "不发狂，就灭亡！",
  ["$guiming1"] = "这是要我命归黄泉吗？",
  ["$guiming2"] = "这就是末世皇帝的不归路！",
  ["~sunhao"] = "命啊！命！",
}

local shixie = General(extension, "shixie", "qun", 3)
local biluan = fk.CreateTriggerSkill{
  name = "biluan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isNude() then
      return table.find(player.room:getOtherPlayers(player, false), function(p) return p:distanceTo(player) == 1 end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#biluan-invoke:::"..#kingdoms, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead then return end
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local num = tonumber(player:getMark("@shixie_distance")) + #kingdoms
    room:setPlayerMark(player,"@shixie_distance",num > 0 and "+"..num or num)
  end,
}
local biluan_distance = fk.CreateDistanceSkill{
  name = "#biluan_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@shixie_distance"))
    if num > 0 then
      return num
    end
  end,
}
biluan:addRelatedSkill(biluan_distance)
shixie:addSkill(biluan)
local lixia = fk.CreateTriggerSkill{
  name = "lixia",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"draw1", "lixia_draw:"..target.id}
    if target:isWounded() then table.insert(all_choices, "lixia_recover:"..target.id) end
    local choices = room:askForChoices(player, all_choices, 1, 2, self.name, nil, false)
    for _, choice in ipairs(choices) do
      if choice == "draw1" then
        player:drawCards(1, self.name)
      elseif choice:startsWith("lixia_draw") then
        target:drawCards(2, self.name)
      else
        room:recover { num = 1, skillName = self.name, who = target, recoverBy = player}
      end
    end
    if player.dead then return end
    local num = tonumber(player:getMark("@shixie_distance"))-1
    room:setPlayerMark(player,"@shixie_distance",num > 0 and "+"..num or num)
  end,
}
local lixia_distance = fk.CreateDistanceSkill{
  name = "#lixia_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@shixie_distance"))
    if num < 0 then
      return num
    end
  end,
}
lixia:addRelatedSkill(lixia_distance)
shixie:addSkill(lixia)
Fk:loadTranslationTable{
  ["shixie"] = "士燮",
  ["#shixie"] = "南交学祖",
  ["designer:shixie"] = "Rivers",
  ["illustrator:shixie"] = "銘zmy",

  ["biluan"] = "避乱",
  [":biluan"] = "结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为存活势力数）。",
  ["lixia"] = "礼下",
  [":lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一至两项：1.摸一张牌；2.令其摸两张牌；3.令其回复1点体力。选择完成后，其他角色计算与你的距离-1。",
  ["#biluan-invoke"] = "避乱：你可弃一张牌，令其他角色计算与你距离+%arg",
  ["@shixie_distance"] = "距离",
  ["lixia_draw"] = "令%src摸两张牌",
  ["lixia_recover"] = "令%src回复1点体力",

  ["$biluan1"] = "身处乱世，自保足矣。",
  ["$biluan2"] = "避一时之乱，求长世安稳。",
  ["$lixia1"] = "将军真乃国之栋梁。",
  ["$lixia2"] = "英雄可安身立命于交州之地。",
  ["~shixie"] = "我这一生，足矣……",
}

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

local litong = General(extension, "litong", "wei", 4)
local tuifeng = fk.CreateTriggerSkill{
  name = "tuifeng",
  anim_type = "masochism",
  derived_piles = "$tuifeng",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if target:isNude() or self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, true, self.name, true, ".", "#tuifeng-cost")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("$tuifeng", self.cost_data, false, self.name)
  end,
}
local tuifeng_trigger = fk.CreateTriggerSkill{
  name = "#tuifeng_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player:getPile("$tuifeng") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("tuifeng")
    room:notifySkillInvoked(player, "tuifeng")
    local n = #player:getPile("$tuifeng")
    room:moveCards({
      from = player.id,
      ids = player:getPile("$tuifeng"),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "tuifeng",
    })
    if player.dead then return end
    room:addPlayerMark(player, "@tuifeng-turn", n)
    player:drawCards(2 * n, "tuifeng")
  end,
}
local tuifeng_targetmod = fk.CreateTargetModSkill{
  name = "#tuifeng_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@tuifeng-turn") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@tuifeng-turn")
    end
  end,
}
tuifeng:addRelatedSkill(tuifeng_targetmod)
tuifeng:addRelatedSkill(tuifeng_trigger)
litong:addSkill(tuifeng)
Fk:loadTranslationTable{
  ["litong"] = "李通",
  ["#litong"] = "万亿吾独往",
  ["illustrator:litong"] = "瞎子Ghe",
  ["tuifeng"] = "推锋",
  [":tuifeng"] = "当你受到1点伤害后，你可以将一张牌置于武将牌上，称为“锋”。准备阶段开始时，若你的武将牌上有“锋”，你将所有“锋”置入弃牌堆，"..
  "摸2X张牌，然后你于此回合的出牌阶段内使用【杀】的次数上限+X（X为你此次置入弃牌堆的“锋”数）。",
  ["#tuifeng_trigger"] = "推锋",
  ["#tuifeng-cost"] = "推锋：你可以将一张牌置于武将牌上，称为“锋”",
  ["@tuifeng-turn"] = "推锋",
  ["$tuifeng"] = "推锋",

  ["$tuifeng1"] = "摧锋陷阵，以杀贼首！",
  ["$tuifeng2"] = "敌锋之锐，我已尽知。",
  ["~litong"] = "战死沙场，快哉。",
}

local buzhi = General(extension, "buzhi", "wu", 3)
local hongde = fk.CreateTriggerSkill{
  name = "hongde",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and ((move.from == player.id and move.to ~= player.id) or
          (move.to == player.id and move.toArea == Card.PlayerHand)) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
      "#hongde-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):drawCards(1, self.name)
  end,
}
local dingpan = fk.CreateActiveSkill{
  name = "dingpan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#dingpan",
  times = function(self)
    return Self.phase == Player.Play and
    #table.filter(Fk:currentRoom().alive_players, function (p)
      return p.role == "rebel"
    end) - Self:usedSkillTimes(self.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) <
      #table.filter(Fk:currentRoom().alive_players, function (p)
        return p.role == "rebel"
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select):getCardIds("e") > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(1, self.name)
    local choice = room:askForChoice(target, {"dingpan_discard:"..player.id, "dingpan_damage:"..player.id}, self.name)
    if choice[10] == "i" then
      local id = room:askForCardChosen(player, target, "e", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      room:moveCardTo(target:getCardIds("e"), Card.PlayerHand, target, fk.ReasonJustMove, self.name, nil, true, target.id)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
buzhi:addSkill(hongde)
buzhi:addSkill(dingpan)
Fk:loadTranslationTable{
  ["buzhi"] = "步骘",
  ["#buzhi"] = "积跬靖边",
  ["illustrator:buzhi"] = "sinno",
  ["hongde"] = "弘德",
  [":hongde"] = "当你一次获得或失去至少两张牌后，你可以令一名其他角色摸一张牌。",
  ["dingpan"] = "定叛",
  [":dingpan"] = "出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；"..
  "2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。",
  ["#hongde-choose"] = "弘德：你可以令一名其他角色摸一张牌",
  ["#dingpan"] = "定叛：令一名装备区里有牌的角色摸一张牌，然后其选择弃置装备或收回装备并受到你造成的伤害",
  ["dingpan_discard"] = "%src弃置你装备区里的一张牌",
  ["dingpan_damage"] = "收回所有装备，%src对你造成1点伤害",

  ["$hongde1"] = "江南重义，东吴尚德。",
  ["$hongde2"] = "德无单行，福必双至。",
  ["$dingpan1"] = "从孙者生，从刘者死！",
  ["$dingpan2"] = "多行不义必自毙！",
  ["~buzhi"] = "交州已定，主公尽可放心。",
}

local zhaoxiang = General(extension, "zhaoxiang", "shu", 4, 4, General.Female)
local fanghun = fk.CreateViewAsSkill{
  name = "fanghun",
  prompt = "#fanghun",
  pattern = "slash,jink",
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local c = Fk:getCardById(to_select)
    return c.trueName == "slash" or c.name == "jink"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, "fanghun")
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying", 1)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@meiying") > 0
  end,
}
local fanghun_record = fk.CreateTriggerSkill{
  name = "#fanghun_record",

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying", data.damage)
  end,
}
local fuhan = fk.CreateTriggerSkill{
  name = "fuhan",
  anim_type = "special",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:getMark("@meiying") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local maxHp = math.max(player:usedSkillTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fuhan-invoke:::"..maxHp)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    local generals = room:findGenerals(function(g)
      return Fk.generals[g].kingdom == "shu"
    end, 5)
    local general = room:askForGeneral(player, generals, 1, true)
    if general == nil then
      general = table.random(generals)
    end
    room:changeHero(player, general, false, false, true)
    local maxHp = math.max(n + player:usedSkillTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    room:changeMaxHp(player, maxHp - player.maxHp)
    player.gender = Fk.generals[player.general].gender
    room:broadcastProperty(player, "gender")
    if player.hp == 0 then
      room:killPlayer({who = player.id,})
    end
    if table.every(player.room:getOtherPlayers(player, false), function(p) return p.hp >= player.hp end) and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
fanghun:addRelatedSkill(fanghun_record)
zhaoxiang:addSkill(fanghun)
zhaoxiang:addSkill(fuhan)
Fk:loadTranslationTable{
  ["zhaoxiang"] = "赵襄",
  ["#zhaoxiang"] = "拾梅鹊影",
  ["designer:zhaoxiang"] = "千幻",
  ["illustrator:zhaoxiang"] = "木美人",
  ["fanghun"] = "芳魂",
  [":fanghun"] = "当你使用【杀】造成伤害后或受到【杀】造成的伤害后，你获得等于伤害值的“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",
  ["fuhan"] = "扶汉",
  [":fuhan"] = "限定技，准备阶段开始时，你可以移去所有“梅影”标记，随机观看五名未登场的蜀势力角色，将武将牌替换为其中一名角色，"..
  "并将体力上限数调整为本局游戏中移去“梅影”标记的数量（至少2，至多8），然后若你是体力值最低的角色，你回复1点体力。",
  ["#fanghun"] = "芳魂：你可以移去1个“梅影”标记，发动〖龙胆〗并摸一张牌",
  ["@meiying"] = "梅影",
  ["#fuhan-invoke"] = "扶汉：你可以变身为一名蜀势力武将！（体力上限为%arg）",

  ["$fanghun1"] = "万花凋落尽，一梅独傲霜。",
  ["$fanghun2"] = "暗香疏影处，凌风踏雪来！",
  ["$fuhan1"] = "承先父之志，扶汉兴刘。",
  ["$fuhan2"] = "天将降大任于我。",
  ["~zhaoxiang"] = "遁入阴影之中……",
}

local dongyun = General(extension, "dongyun", "shu", 3)
local bingzheng = fk.CreateTriggerSkill{
  name = "bingzheng",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not table.every(player.room:getAlivePlayers(), function(p) return p:getHandcardNum() == p.hp end)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getAlivePlayers(), function(p)
      return p:getHandcardNum() ~= p.hp end), Util.IdMapper), 1, 1, "#bingzheng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"bingzheng_draw"}
    if not to:isKongcheng() then
      table.insert(choices, 1, "bingzheng_discard")
    end
    local choice = room:askForChoice(player, choices, self.name, "#bingzheng-choice::"..to.id)
    if choice == "bingzheng_draw" then
      to:drawCards(1, self.name)
    else
      room:askForDiscard(to, 1, 1, false, self.name, false)
    end
    if #to.player_cards[Player.Hand] == to.hp then
      player:drawCards(1, self.name)
      if to ~= player then
        local card = room:askForCard(player, 1, 1, true, self.name, true, ".", "#bingzheng-card::"..to.id)
        if #card > 0 then
          room:obtainCard(to, card[1], false, fk.ReasonGive)
        end
      end
    end
  end,
}
local sheyan = fk.CreateTriggerSkill{
  name = "sheyan",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card:isCommonTrick() then
      local room = player.room
      local targets = room:getUseExtraTargets(data, true, true)
      local origin_targets = U.getActualUseTargets(room, data, event)
      if #origin_targets > 1 then
        table.insertTable(targets, origin_targets)
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.cost_data, 1, 1,
    "#sheyan-choose:::"..data.card:toLogString(), self.name, true, false, "addandcanceltarget_tip", AimGroup:getAllTargets(data.tos))
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if table.contains(AimGroup:getAllTargets(data.tos), self.cost_data) then
      AimGroup:cancelTarget(data, self.cost_data)
      return self.cost_data == player.id
    else
      AimGroup:addTargets(player.room, data, self.cost_data)
    end
  end,
}
dongyun:addSkill(bingzheng)
dongyun:addSkill(sheyan)
Fk:loadTranslationTable{
  ["dongyun"] = "董允",
  ["#dongyun"] = "骨鲠良相",
  ["designer:dongyun"] = "如释帆飞",
  ["illustrator:dongyun"] = "玖等仁品",
  ["bingzheng"] = "秉正",
  [":bingzheng"] = "出牌阶段结束时，你可以令手牌数不等于体力值的一名角色弃置一张手牌或摸一张牌。然后若其手牌数等于体力值，你摸一张牌，且可以交给该角色一张牌。",
  ["sheyan"] = "舍宴",
  [":sheyan"] = "当你成为一张普通锦囊牌的目标时，你可以为此牌增加一个目标或减少一个目标（目标数至少为一）。",
  ["#bingzheng-choose"] = "秉正：令一名角色弃一张手牌或摸一张牌，然后若其手牌数等于体力值，你摸一张牌且可以交给其一张牌",
  ["#bingzheng-choice"] = "秉正：选择令 %dest 执行的一项",
  ["bingzheng_discard"] = "其弃置一张手牌",
  ["bingzheng_draw"] = "其摸一张牌",
  ["#bingzheng-card"] = "秉正：你可以交给 %dest 一张牌",
  ["#sheyan-choose"] = "舍宴：你可以为%arg增加/减少一个目标",
  ["#collateral-choose"] = "请为对 %dest 使用的%arg指定被杀的目标",

  ["$bingzheng1"] = "自古，就是邪不胜正！",
  ["$bingzheng2"] = "主公面前，岂容小人搬弄是非！",
  ["$sheyan1"] = "公事为重，宴席不去也罢。",
  ["$sheyan2"] = "还是改日吧。",
  ["~dongyun"] = "大汉，要亡于宦官之手了……",
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

local ol__mazhong = General(extension, "ol__mazhong", "shu", 4)
local ol__fuman = fk.CreateActiveSkill{
  name = "ol__fuman",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("ol__fuman-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "ol__fuman-phase", 1)
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      skillName = self.name,
    })
  end,
}
local ol__fuman_trigger = fk.CreateTriggerSkill{
  name = "#ol__fuman_trigger",
  main_skill = ol__fuman,
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self, true) and data.card.trueName == "slash" then
      local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return #subcards == 1 and Fk:getCardById(subcards[1]):getMark("@@ol__fuman") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("ol__fuman")
    player.room:notifySkillInvoked(player, "ol__fuman", "drawcard")
    local num = (data.damageDealt) and 2 or 1
    player:drawCards(num, "ol__fuman")
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.skillName == "ol__fuman" and move.moveReason == fk.ReasonGive and move.to == player.id then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@ol__fuman", 1)
            Fk:filterCard(info.cardId, player)
          end
        end
      end
      if move.toArea ~= Card.Processing and move.skillName ~= "ol__fuman" then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@ol__fuman") > 0 then
            room:setCardMark(Fk:getCardById(info.cardId), "@@ol__fuman", 0)
          end
        end
      end
    end
  end,
}
local ol__fuman_filter = fk.CreateFilterSkill{
  name = "#ol__fuman_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@ol__fuman") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
ol__fuman:addRelatedSkill(ol__fuman_filter)
ol__fuman:addRelatedSkill(ol__fuman_trigger)
ol__mazhong:addSkill(ol__fuman)
Fk:loadTranslationTable{
  ["ol__mazhong"] = "马忠",
  ["#ol__mazhong"] = "笑合南中",
  ["ol__fuman"] = "抚蛮",
  [":ol__fuman"] = "出牌阶段每名角色限一次，你可以将一张手牌交给一名其他角色，此牌视为【杀】直到离开其手牌区。当其使用此【杀】结算后，你摸一张牌；若此【杀】造成过伤害，你改为摸两张牌。",
  ["@@ol__fuman"] = "抚蛮",
  ["#ol__fuman_filter"] = "抚蛮",

  ["$ol__fuman1"] = "国家兴亡，匹夫有责。",
  ["$ol__fuman2"] = "跟着我们丞相走，错不了！",
  ["~ol__mazhong"] = "南中不定，后患无穷……",
}

local heqi = General(extension, "heqi", "wu", 4)
local function QizhouChange(player, num, skill_name)
  local room = player.room
  local skills = player.tag["qizhou"]
  if type(skills) ~= "table" then skills = {} end
  local suits = {}
  for _, e in ipairs(player.player_cards[Player.Equip]) do
    table.insertIfNeed(suits, Fk:getCardById(e).suit)
  end
  if #suits >= num then
    if not table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, skill_name, "qizhou")
      table.insert(skills, skill_name)
    end
  else
    if table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, "-"..skill_name, "qizhou")
      table.removeOne(skills, skill_name)
    end
  end
  player.tag["qizhou"] = skills
end
local qizhou = fk.CreateTriggerSkill{
  name = "qizhou",
  frequency = Skill.Compulsory,
  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerEquip then
          return true
        end
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    QizhouChange(player, 1, "ol__duanbing")
    QizhouChange(player, 2, "ex__yingzi")
    QizhouChange(player, 3, "fenwei")
    QizhouChange(player, 4, "lanjiang")
  end,
}
Fk:addPoxiMethod{
  name = "shanxi_show",
  card_filter = function(to_select, selected, data)
    return #selected < #Self:getAvailableEquipSlots()
  end,
  feasible = function(selected)
    return #selected > 0
  end,
}
local shanxi = fk.CreateActiveSkill{
  name = "shanxi",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function ()
    return "#shanxi-choose:::"..#Self:getAvailableEquipSlots()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #player:getAvailableEquipSlots() > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and not target:inMyAttackRange(Self) and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local card_data = {}
    local to_hands = {}
    for i = 1, to:getHandcardNum() do
      table.insert(to_hands, -1)
    end
    if #to_hands > 0 then
      table.insert(card_data, { to.general, to_hands })
    end
    if not player:isKongcheng() then
      table.insert(card_data, { player.general, player.player_cards[Player.Hand] })
    end
    if #card_data == 0 then return end
    local cards = room:askForPoxi(player, "shanxi_show", card_data, nil, true)
    if #cards == 0 then return end
    local from_cards = table.filter(cards, function(id) return id ~= -1 end)
    local to_cards = (#from_cards == #cards) and {} or table.random(to:getCardIds("h"), #cards-#from_cards)
    player:showCards(from_cards)
    to:showCards(to_cards)
    cards = table.connect(from_cards, to_cards)
    local to_throw = table.filter(cards, function (id)
      return Fk:getCardById(id).name == "jink"
    end)
    if #to_throw > 0 then
      local moveInfos = {}
      local to_throw1 = table.filter(to_throw, function(id) return table.contains(from_cards, id)
      and not player:prohibitDiscard(Fk:getCardById(id)) end)
      if #to_throw1 > 0 then
        table.insert(moveInfos, {
          from = player.id,
          ids = to_throw1,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = player.id,
          skillName = self.name,
        })
      end
      local to_throw2 = table.filter(to_throw, function(id) return table.contains(to_cards, id) end)
      if #to_throw2 > 0 then
        table.insert(moveInfos, {
          from = to.id,
          ids = to_throw2,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = player.id,
          skillName = self.name,
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
      if player.dead or to.dead then return end
      card_data = {}
      if #to:getCardIds("e") > 0 then
        table.insert(card_data, { "$Equip", to:getCardIds("e") })
      end
      local nonshow = table.filter(to:getCardIds("h"), function(id) return not table.contains(to_cards, id) end)
      if #nonshow > 0 then
        to_hands = {}
        for i = 1, #nonshow do
          table.insert(to_hands, -1)
        end
        table.insert(card_data, { "$Hand", to_hands })
      end
      if #card_data == 0 then return end
      local card = room:askForCardChosen(player, to, { card_data = card_data }, self.name)
      if room:getCardArea(card) ~= Card.PlayerEquip then
        card = table.random(nonshow)
      end
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
}
heqi:addSkill(qizhou)
heqi:addSkill(shanxi)
heqi:addRelatedSkill("ol__duanbing")
heqi:addRelatedSkill("ex__yingzi")
heqi:addRelatedSkill("fenwei")
heqi:addRelatedSkill("lanjiang")
Fk:loadTranslationTable{
  ["heqi"] = "贺齐",
  ["#heqi"] = "马踏群峦",
  ["designer:heqi"] = "千幻",
  ["illustrator:heqi"] = "DH",
  ["qizhou"] = "绮胄",
  [":qizhou"] = "锁定技，你根据装备区里牌的花色数获得以下技能：1种以上-〖短兵〗；2种以上-〖英姿〗；3种以上-〖奋威〗；4种-〖澜疆〗。",
  ["shanxi"] = "闪袭",
  [":shanxi"] = "出牌阶段限一次，你可以展示你与一名攻击范围内不包含你的角色共计至多X张手牌（X为你的空置装备栏数），若其中有【闪】，弃置之，然后获得其一张未以此法展示的牌。",
  ["#shanxi-choose"] = "闪袭：展示你与一名攻击范围内不包含你的角色共计至多 %arg 张手牌",
  ["shanxi_show"] = "闪袭",

  ["$ex__yingzi_heqi"] = "人靠衣装马靠鞍！",
  ["$ol__duanbing_heqi"] = "可真是一把好刀啊！",
  ["$fenwei_heqi"] = "我的船队，要让全建业城的人都看见！",
  ["$lanjiang_heqi"] = "大江惊澜，浪涌四极之疆！",
  ["$shanxi1"] = "敌援未到，需要速战速决！",
  ["$shanxi2"] = "快马加鞭，赶在敌人戒备之前！",
  ["~heqi"] = "别拿走……我的装备！",
}

local kanze = General(extension, "kanze", "wu", 3)
local xiashu = fk.CreateTriggerSkill{
  name = "xiashu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
    1, 1, "#xiashu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:moveCardTo(player:getCardIds(Player.Hand), Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead or to.dead or to:isKongcheng() then return false end
    local cards = room:askForCard(to, 1, to:getHandcardNum(), false, self.name, false, ".", "#xiashu-card:"..player.id)
    to:showCards(cards)
    local choices = {"xiashu_show"}
    local x = to:getHandcardNum() - #cards
    if x > 0 then
      table.insert(choices, "xiashu_noshow:::" .. tostring(x))
    end
    local choice = U.askforViewCardsAndChoice(player, cards, choices, self.name, "#xiashu-choice::"..to.id)
    if choice ~= "xiashu_show" then
      cards = table.filter(to.player_cards[Player.Hand], function (id)
        return not table.contains(cards, id)
      end)
    end
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, choice == "xiashu_show", player.id)
  end,
}
local kuanshi = fk.CreateTriggerSkill{
  name = "kuanshi",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper),
    1, 1, "#kuanshi-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, self.cost_data)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}

local kuanshi_delay = fk.CreateTriggerSkill{
  name = "#kuanshi_delay",
  mute = true,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  --FIXME:跳过摸牌阶段的时机应该是TurnStart的
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      return data.damage > 1 and target and not target.dead and not player.dead and player:getMark("kuanshi") == target.id
    elseif event == fk.EventPhaseStart then
      return not player.dead and player == target and player.phase == Player.Start and player:getMark("@@kuanshi") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:notifySkillInvoked(player, kuanshi.name, "defensive")
      player:broadcastSkillInvoke(kuanshi.name)
      room:setPlayerMark(player, "kuanshi", 0)
      room:setPlayerMark(player, "@@kuanshi", 1)
      return true
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, kuanshi.name, "negative")
      player:broadcastSkillInvoke(kuanshi.name)
      room:setPlayerMark(player, "@@kuanshi", 0)
      player:skip(Player.Draw)
    end
  end,
}
kuanshi:addRelatedSkill(kuanshi_delay)
kanze:addSkill(xiashu)
kanze:addSkill(kuanshi)
Fk:loadTranslationTable{
  ["kanze"] = "阚泽",
  ["#kanze"] = "慧眼的博士",
  ["illustrator:kanze"] = "LiuHeng",
  ["xiashu"] = "下书",
  [":xiashu"] = "出牌阶段开始时，你可以将所有手牌交给一名其他角色，然后该角色亮出任意数量的手牌（至少一张），令你选择一项："..
  "1.获得其亮出的手牌；2.获得其未亮出的手牌。",
  ["kuanshi"] = "宽释",
  [":kuanshi"] = "结束阶段，你可以选择一名角色。直到你的下回合开始，该角色下一次受到超过1点的伤害时，防止此伤害，然后你跳过下个回合的摸牌阶段。",
  ["#xiashu-choose"] = "下书：将所有手牌交给一名角色，其展示任意张手牌，你获得展示或未展示的牌",
  ["#xiashu-card"] = "下书：展示任意张手牌，%src 选择获得你展示的牌或未展示的牌",
  ["xiashu_show"] = "获得展示的牌",
  ["xiashu_noshow"] = "获得未展示的牌[%arg张]",
  ["#xiashu-choice"] = "下书：选择获得 %dest 的牌",
  ["#kuanshi-choose"] = "宽释：你可以选择一名角色，直到你下回合开始，防止其下次受到超过1点的伤害",
  ["#kuanshi_delay"] = "宽释",
  ["@@kuanshi"] = "宽释",

  ["$xiashu1"] = "吾有密信，特来献于将军。",
  ["$xiashu2"] = "将军若不信，可亲自验看！",
  ["$kuanshi1"] = "不知者，无罪。",
  ["$kuanshi2"] = "罚酒三杯，下不为例。",
  ["~kanze"] = "我早已做好了牺牲的准备。",
}

local liuqi = General(extension, "liuqi", "qun", 3)
liuqi.subkingdom = "shu"
local wenji = fk.CreateTriggerSkill{
  name = "wenji",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not table.every(player.room:getOtherPlayers(player, false), function(p) return (p:isNude()) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, "#wenji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#wenji-give::"..player.id)
    room:setPlayerMark(player, "wenji-turn", Fk:getCardById(card[1]).trueName)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive)
  end,
}
local wenji_record = fk.CreateTriggerSkill{
  name = "#wenji_record",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("wenji", Player.HistoryTurn) > 0 and player:getMark("wenji-turn") ~= 0 and
      player:getMark("wenji-turn") == data.card.trueName
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local tunjiang = fk.CreateTriggerSkill{
  name = "tunjiang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      player:getMark("tunjiang-turn") == 0 and not player.skipped_phases[Player.Play]
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms, self.name)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("tunjiang-turn") == 0 and
      data.firstTarget and data.card.type ~= Card.TypeEquip
  end,
  on_refresh = function(self, event, target, player, data)
    if #AimGroup:getAllTargets(data.tos) == 0 then return end
    for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
      if id ~= player.id then
        player.room:addPlayerMark(player, "tunjiang-turn", 1)
        break
      end
    end
  end,
}
wenji:addRelatedSkill(wenji_record)
liuqi:addSkill(wenji)
liuqi:addSkill(tunjiang)
Fk:loadTranslationTable{
  ["liuqi"] = "刘琦",
  ["#liuqi"] = "居外而安",
  ["cv:liuqi"] = "戴超行",
  ["illustrator:liuqi"] = "NOVART",
  ["wenji"] = "问计",
  [":wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌同名的牌不能被其他角色响应。",
  ["tunjiang"] = "屯江",
  [":tunjiang"] = "结束阶段，若你未跳过本回合的出牌阶段，且你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。",
  ["#wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#wenji-give"] = "问计：你需交给 %dest 一张牌",

  ["$wenji1"] = "言出子口，入于吾耳，可以言未？",
  ["$wenji2"] = "还望先生救我！",
  ["$tunjiang1"] = "皇叔勿惊，吾与关将军已到。",
  ["$tunjiang2"] = "江夏冲要之地，孩儿愿往守之。",
  ["~liuqi"] = "父亲，孩儿来见你了。",
}

local tangzi = General(extension, "tangzi", "wei", 4)
tangzi.subkingdom = "wu"
local xingzhao = fk.CreateTriggerSkill{
  name = "xingzhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.HpChanged, fk.MaxHpChanged, fk.CardUsing, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.HpChanged or event == fk.MaxHpChanged then
        return (player:hasSkill("xunxun", true) and not table.find(player.room.alive_players, function(p) return p:isWounded() end)) or
          (not player:hasSkill("xunxun", true) and table.find(player.room.alive_players, function(p) return p:isWounded() end))
      elseif event == fk.CardUsing then
        return target == player and data.card.type == Card.TypeEquip and
          #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > 1
      else
        return target == player and data.to == Player.Discard and
          #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > 2
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.HpChanged or event == fk.MaxHpChanged then
      if player:hasSkill("xunxun", true) then
        player.room:handleAddLoseSkills(player, "-xunxun", self.name, true, false)
      else
        player.room:handleAddLoseSkills(player, "xunxun", self.name, true, false)
      end
    elseif event == fk.CardUsing then
      player:drawCards(1, self.name)
    else
      return true
    end
  end,
}
tangzi:addSkill(xingzhao)
Fk:loadTranslationTable{
  ["tangzi"] = "唐咨",
  ["#tangzi"] = "工学之奇才",
  ["designer:tangzi"] = "荼蘼",
  ["illustrator:tangzi"] = "NOVART",
  ["xingzhao"] = "兴棹",
  [":xingzhao"] = "锁定技，场上受伤的角色为：1个或以上，你拥有技能〖恂恂〗；2个或以上，你使用装备牌时摸一张牌；3个或以上，你跳过弃牌阶段。",

  ["$xingzhao1"] = "精挑细选，方能成百年之计。",
  ["$xingzhao2"] = "拿些上好的木料来。",
  ["$xunxun_tangzi1"] = "让我先探他一探。",
  ["$xunxun_tangzi2"] = "船，也不是一天就能造出来的。",
  ["~tangzi"] = "偷工减料要不得啊……",
}

local wangyun = General(extension, "wangyun", "qun", 4)
local lianji = fk.CreateActiveSkill{
  name = "lianji",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if target.dead then return end
    local cards = table.filter(room.draw_pile, function(id) return Fk:getCardById(id).sub_type == Card.SubtypeWeapon end)
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        room:moveCardTo(card, Card.Void, nil, fk.ReasonJustMove, self.name)
        card = room:printCard("seven_stars_sword", Card.Spade, 6)
      end
      if target:canUseTo(card, target) then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = card,
        })
      end
    end
    if target.dead or player.dead then return end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local victim = room:askForChoosePlayers(player, targets, 1, 1, "#lianji-choose::"..target.id, self.name, false)[1]
      room:doIndicate(target.id, {victim})
      local use = room:askForUseCard(target, "slash", "slash", "#lianji-slash:"..player.id..":"..victim, true,
      {exclusive_targets = {victim}, bypass_times = true})
      if use then
        room:useCard(use)
        if use.damageDealt then
          room:addPlayerMark(player, "moucheng", 1)
        end
        return false
      end
    end
    if target:getEquipment(Card.SubtypeWeapon) then
      local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#lianji-card::"..target.id, self.name, false)[1]
      room:moveCards({
        from = target.id,
        ids = target:getEquipments(Card.SubtypeWeapon),
        to = to,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local moucheng = fk.CreateTriggerSkill{
  name = "moucheng",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark(self.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-lianji|jingong", nil, true, false)
  end,
}
local jingong = fk.CreateViewAsSkill{
  name = "jingong",
  anim_type = "control",
  prompt = "#jingong",
  interaction = function()
    local names = Self:getMark("jingong-phase")
    if names == 0 then
      names = {"dismantlement", "ex_nihilo", "daggar_in_smile"}  --很难想象什么时候会用到这个默认值
    end
    return U.CardNameBox {choices = names}
  end,
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.trueName == "slash" or card.type == Card.TypeEquip)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
}
local jingong_record = fk.CreateTriggerSkill{
  name = "#jingong_record",

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and
        not table.contains({"nullification", "adaptation"}, card.name) then
        table.insertIfNeed(names, card.name)
      end
    end
    local cards = table.random(names, 2)
    names = {cards[1], cards[2], table.random({"honey_trap", "daggar_in_smile"})}
    player.room:setPlayerMark(player, "jingong-phase", names)
  end,
}
jingong:addRelatedSkill(jingong_record)
wangyun:addSkill(lianji)
wangyun:addSkill(moucheng)
wangyun:addRelatedSkill(jingong)
Fk:loadTranslationTable{
  ["wangyun"] = "王允",
  ["#wangyun"] = "忠魂不泯",
  ["illustrator:wangyun"] = "Thinking",
  ["lianji"] = "连计",
  [":lianji"] = "出牌阶段限一次，你可以弃置一张手牌并指定一名其他角色，其使用牌堆中的一张随机武器牌，然后令其选择一项：1.对其攻击范围内你指定的一名角色"..
  "使用【杀】；2.你将其装备区的武器牌交给任意一名角色。",
  ["moucheng"] = "谋逞",
  [":moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗令目标角色使用【杀】造成过伤害，则你失去〖连计〗，获得〖矜功〗。",
  ["jingong"] = "矜功",
  [":jingong"] = "出牌阶段限一次，你可以将一张装备牌或【杀】当一张锦囊牌使用（从两种随机普通锦囊牌和【美人计】、【笑里藏刀】随机一种中三选一）。",
  ["#lianji-choose"] = "连计：选择令 %dest 使用【杀】的目标",
  ["#lianji-slash"] = "连计：你需对 %dest 使用【杀】，否则 %src 将你的武器牌交给任意角色",
  ["#lianji-card"] = "连计：将 %dest 的武器交给一名角色",
  ["#jingong"] = "矜功：你可以将一张装备牌或【杀】当一张锦囊使用（从两种随机普通锦囊和一种随机专属锦囊中三选一）",

  ["$lianji1"] = "两计扣用，以催强势。",
  ["$lianji2"] = "容老夫细细思量。",
  ["$moucheng1"] = "董贼伏诛，天下太平！",
  ["$moucheng2"] = "叫天不应，叫地不灵，今天就是你的死期！",
  ["$jingong1"] = "董贼旧部，可尽诛之！",
  ["$jingong2"] = "若无老夫之谋，尔等皆化为腐土也。",
  ["~wangyun"] = "努力谢关东诸公，勤以国家为念！",
}

local quyi = General(extension, "quyi", "qun", 4)
local fuji = fk.CreateTriggerSkill{
  name = "fuji",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player, false), function(p) return p:distanceTo(player) == 1 end)
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player, false), function(p) return p:distanceTo(player) == 1 end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
local jiaozi = fk.CreateTriggerSkill{
  name = "jiaozi",
  anim_type = "offensive",
  events = {fk.DamageCaused, fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      table.every(player.room:getOtherPlayers(player, false), function(p)
        return player:getHandcardNum() > p:getHandcardNum() end)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
quyi:addSkill(fuji)
quyi:addSkill(jiaozi)
Fk:loadTranslationTable{
  ["quyi"] = "麴义",
  ["#quyi"] = "名门的骁将",
  ["cv:quyi"] = "冷泉月夜",
  ["illustrator:quyi"] = "王立雄", -- 稀有皮 界桥先登
  ["designer:quyi"] = "荼蘼",

  ["fuji"] = "伏骑",
  [":fuji"] = "锁定技，当你使用【杀】或普通锦囊牌时，你令所有至你距离为1的角色不能响应此牌。",
  ["jiaozi"] = "骄恣",
  [":jiaozi"] = "锁定技，当你造成或受到伤害时，若你的手牌为全场唯一最多，则此伤害+1。",

  ["$fuji1"] = "白马？不足挂齿！",
  ["$fuji2"] = "掌握之中，岂可逃之？",
  ["$jiaozi1"] = "数战之功，吾应得此赏！",
  ["$jiaozi2"] = "无我出力，怎会连胜？",
  ["~quyi"] = "主公，我无异心啊！",
}

local xizhicai = General(extension, "xizhicai", "wei", 3)
local updataXianfu = function (room, player, target)
  local mark = player:getTableMark("xianfu")
  table.insertIfNeed(mark[2], target.id)
  room:setPlayerMark(player, "xianfu", mark)
  local names = table.map(mark[2], function(pid) return Fk:translate(room:getPlayerById(pid).general) end)
  room:setPlayerMark(player, "@xianfu", table.concat(names, ","))
end
local xianfu = fk.CreateTriggerSkill{
  name = "xianfu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, math.random(2))
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#xianfu-choose", self.name, false, true)
    local mark = player:getTableMark(self.name)
    if #mark == 0 then mark = {{},{}} end
    table.insertIfNeed(mark[1], tos[1])
    room:setPlayerMark(player, self.name, mark)
  end,
}
local xianfu_delay = fk.CreateTriggerSkill{
  name = "#xianfu_delay",
  events = {fk.Damaged, fk.HpRecover},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getTableMark("xianfu")
    if not player.dead and not target.dead and #mark > 0 and table.contains(mark[1], target.id) then
      return event == fk.Damaged or player:isWounded()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    updataXianfu (room, player, target)
    room:sendLog{ type = "#SkillDelayInvoked", from = player.id, arg = "xianfu", }
    if event == fk.Damaged then
      player:broadcastSkillInvoke("xianfu", math.random(2)+2)
      room:damage{
        to = player,
        damage = data.damage,
        skillName = "xianfu",
      }
    else
      player:broadcastSkillInvoke("xianfu", math.random(2)+4)
      if player:isWounded() then
        room:recover{
          who = player,
          num = data.num,
          recoverBy = player,
          skillName = "xianfu",
        }
      end
    end
  end,
}
local chouce = fk.CreateTriggerSkill{
  name = "chouce",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if i > 1 and (self.cancel_cost or not player:hasSkill(self)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return false end
    if judge.card.color == Card.Red then
      local targets = table.map(room.alive_players, Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-draw", self.name, false)
      local to = room:getPlayerById(tos[1])
      local num = 1
      local mark = player:getTableMark("xianfu")
      if #mark > 0 and table.contains(mark[1], to.id) then
        num = 2
        updataXianfu (room, player, to)
      end
      to:drawCards(num, self.name)
    elseif judge.card.color == Card.Black then
      local targets = table.map(table.filter(room.alive_players, function(p) return not p:isAllNude() end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-discard", self.name, false)
      local to = room:getPlayerById(tos[1])
      local card = room:askForCardChosen(player, to, "hej", self.name)
      room:throwCard({card}, self.name, to, player)
    end
  end,
}
xianfu:addRelatedSkill(xianfu_delay)
xizhicai:addSkill("tiandu")
xizhicai:addSkill(xianfu)
xizhicai:addSkill(chouce)
Fk:loadTranslationTable{
  ["xizhicai"] = "戏志才",
  ["#xizhicai"] = "负俗的夭才",
  ["cv:xizhicai"] = "曹真",
  ["designer:xizhicai"] = "荼蘼",
  ["illustrator:xizhicai"] = "眉毛子",
  ["xianfu"] = "先辅",
  ["@xianfu"] = "先辅",
  [":xianfu"] = "锁定技，游戏开始时，你选择一名其他角色，当其受到伤害后，你受到等量的伤害；当其回复体力后，你回复等量的体力。",
  ["chouce"] = "筹策",
  [":chouce"] = "当你受到1点伤害后，你可以进行判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",
  ["#xianfu-choose"] = "先辅: 请选择要先辅的角色",
  ["#chouce-draw"] = "筹策: 令一名角色摸一张牌（若为先辅角色则摸两张）",
  ["#chouce-discard"] = "筹策: 弃置一名角色区域里的一张牌",
  ["#xianfu_delay"] = "先辅",
  ["#SkillDelayInvoked"] = "%from 的“%arg”的延迟效果被触发",

  ["$tiandu_xizhicai1"] = "天意，不可逆。",
  ["$tiandu_xizhicai2"] = "既是如此。",
  ["$xianfu1"] = "辅佐明君，从一而终。",
  ["$xianfu2"] = "吾于此生，竭尽所能。",
  ["$xianfu3"] = "春蚕至死，蜡炬成灰！",
  ["$xianfu4"] = "愿为主公，尽我所能。",
  ["$xianfu5"] = "赠人玫瑰，手有余香。",
  ["$xianfu6"] = "主公之幸，我之幸也。",
  ["$chouce1"] = "一筹一划，一策一略。",
  ["$chouce2"] = "主公之忧，吾之所思也。",
  ["~xizhicai"] = "为何……不再给我……一点点时间……",
}

local sufei = General(extension, "ol__sufei", "wu", 4)
sufei.subkingdom = "qun"
local lianpian = fk.CreateTriggerSkill{
  name = "lianpian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 3 then
      local room = player.room
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
      if phase_event == nil then return end
      local end_id = phase_event.id
      local tos
      if #room.logic:getEventsByRule(GameEvent.UseCard, 2, function (e)
        local use = e.data[1]
        if use.from == player.id then
          tos = use.tos
          return true
        end
        return false
      end, end_id) < 2 then return end
      if not tos then return end
      local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
        return table.contains(TargetGroup:getRealTargets(tos), id)
      end)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(1, self.name)
    if table.contains(player:getCardIds("h"), cards[1]) then
      local targets = table.filter(self.cost_data, function (id)
        return not room:getPlayerById(id).dead and id ~= player.id
      end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1,
        "#lianpian-choose:::"..Fk:getCardById(cards[1]):toLogString(), self.name, true)
      if #to > 0 then
        room:moveCardTo(cards, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, self.name, nil, false, player.id)
      end
    end
  end,
}
sufei:addSkill(lianpian)
Fk:loadTranslationTable{
  ["ol__sufei"] = "苏飞",
  ["#ol__sufei"] = "与子同袍",
  ["illustrator:ol__sufei"] = "兴游",
  ["lianpian"] = "联翩",
  [":lianpian"] = "每回合限三次，当你于出牌阶段内使用牌指定目标后，若此牌与你此阶段内使用的上一张牌有共同的目标角色，你可以摸一张牌，"..
  "然后你可以摸到的牌交给这些角色中的一名。",
  ["#lianpian-choose"] = "联翩：你可以将%arg交给其中一名角色",

  ["$lianpian1"] = "需持续投入，方有回报。",
  ["$lianpian2"] = "心无旁骛，断而敢行！",
  ["~ol__sufei"] = "恐不能再与兴霸兄……并肩奋战了……",
}

local huangquan = General(extension, "ol__huangquan", "shu", 3)
huangquan.subkingdom = "wei"
local dianhu = fk.CreateTriggerSkill{
  name = "dianhu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #player.room.alive_players > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, 1)
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
      "#dianhu-choose", self.name, false)
    to = room:getPlayerById(to[1])
    local mark =  to:getTableMark("@@dianhu")
    table.insert(mark, player.id)
    room:setPlayerMark(to, "@@dianhu", mark)
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and type(player:getMark("@@dianhu")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@@dianhu")
    table.removeOne(mark, target.id)
    player.room:setPlayerMark(player, "@@dianhu", #mark > 0 and mark or 0)
  end,
}
local dianhu_delay = fk.CreateTriggerSkill{
  name = "#dianhu_delay",
  events = {fk.Damaged, fk.HpRecover},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target and not (player.dead or target.dead) then
      local mark =  target:getTableMark("@@dianhu")
      if table.contains(mark, player.id) then
        if event == fk.Damaged then
          return data.from == player
        end
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(dianhu.name, 2)
    player:drawCards(1, dianhu.name)
  end,
}
local jianji = fk.CreateActiveSkill{
  name = "jianji",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#jianji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local id = target:drawCards(1, self.name)[1]
    if not target.dead and table.contains(target:getCardIds("h"), id) then
      room:askForUseRealCard(target, {id}, self.name, "#jianji-use")
    end
  end,
}
dianhu:addRelatedSkill(dianhu_delay)
huangquan:addSkill(dianhu)
huangquan:addSkill(jianji)
Fk:loadTranslationTable{
  ["ol__huangquan"] = "黄权",
  ["#ol__huangquan"] = "道绝殊途",
  ["illustrator:ol__huangquan"] = "兴游",

  ["dianhu"] = "点虎",
  [":dianhu"] = "锁定技，游戏开始时，你指定一名其他角色；当你对该角色造成伤害后或该角色回复体力后，你摸一张牌。",
  ["jianji"] = "谏计",
  [":jianji"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌，然后其可以使用该牌。",
  ["#dianhu_delay"] = "点虎",
  ["@@dianhu"] = "点虎",
  ["#dianhu-choose"] = "点虎：指定一名角色，本局当你对其造成伤害或其回复体力后，你摸一张牌",
  ["#jianji"] = "谏计：令一名其他角色摸一张牌，其可以使用之",
  ["#jianji-use"] = "谏计：你可以使用这张牌",

  ["$dianhu1"] = "预则立，不预则废！",
  ["$dianhu2"] = "就用你，给我军祭旗！",
  ["$jianji1"] = "锦上添花，不如雪中送炭。",
  ["$jianji2"] = "密计交于将军，可解燃眉之困。",
  ["~ol__huangquan"] = "魏王厚待于我，降魏又有何错？",
}

local luzhi = General(extension, "luzhiw", "wei", 3)
local qingzhong = fk.CreateTriggerSkill{
  name = "qingzhong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    player.room:setPlayerMark(player, "qingzhong-phase", 1)
  end,
}
local qingzhong_delay = fk.CreateTriggerSkill{
  name = "#qingzhong_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("qingzhong-phase") > 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      n = math.min(n, p:getHandcardNum())
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p:getHandcardNum() == n then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local cancelable = (n == player:getHandcardNum())
    local to
    if #targets == 1 and not cancelable then
      to = targets[1]
    else
      to = room:askForChoosePlayers(player, targets, 1, 1, "#qingzhong-choose", qingzhong.name, cancelable)[1]
    end
    if to then
      player:broadcastSkillInvoke(qingzhong.name)
      room:notifySkillInvoked(player, qingzhong.name, "support")
      U.swapHandCards(room, player, player, room:getPlayerById(to), qingzhong.name)
    end
  end,
}
qingzhong:addRelatedSkill(qingzhong_delay)
luzhi:addSkill(qingzhong)
local weijing = fk.CreateViewAsSkill{
  name = "weijing",
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    for _, name in ipairs({"slash","jink"}) do
      local card = Fk:cloneCard(name)
      if (Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card)) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return U.CardNameBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
}
luzhi:addSkill(weijing)
Fk:loadTranslationTable{
  ["luzhiw"] = "鲁芝",
  ["#luzhiw"] = "夷夏慕德",
  ["designer:luzhiw"] = "世外高v狼",
  ["illustrator:luzhiw"] = "秋呆呆",
  ["qingzhong"] = "清忠",
  [":qingzhong"] = "出牌阶段开始时，你可以摸两张牌，然后本阶段结束时，若有其他角色：和你一起并列场上手牌数最少，你可与这些角色中的一名交换手牌；比你手牌数少，你须与这些角色中手牌数最少的任意一名交换手牌。",
  ["weijing"] = "卫境",
  [":weijing"] = "每轮限一次，当你需要使用【杀】或【闪】时，你可以视为使用之。",
  ["#qingzhong-choose"] = "清忠：选择一名手牌数最少的其他角色，与其交换手牌",
  ["#weijing_record"] = "卫境",

  ["$qingzhong1"] = "执政为民，当尽我所能。",
  ["$qingzhong2"] = "吾自幼流离失所，更能体恤百姓之苦。",
  ["$weijing1"] = "战事兴起，最苦的，仍是百姓。",
  ["$weijing2"] = "国乃大家，保大家才有小家。",
  ["~luzhiw"] = "年迈力微，是该告老还乡了……",
}


local xujing = General(extension, "ol__xujing", "shu", 3)
local yuxu = fk.CreateTriggerSkill{
  name = "yuxu",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) % 2 == 1 or
    player.room:askForSkillInvoke(player, self.name, data, "#yuxu-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:usedSkillTimes(self.name, Player.HistoryPhase) % 2 == 1 then
      player:drawCards(1, self.name)
    else
      if not player:isNude() then
        room:askForDiscard(player, 1, 1, true, self.name, false)
      end
    end
  end,
}
local shijian = fk.CreateTriggerSkill{
  name = "shijian",
  anim_type = "support",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and target.phase == Player.Play and not player:isNude() and not target:hasSkill("yuxu",true) then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        return use.from == target.id
      end, Player.HistoryPhase)
      return #events == 2 and events[2].data[1] == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#shijian-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    room:handleAddLoseSkills(target, "yuxu")
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(target, "-yuxu")
    end)
  end,
}
xujing:addSkill(yuxu)
xujing:addSkill(shijian)
Fk:loadTranslationTable{
  ["ol__xujing"] = "许靖",
  ["#ol__xujing"] = "品评名士",
  ["designer:ol__xujing"] = "pui980178",
  ["illustrator:ol__xujing"] = "君桓文化",
  ["yuxu"] = "誉虚",
  [":yuxu"] = "当你于出牌阶段内使用牌结算结束后，若你于此阶段内发动过本技能的次数为：偶数，你可以摸一张牌；奇数，你弃置一张牌。",
  ["shijian"] = "实荐",
  [":shijian"] = "一名其他角色于其出牌阶段使用的第二张牌结算结束后，你可以弃置一张牌，令其获得〖誉虚〗直到回合结束。",
  ["#yuxu-invoke"] = "誉虚：你可以摸一张牌，然后你使用下一张牌后需弃置一张牌",
  ["#shijian-invoke"] = "实荐：你可以弃置一张牌，令%dest获得〖誉虚〗直到回合结束",

  ["$yuxu1"] = "誉名浮虚，播流四海。",
  ["$yuxu2"] = "誉虚之名，得保一时。",
  ["$shijian1"] = "国家安危，在于足下。",
  ["$shijian2"] = "行之得道，即社稷用宁。",
  ["~ol__xujing"] = "漂薄风波，绝粮茹草……",
}

local gaolan = General(extension, "ol__gaolan", "qun", 4)
local xiying = fk.CreateTriggerSkill{
  name = "xiying",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand|.|^basic", "#xiying-invoke", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "xiying_invoked-turn", 1)
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player, false), Util.IdMapper))
    room:throwCard(self.cost_data, self.name, player, player)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and #room:askForDiscard(p, 1, 1, true, self.name, true, ".", "#xiying-discard") == 0 then
        room:addPlayerMark(p, "@@xiying-turn", 1)
      end
    end
  end,
}
local xiying_delay = fk.CreateTriggerSkill{
  name = "#xiying_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player.phase == Player.Finish and player:getMark("xiying_invoked-turn") > 0 then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return false end
      local function PlayCheck (e)
        if e.data[1].from ~= player then return false end
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        return in_play
      end
      return #player.room.logic:getActualDamageEvents(1, PlayCheck) > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room.draw_pile, function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    if #cards > 0 then
      room:moveCards({
        ids = table.random(cards, 1),
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
xiying:addRelatedSkill(xiying_delay)
local xiying_prohibit = fk.CreateProhibitSkill{
  name = "#xiying_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@xiying-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@xiying-turn") > 0
  end,
}
xiying:addRelatedSkill(xiying_prohibit)
gaolan:addSkill(xiying)
Fk:loadTranslationTable{
  ["ol__gaolan"] = "高览",
  ["#ol__gaolan"] = "名门的峦柱",
  ["designer:ol__gaolan"] = "七哀",
  ["illustrator:ol__gaolan"] = "兴游",
  ["xiying"] = "袭营",
  [":xiying"] = "出牌阶段开始时，你可以弃置一张非基本手牌，令所有其他角色选择一项：1.弃置一张牌；2.本回合不能使用或打出牌。"..
  "若如此做，结束阶段，若你于本回合出牌阶段造成过伤害，你获得牌堆中一张【杀】或伤害锦囊牌。",
  ["#xiying_delay"] = "袭营",
  ["@@xiying-turn"] = "被袭营",
  ["#xiying-invoke"] = "袭营：你可以弃置一张非基本手牌，所有其他角色需弃置一张牌，否则其本回合不能使用或打出牌",
  ["#xiying-discard"] = "袭营：你需弃置一张牌，否则本回合不能使用或打出牌",
  
  ["$xiying1"] = "速袭曹营，以解乌巢之难！",
  ["$xiying2"] = "此番若功不能成，我军恐难以再战。",
  ["~ol__gaolan"] = "郭图小辈之计……误军呐！",
}

return extension
