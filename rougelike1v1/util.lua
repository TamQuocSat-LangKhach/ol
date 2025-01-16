---@alias RougeItemEntry [integer, string, fun(self: string, player: ServerPlayer)?]

---@class RougeUtil
local RougeUtil = {
  talents = {},
  cards = {},
  skills = {},
}

-- 池子构建相关
------------------------

---@param talent RougeItemEntry
function RougeUtil:addTalent(talent)
  table.insert(self.talents, talent)
end

---@param talent RougeItemEntry
function RougeUtil:addBuffTalent(talent)
  talent[3] = function(self, player)
    RougeUtil.attachTalentToPlayer(player, self)
  end
  self:addTalent(talent)
end

---@param skill RougeItemEntry
function RougeUtil:addSkill(skill)
  table.insert(self.skills, skill)
end

-- 唉技能池
RougeUtil:addSkill { 0, "kunfen" }
local cost1skills = {
  "kongcheng", "qingguo", "keji", "yinghun", "lieren", "songci",
  -- "shenxian", -- TODO: 缺少OL星彩
  "shefu", "qizhi", "gushe", "sheyan", "shuimeng", "jiushi", "jueqing",
  "qice", "zhiyu", "quanji", "lijian", "shibei", "tianming", "zhuhai",
  "ex__fanjian", "juece", "fencheng", "zhuandui", "qianjie", "ex__biyue",
  "hunzi", "zhuijix", "ol_ex__shizhan", "xiangshu", "ciwei", "guanxing",
  "mengjin", "guzheng", "yongsi", "luoying", "jigong", "jj__lianhuan&",
  "ex__wusheng", "duanfa", "ol_ex__changbiao", "tairan", "qizhou", "wangxi",
}
local cost2skills = {
  "qingnang", "weimu", "shelie", "jingong", "xiansi",
  -- "boss__guiji", -- 不是，怎么有抓鬼的技能啊
  "weijing", "tieqi", "ganglie", "qixi", "jijiu", "bazhen", "tianyi",
  "xiangle", "beige", "ol__xuehen", "aocai", "kangkai", "benyu", "ol__zhendu",
  "mozhi", "juesi", "xiahui", "gongxin", "yeyan", "juejing", "chouce",
  "ol__yingyuan", -- 1v1池子里面有应援是吧
  "fenli", "yizhong", "qianxi", "lihuo", "ol__jingce", "yuce", "anjian",
  "danshou", "qiuyuan", "enyuan", "ex__yijue", "ex__tishen", "yajiao",
  "ex__yingzi", "ex__fankui", "qiaomeng", "huomo", "jishe", "fumian",
  "shouxi", "wenji", "zuilun", "fuyin", "langxi", "sidao", "zaiqi",
  "huqi", "guanxu", "beizhan", "shiyuan", "dingcuo", "zengou", "ol_ex__kanpo",
  "juguan", "wushuang", "jieming", "zhenlue", "tuifeng",
  -- "aozhan", 缺少鏖战
  "zhaxiang", "liyu", "guanwei", "guanchao", "ol_ex__huoji", "luoyi",
  "luanji", "jilei", "fengpo",
  -- "qimou", 缺少手杀界魏延
  "fanghun",
}
local cost3skills = {
  "ol__sanyao", "ol__caishi", "ol_ex__tiaoxin", "fengzi", "jizhan", "yiji",
  "niepan", "duwu", "liangzhu",
  -- "ol__linglong", 缺少ol群黄月英
  "jugu", "guixin", "lianpo", "buyi", "ol__sidi", "shenduan", "mingzhe",
  "ol__jieyuan", "ex__jianxiong", "huituo", "ol__qingxian", "shicai",
  "ex__zhiheng", "ex__luoshen", "ol_ex__leiji", "yuxu", "shenfu", "gn_jieying",
  "ex__longdan", "ol_ex__jiuchi", "ol_ex__tianxiang", "weiyi", "yashi",
  "ol_ex__qiangxi", "choufa", "ol_ex__wansha", "longyin",
  -- "shouyi" 缺少兽裔
  "ol_ex__jiang", "ol_ex__shuangxiong",
}
local cost4skills = {
  "ty__shanjia", "jinzhi", "chengxiang", "ol__zhuiji", "kurou", "baobian",
  "qiangwu", "ol__meibu", "luanzhan", "zhengnan", "ol_ex__kuanggu",
  "ol_ex__liegong", "ol__wushen", "longhun", "shenji", "fuji", "jiaozi",
  "re__pojun", "shangshi", "dangxian", "ty_ex__benxi", "qiangzhi", "jianying",
  "xiongluan", "lingren", "xionghuo", "neifa", "jili", "tuogu", "wangong",
  "jianhui", "ol_ex__botu", "ol__shichou", "yuheng",
}
for _, s in ipairs(cost1skills) do RougeUtil:addSkill { 1, s } end
for _, s in ipairs(cost2skills) do RougeUtil:addSkill { 2, s } end
for _, s in ipairs(cost3skills) do RougeUtil:addSkill { 3, s } end
for _, s in ipairs(cost4skills) do RougeUtil:addSkill { 4, s } end

