local bolan = fk.CreateSkill{
  name = "bolan",
  attached_skill_name = "bolan&",
}

Fk:loadTranslationTable{
  ["bolan"] = "博览",
  [":bolan"] = "出牌阶段开始时，你可以从随机三个“出牌阶段限一次”的技能中选择一个获得直到本阶段结束；其他角色的出牌阶段限一次，"..
  "其可以失去1点体力，令你从随机三个“出牌阶段限一次”的技能中选择一个，其获得之直到此阶段结束。"..
  "<br><font color='red'>村：“博览”技能池为多服扩充版，且不会出现房间禁卡",

  ["#bolan-choice"] = "博览：选择令 %dest 此阶段获得技能",

  ["$bolan1"] = "博览群书，融会贯通。",
  ["$bolan2"] = "博览于文，约之以礼。",
}

BolanSkills = {
  --ol official skills
  "quhu", "qiangxi", "qice", "daoshu", "ol_ex__tiaoxin", "qiangwu", "tianyi", "ex__zhiheng", "ex__jieyin", "ex__guose",
  "lijian", "qingnang", "lihun", "mingce", "mizhao", "sanchen", "gongxin", "ex__chuli",
  --standard
  "ex__kurou", "ex__yijue", "fanjian", "ex__fanjian", "dimeng", "jijie", "poxi", "jueyan", "zhiheng","feijun", "tiaoxin",
  --sp
  "quji", "dahe", "tanhu", "fenxun","xueji", "re__anxu",
  --yjcm
  "nos__xuanhuo", "xinzhan", "nos__jujian", "ganlu", "xianzhen", "anxu", "gongqi", "huaiyi", "zhige", "anguo", "mingjian", "mieji",
  "duliang","junxing",
  --ol
  "ziyuan", "lianzhu", "shanxi", "lianji", "jianji", "liehou", "xianbi", "shidu", "yanxi", "xuanbei", "yushen", "bolong", "fuxun",
  "qiuxin", "ol_ex__dimeng", "juguan", "ol__xuehen", "ol__fenxun", "weikui", "caozhaoh", "ol_ex__changbiao","qingyix","qin__qihuo",
  "lilun","chongxin","xiaosi", "ol__mouzhu",
  --mobile
  "wuyuan", "zhujian", "duansuo", "poxiang", "hannan", "shihe", "wisdom__qiai", "shameng", "zundi", "mobile__shangyi", "yangjie",
  "m_ex__anxu", "beizhu", "mobile__zhouxuan", "mobile__yizheng", "guli", "m_ex__xianzhen", "m_ex__ganlu", "m_ex__mieji",
  "qiaosi", "pingcai","guanxu","guangu","shandao", "mou__zhiheng", "m_ex__junxing","mobile__yinju","dingzhou","guanzong","huiyao",
  --mougong
  "mou__qixi", "mou__lijian",
  --overseas
  "os__jimeng", "os__beini", "os__yuejian", "os__waishi", "os__weipo", "os__shangyi", "os__jinglue", "os__zhanyi", "os__daoji",
  "os_ex__gongqi", "os__gongxin", "os__zhuidu", "os__danlie","os__mutao",
  --tenyear
  "guolun", "kuiji", "ty__jianji", "caizhuang", "xinyou", "tanbei", "lueming", "ty__songshu", "ty__mouzhu", "libang", "nuchen",
  "weiwu", "ty__qingcheng", "ty__jianshu", "qiangzhiz", "ty__fenglue", "boyan", "ty_ex__mingce", "ty_ex__anxu",
  "ty_ex__mingjian", "ty_ex__quji", "jianzheng", "ty_ex__jixu", "ty__kuangfu", "yingshui", "weimeng", "tunan", "ty_ex__ganlu",
  "ty_ex__gongqi","huahuo","qiongying","jichun","xiaowu","mansi","kuizhen","zigu","ty_ex__wurong","jiuxianc","ty__lianji",
  "ty__xiongsuan","channi","ty__lianzhu","ty__beini","minsi","zhuren","cuijian", "changqu","ty__jiaohao","qingtan","yanjiao",
  "liangyan",
  --jsrg
  "js__yizheng", "shelun", "lunshi", "chushi", "pingtao","js__lianzhu","js__jinfa", "duxing", "yangming",
  --offline
  "miaojian", "xuepin", "ofl__shameng", "lifengs", "duyi", "mixin",
  --mini,
  "mini_yanshi", "mini_jifeng", "mini__jieyin", "mini__qiangwu", "mini_zhujiu",
}

---@param room Room
local getBolanSkills = function(room)
  local mark = room:getBanner("BolanSkills")
  if mark then
    return mark
  else
    local all_skills = {}
    for _, g in ipairs(room.general_pile) do
      for _, s in ipairs(Fk.generals[g]:getSkillNameList()) do
        table.insert(all_skills, s)
      end
    end
    local skills = table.filter(BolanSkills, function(s) return table.contains(all_skills, s) end)
    room:setBanner("BolanSkills", skills)
    return skills
  end
end

bolan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bolan.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.filter(getBolanSkills(room), function (skill_name)
      return not player:hasSkill(skill_name, true)
    end)
    if #skills > 0 then
      local choice = room:askToChoice(player, {
        choices = table.random(skills, 3),
        skill_name = bolan.name,
        prompt = "#bolan-choice::"..player.id,
        detailed = true,
      })
      room:handleAddLoseSkills(player, choice)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..choice)
      end)
    end
  end,
})

return bolan
