local extension = Package:new("ol_qifu")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/qifu/skills")

Fk:loadTranslationTable{
  ["ol_qifu"] = "OL-祈福",
}

local guansuo = General:new(extension, "ol__guansuo", "shu", 4)
guansuo:addSkills { "ol__zhengnan", "xiefang" }
guansuo:addRelatedSkills { "ex__wusheng", "dangxian", "ty_ex__zhiman" }
Fk:loadTranslationTable{
  ["ol__guansuo"] = "关索",
  ["#ol__guansuo"] = "承父武志",
  ["illustrator:ol__guansuo"] = "白夜零BYL",

  ["$ex__wusheng_ol__guansuo"] = "关氏威名，可敌千军！",
  ["$dangxian_ol__guansuo"] = "一马当先，万险皆破！",
  ["$ty_ex__zhiman_ol__guansuo"] = "蛮夷之辈，不足为惧。",
  ["~ol__guansuo"] = "花落人陨情意消。",
}

local baosanniang = General:new(extension, "ol__baosanniang", "shu", 4, 4, General.Female)
baosanniang:addSkills { "ol__wuniang", "ol__xushen" }
baosanniang:addRelatedSkill("ol__zhennan")
Fk:loadTranslationTable{
  ["ol__baosanniang"] = "鲍三娘",
  ["#ol__baosanniang"] = "平南之巾帼",
  ["illustrator:ol__baosanniang"] = "DH",

  ["~ol__baosanniang"] = "我还想与你，共骑这雪花驹……",
}

local caoying = General:new(extension, "caoying", "wei", 4, 4, General.Female)
caoying:addSkills { "lingren", "fujian" }
caoying:addRelatedSkills { "ex__jianxiong", "xingshang" }
Fk:loadTranslationTable{
  ["caoying"] = "曹婴",
  ["#caoying"] = "龙城凤鸣",
  ["cv:caoying"] = "水原",
  ["illustrator:caoying"] = "花弟",
  ["designer:caoying"] = "韩旭",

  ["$ex__jianxiong_caoying"] = "且收此弩箭，不日奉还。",
  ["$xingshang_caoying"] = "此刀枪军械，尽归我有。",
  ["~caoying"] = "曹魏天下存，魂归故土安……",
}

General:new(extension, "ol__caochun", "wei", 4):addSkills { "ol__shanjia" }
Fk:loadTranslationTable{
  ["ol__caochun"] = "曹纯",
  ["#ol__caochun"] = "虎豹骑首",
  ["illustrator:ol__caochun"] = "磐蒲",

  ["~ol__caochun"] = "三属之下，竟也护不住我性命……",
}

General:new(extension, "yuantanyuanshang", "qun", 4):addSkills { "neifa" }
Fk:loadTranslationTable{
  ["yuantanyuanshang"] = "袁谭袁尚",
  ["#yuantanyuanshang"] = "兄弟阋墙",
  ["designer:yuantanyuanshang"] = "笔枔",
  ["illustrator:yuantanyuanshang"] = "MUMU",

  ["~yuantanyuanshang"] = "兄弟难齐心，该有此果……",
}

General:new(extension, "caoshuang", "wei", 4):addSkills { "tuogu", "shanzhuan" }
Fk:loadTranslationTable{
  ["caoshuang"] = "曹爽",
  ["#caoshuang"] = "托孤辅政",
  ["illustrator:caoshuang"] = "明暗交界",

  ["~caoshuang"] = "悔不该降了司马懿。",
}

General:new(extension, "wolongfengchu", "shu", 4):addSkills { "youlong", "luanfeng" }
Fk:loadTranslationTable{
  ["wolongfengchu"] = "卧龙凤雏",
  ["#wolongfengchu"] = "一匡天下",
  ["illustrator:wolongfengchu"] = "铁杵文化",
  ["designer:wolongfengchu"] = "张浩",

  ["~wolongfengchu"] = "铁链，东风，也难困这魏军……",
}

General:new(extension, "ol__panshu", "wu", 3, 3, General.Female):addSkills { "weiyi", "jinzhi" }
Fk:loadTranslationTable{
  ["ol__panshu"] = "潘淑",
  ["#ol__panshu"] = "江东神女",
  ["illustrator:ol__panshu"] = "君桓文化",
  ["designer:ol__panshu"] = "张浩",

  ["~ol__panshu"] = "本为织女，幸蒙帝垂怜……",
}

General:new(extension, "ol__fengfangnv", "qun", 3, 3, General.Female):addSkills { "zhuangshu", "chuiti" }
Fk:loadTranslationTable{
  ["ol__fengfangnv"] = "冯方女",
  ["#ol__fengfangnv"] = "为君梳妆浓",
  ["illustrator:ol__fengfangnv"] = "君桓文化",

  ["~ol__fengfangnv"] = "毒妇妒我……",
}

General:new(extension, "caoxiancaohua", "qun", 3, 3, General.Female):addSkills { "huamu", "qianmeng", "liangyuan", "jisi" }
Fk:loadTranslationTable{
  ["caoxiancaohua"] = "曹宪曹华",
  ["#caoxiancaohua"] = "与君化木",
  ["designer:caoxiancaohua"] = "玄蝶既白",
  ["illustrator:caoxiancaohua"] = "匠人绘",

  ["~caoxiancaohua"] = "爱恨有泪，聚散无常……",
}

General:new(extension, "ol__zhouchu", "jin", 4):addSkills { "shanduan", "yilie" }
Fk:loadTranslationTable{
  ["ol__zhouchu"] = "周处",
  ["#ol__zhouchu"] = "忠烈果毅",
  ["cv:ol__zhouchu"] = "陆泊云",
  ["illustrator:ol__zhouchu"] = "游漫美绘",

  ["~ol__zhouchu"] = "死战死谏，死亦可乎！",
}

General:new(extension, "ol__feiyi", "shu", 3):addSkills { "yanru", "hezhong" }
Fk:loadTranslationTable{
  ["ol__feiyi"] = "费祎",
  ["#ol__feiyi"] = "中才之相",
  ["designer:ol__feiyi"] = "廷玉",
  ["illustrator:ol__feiyi"] = "君桓文化",

  ["~ol__feiyi"] = "今为小人所伤，皆酒醉之误……",
}

General:new(extension, "ol__jiangwan", "shu", 3):addSkills { "ziruo", "xufa" }
Fk:loadTranslationTable{
  ["ol__jiangwan"] = "蒋琬",
  ["#ol__jiangwan"] = "社稷之器",
  ["illustrator:ol__jiangwan"] = "错落宇宙",
  ["designer:ol__jiangwan"] = "玄蝶即白",

  ["~ol__jiangwan"] = "臣既暗弱，加婴疾疢，规方无成……",
}

General:new(extension, "ol__xuelingyun", "wei", 3, 3, General.Female):addSkills { "siqi", "qiaozhi" }
Fk:loadTranslationTable{
  ["ol__xuelingyun"] = "薛灵芸",
  ["#ol__xuelingyun"] = "红烛垂泪",
  ["illustrator:ol__xuelingyun"] = "土豆",

  ["~ol__xuelingyun"] = "宫墙阻春柳，此心藏玉壶。",
}

return extension