--- 价格/牌名/点数/可能花色
---@param card [integer, string, integer, integer[]]
function RougeUtil:addCard(card)
  table.insert(self.cards, card)
end

local spade = { Card.Spade }
local heart = { Card.Heart }
local club = { Card.Club }
local diamond = { Card.Diamond }
local black = { Card.Spade, Card.Club }
local red = { Card.Heart, Card.Diamond }
local allsuits = { Card.Spade, Card.Heart, Card.Club, Card.Diamond }
RougeUtil:addCard { 0, "slash", 1, allsuits }
RougeUtil:addCard { 0, "jink", 2, allsuits }
RougeUtil:addCard { 1, "peach", 8, allsuits }
RougeUtil:addCard { 1, "analeptic", 9, allsuits }
RougeUtil:addCard { 0, "fire__slash", 13, red }
RougeUtil:addCard { 0, "thunder__slash", 13, black }
RougeUtil:addCard { 0, "dismantlement", 6, allsuits }
RougeUtil:addCard { 0, "amazing_grace", 5, allsuits }
RougeUtil:addCard { 0, "duel", 12, allsuits }
RougeUtil:addCard { 0, "lightning", 1, allsuits }
RougeUtil:addCard { 0, "god_salvation", 8, allsuits }
RougeUtil:addCard { 0, "nullification", 7, allsuits }
RougeUtil:addCard { 0, "iron_chain", 3, allsuits }
RougeUtil:addCard { 0, "collateral", 3, allsuits }
RougeUtil:addCard { 0, "fire_attack", 11, allsuits }
RougeUtil:addCard { 1, "snatch", 6, allsuits }
RougeUtil:addCard { 1, "savage_assault", 11, allsuits }
RougeUtil:addCard { 1, "archery_attack", 10, allsuits }
RougeUtil:addCard { 1, "supply_shortage", 4, allsuits }
RougeUtil:addCard { 1, "ex_nihilo", 10, allsuits }
RougeUtil:addCard { 2, "indulgence", 4, allsuits }
RougeUtil:addCard { 0, "crossbow", 1, diamond }
RougeUtil:addCard { 0, "qinggang_sword", 6, spade }
RougeUtil:addCard { 0, "blade", 5, spade }
RougeUtil:addCard { 0, "spear", 12, spade }
RougeUtil:addCard { 0, "kylin_bow", 5, heart }
RougeUtil:addCard { 0, "guding_blade", 1, spade }
RougeUtil:addCard { 0, "fan", 1, diamond }
RougeUtil:addCard { 0, "halberd", 12, diamond }
RougeUtil:addCard { 0, "ice_sword", 2, spade }
RougeUtil:addCard { 0, "triblade", 12, diamond }
RougeUtil:addCard { 0, "six_swords", 6, diamond }
RougeUtil:addCard { 0, "five_elements_fan", 1, diamond }
RougeUtil:addCard { 0, "black_chain", 13, spade }
RougeUtil:addCard { 1, "axe", 5, diamond }
RougeUtil:addCard { 1, "seven_stars_sword", 6, spade }
RougeUtil:addCard { 1, "py_double_halberd", 13, diamond }
-- RougeUtil:addCard { 2, "百辟刀", 2, spade }
RougeUtil:addCard { 0, "vine", 2, spade }
RougeUtil:addCard { 0, "breastplate", 1, club }
RougeUtil:addCard { 0, "dark_armor", 2, club }
RougeUtil:addCard { 1, "eight_diagram", 2, club }
RougeUtil:addCard { 1, "nioh_shield", 2, club }
RougeUtil:addCard { 1, "silver_lion", 1, club }
RougeUtil:addCard { 0, "wonder_map", 12, club }
RougeUtil:addCard { 0, "taigong_tactics", 2, spade }
RougeUtil:addCard { 1, "py_threebook", 5, spade }

