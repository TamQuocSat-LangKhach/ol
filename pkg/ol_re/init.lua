local extension = Package:new("ol_re")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_re/skills")

Fk:loadTranslationTable{
  ["ol_re"] = "OL修改",
}

General:new(extension, "ol__sunliang", "wu", 3):addSkills { "ol__kuizhu", "ol__chezheng", "ol__lijun" }
Fk:loadTranslationTable{
  ["ol__sunliang"] = "孙亮",
  ["#ol__sunliang"] = "寒江枯木",
  ["cv:ol__sunliang"] = "徐刚",
  ["illustrator:ol__zhol__sunliangoufei"] = "alien",

  ["~ol__sunliang"] = "君不君，臣不臣，此国之悲……",
}

General:new(extension, "ol__zhoufei", "wu", 3, 3, General.Female):addSkills { "ol__liangyin", "ol__kongsheng" }
Fk:loadTranslationTable{
  ["ol__zhoufei"] = "周妃",
  ["#ol__zhoufei"] = "软玉温香",
  ["designer:ol__zhoufei"] = "玄蝶既白",
  ["illustrator:ol__zhoufei"] = "圆子",

  ["~ol__zhoufei"] = "梧桐半枯衰，鸳鸯白头散……",
}

General:new(extension, "ol__godguanyu", "god", 5):addSkills { "ol__wushen", "wuhun" }
Fk:loadTranslationTable{
  ["ol__godguanyu"] = "神关羽",
  ["#ol__godguanyu"] = "鬼神再临",
  ["illustrator:ol__godguanyu"] = "秋呆呆",

  ["$wuhun_ol__godguanyu1"] = "还我头来！",
  ["$wuhun_ol__godguanyu2"] = "不杀此人，何以雪恨？",
  ["~ol__godguanyu"] = "夙愿已了，魂归地府。",
}

General:new(extension, "ol__godzhangliao", "god", 4):addSkills { "ol__duorui", "ol__zhiti" }
Fk:loadTranslationTable{
  ["ol__godzhangliao"] = "神张辽",
  ["#ol__godzhangliao"] = "雁门之刑天",

  ["~ol__godzhangliao"] = "辽来，辽来！辽去！辽去……",
}

General:new(extension, "ol__masu", "shu", 3):addSkills { "ol__sanyao", "ty_ex__zhiman" }
Fk:loadTranslationTable{
  ["ol__masu"] = "马谡",
  ["#ol__masu"] = "军略之才器",
  ["designer:ol__masu"] = "豌豆帮帮主",
  ["illustrator:ol__masu"] = "鬼画府",

  ["$ty_ex__zhiman_ol__masu1"] = "覆军杀将非良策也，当服其心以求长远。",
  ["$ty_ex__zhiman_ol__masu2"] = "欲平南中之叛，当以攻心为上。",
  ["~ol__masu"] = "悔不听王平之言，铸此大错……",
}

General:new(extension, "ol__guohuai", "wei", 3):addSkills { "ol__jingce" }
Fk:loadTranslationTable{
  ["ol__guohuai"] = "郭淮",
  ["#ol__guohuai"] = "垂问秦雍",
  ["illustrator:ol__guohuai"] = "张帅",

  ["~ol__guohuai"] = "穷寇莫追……",
}

General:new(extension, "ol__caozhen", "wei", 4):addSkills { "ol__sidi" }
Fk:loadTranslationTable{
  ["ol__caozhen"] = "曹真",
  ["#ol__caozhen"] = "荷国天督",
  ["illustrator:ol__caozhen"] = "biou09",

  ["~ol__caozhen"] = "三马共槽，养虎为患哪！",
}

General:new(extension, "ol__guyong", "wu", 3):addSkills { "shenxing", "ol__bingyi" }
Fk:loadTranslationTable{
  ["ol__guyong"] = "顾雍",
  ["#ol__guyong"] = "庙堂的玉磐",
  ["designer:ol__guyong"] = "玄蝶既白",
  ["illustrator:ol__guyong"] = "Sky",

  ["$shenxing_ol__guyong1"] = "上兵伐谋，三思而行。",
  ["$shenxing_ol__guyong2"] = "精益求精，慎之再慎。",
  ["~ol__guyong"] = "此番患疾，吾必不起……",
}

local jikang = General:new(extension, "ol__jikang", "wei", 3)
jikang:addSkills { "ol__qingxian", "ol__juexiang" }
jikang:addRelatedSkills { "ol__jixian", "ol__liexian", "ol__rouxian", "ol__hexian" }
Fk:loadTranslationTable{
  ["ol__jikang"] = "嵇康",
  ["#ol__jikang"] = "峻峰孤松",
  ["illustrator:ol__jikang"] = "凝聚永恒",

  ["~ol__jikang"] = "曲终人散，空留余音……",
}

General:new(extension, "ol__xinxianying", "wei", 3, 3, General.Female):addSkills { "ol__zhongjian", "ol__caishi" }
Fk:loadTranslationTable{
  ["ol__xinxianying"] = "辛宪英",
  ["#ol__xinxianying"] = "名门智女",
  ["designer:ol__xinxianying"] = "如释帆飞",
  ["illustrator:ol__xinxianying"] = "凝聚永恒",

  ["~ol__xinxianying"] = "料人如神，而难自知啊……",
}

return extension
