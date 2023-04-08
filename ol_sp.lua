local extension = Package("ol_sp")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp"] = "OL专属",
}

Fk:loadTranslationTable{
  ["zhugeke"] = "诸葛恪",
  ["aocai"] = "傲才",
  [":aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，若你观看的牌中有此牌，你可以使用或打出之。",
  ["duwu"] = "黩武",
  [":duwu"] = "出牌阶段，你可以弃置X张牌对你攻击范围内的一名其他角色造成1点伤害（X为该角色的体力值）。若你以此法令该角色进入濒死状态，则濒死状态结算后你失去1点体力，且本回合不能再发动“黩武”。",
}

local chengyu = General(extension, "chengyu", "wei", 3)
local shefu = fk.CreateTriggerSkill{
  name = "shefu",
  anim_type = "control",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isKongcheng()
      else
        return target ~= player and player.phase == Player.NotActive and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".")
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
      player:addToPile(self.name, self.cost_data, false, self.name)
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
    return target == player and target:hasSkill(self.name) and data.from ~= nil and not target.dead and #player.player_cards[Player.Hand] ~= #data.from.player_cards[Player.Hand] and #player.player_cards[Player.Hand] < 5
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if #player.player_cards[Player.Hand] > #data.from.player_cards[Player.Hand] then
      local _, discard = room:askForUseActiveSkill(player, "discard_skill", "#benyu-discard", true,{
        num = #player.player_cards[Player.Hand],
        min_num = #data.from.player_cards[Player.Hand] + 1,
        include_equip = false,
        reason = self.name,
        pattern = ".|.|.|hand|.|.",
      })
      if discard then
        self.cost_data = discard.cards
        return true
      end
    else
      self.cost_data = room:askForSkillInvoke(player, self.name)
      return self.cost_data
    end
  end,
  on_use = function(self, event, target, player, data)
    if type(self.cost_data) == "table" and #self.cost_data > 0 then
      player.room:throwCard(self.cost_data, self.name, player, player)
      player.room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = self.name,
      }
    else
      player:drawCards(math.min(5, #data.from.player_cards[Player.Hand]) - #player.player_cards[Player.Hand])
    end
  end,
}
chengyu:addSkill(shefu)
chengyu:addSkill(benyu)
Fk:loadTranslationTable{
  ["chengyu"] = "程昱",
  ["shefu"] = "设伏",
  [":shefu"] = "结束阶段开始时，你可将一张手牌扣置于武将牌上，称为“伏兵”。若如此做，你为“伏兵”记录一个基本牌或锦囊牌的名称（须与其他“伏兵”记录的名称均不同）。当其他角色于你的回合外使用手牌时，你可将记录的牌名与此牌相同的一张“伏兵”置入弃牌堆，然后此牌无效。",
  ["benyu"] = "贲育",
  [":benyu"] = "当你受到伤害后，若你的手牌数不大于伤害来源手牌数，你可以将手牌摸至与伤害来源手牌数相同（最多摸至5张）；否则你可以弃置大于伤害来源手牌数的手牌，然后对其造成1点伤害。",
  ["#benyu-discard"] = "贲育：你可以弃置大于伤害来源手牌数的手牌，对其造成1点伤害",
}

local sunhao = General(extension, "sunhao", "wu", 5)
local canshi = fk.CreateTriggerSkill{
  name = "canshi",
  anim_type = "drawcard",
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if p:isWounded() then
        n = n + 1
      end
    end
    player:drawCards(n)
    return true
  end,

  refresh_events ={fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and player:usedSkillTimes(self.name) > 0 and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name)
  end,
}
local chouhai = fk.CreateTriggerSkill{
  name = "chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
sunhao:addSkill(canshi)
sunhao:addSkill(chouhai)
Fk:loadTranslationTable{
  ["sunhao"] = "孙皓",
  ["canshi"] = "残蚀",
  [":canshi"] = "摸牌阶段开始时，你可以放弃摸牌，摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用基本牌或锦囊牌时，你弃置一张牌。",
  ["chouhai"] = "仇海",
  [":chouhai"] = "锁定技，当你受到伤害时，若你没有手牌，你令此伤害+1。",
  ["guiming"] = "归命",
  [":guiming"] = "主公技，锁定技，其他吴势力角色于你的回合内视为已受伤的角色。",
}

Fk:loadTranslationTable{
  ["shixie"] = "士燮",
  ["biluan"] = "避乱",
  [":biluan"] = "摸牌阶段开始时，若有其他角色与你距离为1，则你可以放弃摸牌，然后其他角色计算与你距离+X（X为势力数）。",
  ["lixia"] = "礼下",
  [":lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.其摸一张牌。然后其他角色与你的距离-1。",
}

Fk:loadTranslationTable{
  ["zhanglu"] = "张鲁",
  ["yishe"] = "义舍",
  [":yishe"] = "结束阶段开始时，若你的武将牌上没有牌，你可以摸两张牌。若如此做，你将两张牌置于武将牌上称为“米”，当“米”移至其他区域后，若你的武将牌上没有“米”，你回复1点体力。",
  ["bushi"] = "布施",
  [":bushi"] = "当你受到1点伤害后，或其他角色受到你造成的1点伤害后，受到伤害的角色可以获得一张“米”。",
  ["midao"] = "米道",
  [":midao"] = "当一张判定牌生效前，你可以打出一张“米”代替之。",
}

local mayunlu = General(extension, "mayunlu", "shu", 4, 4, General.Female)
local fengpo = fk.CreateTriggerSkill{
  name = "fengpo",
  anim_type = "offensive",
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and (data.card.trueName == "slash" or data.card.name == "duel") then
        return player:usedCardTimes("slash") + player:usedCardTimes("duel") <= 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if to:isKongcheng() then return end
    local n = 0
    for _, id in ipairs(to:getCardIds(Player.Hand)) do
      if Fk:getCardById(id).suit == Card.Diamond then
        n = n + 1
      end
    end
    local choice = room:askForChoice(player,{"fengpo_draw", "fengpo_damage"}, self.name)
    if choice == "fengpo_draw" then
      player:drawCards(n)
    else
      data.additionalDamage = (data.additionalDamage or 0) + n
    end
  end,
}
mayunlu:addSkill("mashu")
mayunlu:addSkill(fengpo)
Fk:loadTranslationTable{
  ["mayunlu"] = "马云騄",
  ["fengpo"] = "凤魄",
  [":fengpo"] = "当你于出牌阶段内使用的第一张【杀】或【决斗】仅指定唯一目标后，你可以选择一项:1.摸X张牌；2.此牌造成的伤害+X。(X为其♦手牌数)",
  ["fengpo_draw"] = "摸X张牌",
  ["fengpo_damage"] = "伤害+X",
}

--OL007 兀突骨
Fk:loadTranslationTable{
  ["cuiyan"] = "崔琰",
  ["yawang"] = "雅望",
  [":yawang"] = "锁定技，摸牌阶段开始时，你放弃摸牌，改为摸X张牌，然后你于出牌阶段内至多使用X张牌（X为与你体力值相等的角色数）。",
  ["xunzhi"] = "殉志",
  [":xunzhi"] = "准备阶段开始时，若你的上家和下家与你的体力值均不相等，你可以失去1点体力。若如此做，你的手牌上限+2。",
}
--王基
local guansuo = General(extension, "guansuo", "shu", 4)
local zhengnan = fk.CreateTriggerSkill{
  name = "zhengnan",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3)
    local choices = {"wusheng", "dangxian", "zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i]) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askForChoice(player, choices, self.name)
      player.room:handleAddLoseSkills(player, choice, nil)
    end
  end,
}
local xiefang = fk.CreateDistanceSkill{
  name = "xiefang",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.gender == General.Female then
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
Fk:loadTranslationTable{
  ["guansuo"] = "关索",
  ["zhengnan"] = "征南",
  [":zhengnan"] = "当其他角色死亡后，你可以摸三张牌，若如此做，你获得下列技能中的任意一个：“武圣”，“当先”和“制蛮”。",
  ["xiefang"] = "撷芳",
  [":xiefang"] = "锁定技，你计算与其他角色的距离-X（X为女性角色数）。",
}
Fk:loadTranslationTable{
  ["tadun"] = "蹋顿",
  ["luanzhan"] = "乱战",
  [":luanzhan"] = "你使用【杀】或黑色非延时类锦囊牌可以额外选择X名角色为目标；当你使用【杀】或黑色非延时类锦囊牌指定目标后，若此牌的目标角色数小于X，则X减至0。（X为你于本局游戏内造成过伤害的次数）。",
}
Fk:loadTranslationTable{
  ["yanbaihu"] = "严白虎",
  ["zhidao"] = "雉盗",
  [":zhidao"] = "锁定技，当你于出牌阶段内第一次对区域里有牌的其他角色造成伤害后，你获得其手牌、装备区和判定区里的各一张牌，然后直到回合结束，其他角色不能被选择为你使用牌的目标。",
  ["jili"] = "寄篱",
  [":jili"] = "锁定技，当一名其他角色成为红色基本牌或红色非延时类锦囊牌的目标时，若其与你的距离为1且你既不是此牌的使用者也不是目标，你也成为此牌的目标。",
}
Fk:loadTranslationTable{
  ["wanglang"] = "王朗",
  ["gushe"] = "鼓舌",
  [":gushe"] = "出牌阶段限一次，你可以用一张手牌与至多三名角色同时拼点，然后依次结算拼点结果，没赢的角色选择一项：1.弃置一张牌；2.令你摸一张牌。若拼点没赢的角色是你，你需先获得一个“饶舌”标记（你有7个饶舌标记时，你死亡）。",
  ["jici"] = "激词",
  [":jici"] = "当你发动“鼓舌”拼点的牌亮出后，若点数小于X，你可令点数+X；若点数等于X，视为你此回合未发动过“鼓舌”。（X为你“饶舌”标记的数量）。锁定技，当一名其他角色成为红色基本牌或红色非延时类锦囊牌的目标时，若其与你的距离为1且你既不是此牌的使用者也不是目标，你也成为此牌的目标。",
}

Fk:loadTranslationTable{
  ["litong"] = "李通",
  ["tuifeng"] = "推锋",
  [":tuifeng"] = "当你受到1点伤害后，你可以将一张牌置于武将牌上，称为“锋”。准备阶段开始时，若你的武将牌上有“锋”，你将所有“锋”置入弃牌堆，摸2X张牌，然后你于此回合的出牌阶段内使用【杀】的次数上限+X（X为你此次置入弃牌堆的“锋”数）。",
}
Fk:loadTranslationTable{
  ["mizhu"] = "糜竺",
  ["ziyuan"] = "资援",
  [":ziyuan"] = "出牌阶段限一次，你可以将任意张点数之和为13的手牌交给一名其他角色，然后该角色回复1点体力。",
  ["jugu"] = "巨贾",
  [":jugu"] = "锁定技，1.你的手牌上限+X。2.游戏开始时，你摸X张牌。（X为你的体力上限）",
}
Fk:loadTranslationTable{
  ["buzhi"] = "步骘",
  ["hongde"] = "弘德",
  [":hongde"] = "当你一次获得或失去至少两张牌后，你可以令一名其他角色摸一张牌。",
  ["dingpan"] = "定叛",
  [":dingpan"] = "出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。",
}

Fk:loadTranslationTable{
  ["dongbai"] = "董白",
  ["lianzhu"] = "连诛",
  [":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",
  ["xiahui"] = "黠慧",
  [":xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，其不能使用、打出、弃置这些牌直到其体力值减少为止。",
}

--赵襄
Fk:loadTranslationTable{
  ["dongyun"] = "董允",
  ["bingzheng"] = "秉正",
  [":bingzheng"] = "出牌阶段结束时，你可以令手牌数不等于体力值的一名角色弃置一张手牌或摸一张牌。然后若其手牌数等于体力值，你摸一张牌，且可以交给该角色一张牌。",
  ["sheyan"] = "舍宴",
  [":sheyan"] = "当你成为一张普通锦囊牌的目标时，你可以为此牌增加一个目标或减少一个目标（目标数至少为一）。",
}
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["fuman"] = "抚蛮",
  [":fuman"] = "出牌阶段，你可以将一张【杀】交给一名本回合未获得过“抚蛮”牌的其他角色，然后其于下个回合结束之前使用“抚蛮”牌时，你摸一张牌。",
}
Fk:loadTranslationTable{
  ["heqi"] = "贺齐",
  ["qizhou"] = "绮胄",
  [":qizhou"] = "锁定技，你根据装备区里牌的花色数获得以下技能：1种以上-马术；2种以上-英姿；3种以上-短兵；4种-奋威。",
  ["shanxi"] = "闪袭",
  [":shanxi"] = "出牌阶段限一次，你可以弃置一张红色基本牌，然后弃置攻击范围内的一名其他角色的一张牌，若弃置的牌是【闪】，你观看其手牌，若弃置的不是【闪】，其观看你的手牌。",
}
Fk:loadTranslationTable{
  ["kanze"] = "阚泽",
  ["xiashu"] = "下书",
  [":xiashu"] = "出牌阶段开始时，你可以将所有手牌交给一名其他角色，然后该角色亮出任意数量的手牌（至少一张），令你选择一项：1.获得其亮出的手牌；2.获得其未亮出的手牌。",
  ["kuanshi"] = "宽释",
  [":kuanshi"] = "结束阶段，你可以选择一名角色。直到你的下回合开始，该角色下一次受到超过1点的伤害时，防止此伤害，然后你跳过下个回合的摸牌阶段。",
}

Fk:loadTranslationTable{
  ["huangfusong"] = "皇甫嵩",
  ["fenyue"] = "奋钺",
  [":fenyue"] = "出牌阶段限X次，你可以与一名角色拼点，若你赢，你选择一项：1.其不能使用或打出手牌直到回合结束；2.视为你对其使用了【杀】（不计入次数限制）。若你没赢，你结束出牌阶段。（X为存活的忠臣数）。",
}

--刘琦
--唐咨
--王允

--麹义
--戏志才
Fk:loadTranslationTable{
  ["sunqian"] = "孙乾",
  ["qianya"] = "谦雅",
  [":qianya"] = "当你成为锦囊牌的目标后，你可以将任意张手牌交给一名其他角色。",
  ["shuimeng"] = "说盟",
  [":shuimeng"] = "出牌阶段结束时，你可以与一名角色拼点，若你赢，视为你使用【无中生有】；若你没赢，视为其对你使用【过河拆桥】。",
}

--审配 官渡 2017.12
--荀谌
--刘晔
--淳于琼

--苏飞 龙舟 2018.05
--黄权

--卑弥呼 2018.6.8
--鲁芝 2018.7.5

--鲍三娘
--曹婴 2019.2.28
local caoying = General(extension, "caoying", "wei", 4, 4, General.Female)
local lingren = fk.CreateTriggerSkill{
  name = "lingren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:usedSkillTimes(self.name) == 0 then
      if data.firstTarget and #AimGroup:getAllTargets(data.tos) > 0 then
        local pattern = "slash,duel,savage_assault,archery_attack,fire_attack"
        if data.card:matchPattern(pattern) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, data.tos[1], 1, 1, "#lingren-choose", self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"lingren_basic", "lingren_trick", "lingren_equip", "lingren_end"}
    local yes = {}
    for i = 1, 3, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "lingren_end" then
        break
      else
        table.insert(yes, choice)
        table.removeOne(choices, choice)
      end
    end
    table.removeOne(choices, "lingren_end")
    local right = 0
    for _, id in ipairs(to.player_cards[Player.Hand]) do
      local str = "lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    if right > 0 then data.card.extra_data = {self.name, self.cost_data} end  --can't use data.additionalDamage here!
    if right > 1 then player:drawCards(2) end
    if right > 2 then room:handleAddLoseSkills(player, "jianxiong|xingshang", nil, true, false) end
  end,

  refresh_events = {fk.DamageCaused, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, true) then
      if event == fk.DamageCaused then
        return data.card and data.card.extra_data and data.card.extra_data[1] == self.name and data.card.extra_data[2] == data.to.id
      else
        return data.to == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      player.room:handleAddLoseSkills(player, "-jianxiong|-xingshang", nil, true, false)
    end
  end,
}
local fujian = fk.CreateTriggerSkill {
  name = "fujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
      self.fujian_num = #player.player_cards[Player.Hand]
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] < self.fujian_num then
          self.fujian_num = #p.player_cards[Player.Hand]
        end
      end
      return self.fujian_num > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getOtherPlayers(player)[math.random(1, #room.alive_players - 1)]
    room:doIndicate(player.id, {to.id})
    local view = {}
    while #view < self.fujian_num do
      local id = to.player_cards[Player.Hand][math.random(1, #to.player_cards[Player.Hand])]
      table.insertIfNeed(view, id)
    end
    room:fillAG(player, view)
    room:delay(5000)
    room:closeAG(player)
  end,
}
caoying:addSkill(lingren)
caoying:addSkill(fujian)
Fk:loadTranslationTable{
  ["caoying"] = "曹婴",
  ["lingren"] = "凌人",
  [":lingren"] = "出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得技能〖奸雄〗和〖行殇〗直到你的下个回合开始。",
  ["fujian"] = "伏间",
  [":fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的X张手牌（X为全场手牌数最小的角色的手牌数）。",
  ["#lingren-choose"] = "凌人：你可以猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["lingren_end"] = "结束",
}
--许靖 2020.1.1
--袁谭袁尚 2020.2.7
--孙邵 2020.4.30
--神甄姬 神曹丕 2020.5.22
--（官渡）高览 2020.6.28
--曹爽 2020.9.4
--群张辽 2020.10.26
--晋 司马懿 张春华 司马师 夏侯徽 司马昭 王元姬 杜预 张虎乐綝 2020.12.15 应变篇
--张陵 2021.1.10
--卧龙凤雏 2021.2.7
--羊徽瑜 2021.3.12
--司马伷 2021.5.24
--卫瓘 石苞 彻里吉 潘淑 2021.6.9
--黄祖 2021.6.24
--钟琰 黄承彦 2021.7.15
--高干 杜袭2021.8.27
--吕旷吕翔 2021.9.15
--华歆2021.9.24
--邓芝 王荣 卞夫人2021.10.1
--左棻 2021.10.30
--杨艳 杨芷2021.11.17
--冯方女 杨仪 朱灵2021.12.24
--（官渡，未上线）辛评 韩猛2021.12.26
--宣公主 董昭 辛敞 吾彦2022.1.20
--陈登 田豫 范疆张达 朱灵2022.3.25
--羊祜 清河公主 贾充 2022.5.7
--滕芳兰2022.6.12
--群孟获 芮姬 王祥 卫兹2022.6.14
--郭槐
--神孙权（东吴命运线版） 赵俨2022.8.14
--周处 曹宪曹华2022.9.6
--王衍2022.9.29
--霍峻 邓忠2022.10.21
--夏侯玄2022.11.3
--张芝2022.11.19
--颍川荀氏：荀谌 荀淑 荀粲 荀采
--神孙权（制衡技能版）
--族：吴班 吴苋2022.12.24
--阿会喃 胡班2023.1.13
--傅肜2023.2.4
--刘巴2023.2.25
--族：韩韶 韩融
--马承2023.3.26

--手杀
--留赞 凌操 孙茹 
--朱灵 李丰
--诸葛果
--曹纯
--赵统赵广
--马钧
--祢衡
--陶谦
--庞德公
--司马昭 王元姬 2019.6.30
--审配 2019.9.17
--胡金定 2019.12.24
--贾逵 张翼 2020.3.12
--陈登 杨彪 2020.4.10
--杨仪 董承 2020.5.15
--郑玄（切水果） 邓芝 2020.6.20
--群张辽 群张郃 群徐晃 群甘宁 2020.6.30
--苏飞 通渠贾逵 2020.8.18
--傅肜 2020.9.22
--丁原 2020.10.24
--司马师 羊徽瑜 2020.11.28
--胡车儿 2021.1.5
--公孙康 2021.2.23
--智包：王粲 陈震 孙邵 荀谌 卞夫人 费祎 骆统 杜预 神郭嘉 荀彧2021.3.20
--理包：李肃2021.4.15
--南华（flappy bird） 2021.6.4
--信包：辛毗 吴景 糜夫人 王淩 王甫赵累 周处 孔融 羊祜 神太史慈 孙策 2021.6.4
--周群 
--谯周 2021.10.14
--仁包：华歆 许靖 蔡贞姬 向宠 张仲景 张温 刘璋 桥公 2021.8.22
--勇包：文鸯 陈武董袭 宗预 袁涣 花鬘 王双 孙翊 高览2021.11.10
--孙寒华（小游戏） 傅佥2021.11.10
--司马孚 阎圃 马元义2021.12.7
--严包：张昌蒲 崔琰 蒋琬 蒋钦 吕范 皇甫嵩 朱儁 2022.1.7
--杨婉 裴秀 刘赪 2022.1.7
--群黄忠 蒋干 2022.2.9
--毛玠2022.3.16
--杨阜 马日磾 刘巴2022.4.13
--阮慧2022.7.14
--王濬2022.9.16
--曹嵩2022.10.26
--彭羕2022.12.27
--群魏延2023.3.23

--海外
--群葛玄2021.9.9
--贾充2021.9.24
--朵思大王 乐就 吴班2021.10.1
--群于禁2021.11.11
--臧霸 刘宏 霍峻 群曹操 牛金（1v1技能组） 张曼成2022.3.3
--曹肇 濮阳兴 田豫 王昶 吴景 王粲 2022.4.14
--刘夫人 马腾 蹇硕 牛辅董翓 蒋济 邴原 鲍信 傅肜 陈武董袭 王淩2022.6.22
--张既 冯习 张宁 于夫罗2022.8.15
--张南 呼厨泉2022.9.29
--阎象 李遗2022.10.9
--夏侯尚 夏侯恩 2022.10.21
--桥蕤2022.11.18
--武侠：王越 李彦 童渊 徐庶2022.12.3
--魏续 郝萌2023.1.13

--特殊
--用间篇专属 
--1v1 及原稿 牛金 何进 韩遂 向宠 孙翊 朵思大王 注诣
--神貂蝉
--官盗：群曹操 孙寒华
return extension