-- 货币与商店相关
------------------------

---@param player ServerPlayer
---@param n integer
function RougeUtil.changeMoney(player, n)
  local money = player:getMark("rouge_money")
  money = math.max(0, money + n)
  player.room:setPlayerMark(player, "rouge_money", money)
end

---@param player ServerPlayer
function RougeUtil:generateShop(player)
  p(player:getTableMark("rougelike1v1_shop_items"))
  local data = player:getTableMark("rougelike1v1_shop_items")
  local n = player:getMark("rougelike1v1_shop_num") - #data
  if n > 0 then
    local a = math.random(0, math.min(2, n))
    local b = math.random(0, math.max(math.min(2, n - a), 0))

    local p_talents = player:getTableMark("@[rouge1v1]mark")
    local p_skills = table.map(player.player_skills, Util.NameMapper)

    local await = {
      talents = table.filter(self.talents, function(t)
        return not table.contains(p_talents, t[2])
      end),
      skills = table.filter(self.skills, function(s)
        return not table.contains(p_skills, s[2])
      end)
    }

    local talents = table.random(await.talents, n - a - b)
    local cards = table.random(self.cards, b)
    local skills = table.random(await.skills, a)

    for _, t in ipairs(talents) do
      table.insert(data, { "talent", t[1], t[2] })
    end
    for _, card in ipairs(cards) do
      table.insert(data, { "card", card[1], card[2], card[3], table.random(card[4]) })
    end
    for _, s in ipairs(skills) do
      table.insert(data, { "skill", table.unpack(s) })
    end
  end
  return data
end

-- 其余乱七八糟相关
-------------------------

---@param player ServerPlayer
---@param target ServerPlayer
function RougeUtil.isEnemy(player, target)
  return player.role ~= target.role
end

---@param player ServerPlayer
---@param talent string
function RougeUtil.sendTalentLog(player, talent)
  player.room:sendLog{
    type = "#rouge_talent_effect",
    from = player.id,
    arg = talent,
    arg2 = ":" .. talent,
    toast = true,
  }
end

---@param player ServerPlayer
---@param talent string
function RougeUtil.attachTalentToPlayer(player, talent)
  local room = player.room
  room:addTableMark(player, "@[rouge1v1]mark", talent)
end

---@param player Player
---@param talent string
function RougeUtil.hasTalent(player, talent)
  return table.contains(player:getTableMark("@[rouge1v1]mark"), talent)
end

---@param player ServerPlayer
---@param prefix string
---@return string[]
function RougeUtil.hasTalentStart(player, prefix)
  return table.filter(player:getTableMark("@[rouge1v1]mark"), function(talent)
    return talent:startsWith(prefix)
  end)
end

---@param player ServerPlayer
---@param talents string[]
function RougeUtil.hasOneOfTalents(player, talents)
  for _, talent in ipairs(talents) do
    if RougeUtil.hasTalent(player, talent) then
      return true
    end
  end
  return false
end

---@param player ServerPlayer
---@param skill_name string
function RougeUtil.attachSkillToPlayer(player, skill_name)
  local room = player.room
  room:handleAddLoseSkills(player, skill_name, nil, false)
  local mark = player:getTableMark("rouge_skills")
  -- TODO: 忘记初始技能的地方
  local n = player:getMark("@rougelike1v1_skill_num")
  if #mark >= n then
    local tolose = room:askForChoice(player, mark, "rougelike1v1", "#rouge-lose", true)
    room:handleAddLoseSkills(player, "-" .. tolose, nil, true)
    table.removeOne(mark, tolose)
  end
  table.insert(mark, skill_name)
  room:setPlayerMark(player, "rouge_skills", mark)
end

---@param players ServerPlayer[]
function RougeUtil:askForShopping(players)
  local room = players[1].room
  local command = "CustomDialog"
  local req = Request:new(players, command)
  req.focus_text = "rouge_shop"

  for _, p in ipairs(players) do
    local data = self:generateShop(p)
    room:setPlayerMark(p, "rougelike1v1_shop_items", 0)

    req:setData(p, {
      path = "packages/ol/rougelike1v1/RougeShop.qml",
      data = data,
    })
  end

  req:ask()

  for _, p in ipairs(players) do
    local result = req:getResult(p)
    if result ~= "" then
      local locked, ret = result[2], result[1]
      if locked then
        room:setPlayerMark(p, "rougelike1v1_shop_items", locked)
      end
      for _, dat in ipairs(ret) do
        RougeUtil.changeMoney(p, -dat[2])
        if dat[1] == "talent" then
          for _, t in ipairs(RougeUtil.talents) do
            if t[2] == dat[3] then
              room:sendLog {
                type = "#rouge_shop_buy_talent",
                from = p.id,
                arg = t[2],
              }
              t[3](t[2], p)
              break
            end
          end
        elseif dat[1] == "skill" then
          room:sendLog {
            type = "#rouge_shop_buy_skill",
            from = p.id,
            arg = dat[3],
          }
          RougeUtil.attachSkillToPlayer(p, dat[3])
        elseif dat[1] == "card" then
          local card = room:printCard(dat[3], dat[5], dat[4])
          room:sendLog {
            type = "#rouge_shop_buy_card",
            from = p.id,
            card = { card.id },
          }
          room:obtainCard(p, card, true, fk.ReasonJustMove, nil, "rougelike1v1", MarkEnum.DestructIntoDiscard)
        end
      end
    end
  end
end

Fk:addQmlMark{
  name = "rouge1v1",
  how_to_show = function(name, value, player)
    return Fk:translate("@[rouge1v1]"):format(#value, player:getMark("rouge_money"))
  end,
  qml_path = function (name, value, player)
    return "packages/utility/qml/DetailBox"
  end,
}

Fk:loadTranslationTable{
  ["rouge_money"] = "虎符",
  ["rouge_talent"] = "战法",
  ["@[rouge1v1]"] = "战法%d 虎符%d",
  ["@[rouge1v1]mark"] = "",
  ["rouge_shop"] = "虎符商店",
  ["#rouge_shop"] = "虎符商店：请选择要购买的能力",
  ["#rouge_current"] = "当前持有：%arg",
  ["rouge_shop_refresh"] = "刷新商店",
  ["rouge_shop_ok"] = "完成购买",
  ["rouge_shop_lock"] = "锁定商店",
  ["#rouge_shop_buy_skill"] = "%from 从虎符商店购买了 <font color='blue'>技能</font> %arg",
  ["#rouge_shop_buy_card"] = "%from 从虎符商店购买了 <font color='orange'>卡牌</font> %card",
  ["#rouge_shop_buy_talent"] = "%from 从虎符商店购买了 <font color='purple'>战法</font> %arg",
  ["#rouge_talent_effect"] = "%from 的 <font color='purple'>战法</font> %arg 生效：%arg2",
  ["@rougelike1v1_skill_num"]="技能槽数量",
  ["#rouge-lose"] = "单骑无双：技能槽已满，请选择要失去的技能",
}

return RougeUtil