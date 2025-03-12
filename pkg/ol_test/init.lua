local extension = Package:new("ol_test")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_test/skills")

Fk:loadTranslationTable{
  ["ol_test"] = "OL-测试服",
}

General:new(extension, "dongtuna", "qun", 4):addSkills { "jianman" }
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["#dongtuna"] = "铅刀拿云",
  ["designer:dongtuna"] = "大宝",
  ["illustrator:dongtuna"] = "monkey",

  ["~dongtuna"] = "孟获小儿，安敢杀我！",
}

General:new(extension, "ol__peixiu", "wei", 4):addSkills { "maozhu", "jinlan" }
Fk:loadTranslationTable{
  ["ol__peixiu"] = "裴秀",
  ["#ol__peixiu"] = "勋德茂著",

  ["~ol__peixiu"] = "",
}

General:new(extension, "budugen", "qun", 4):addSkills { "kouchao" }
Fk:loadTranslationTable{
  ["budugen"] = "步度根",
  ["#budugen"] = "秋城雁阵",

  ["~budugen"] = "",
}

General:new(extension, "kongshu", "qun", 3, 3, General.Female):addSkills { "leiluan", "fuchao" }
Fk:loadTranslationTable{
  ["kongshu"] = "孔淑",
  --["#kongshu"] = "",

  ["~kongshu"] = "",
}

General:new(extension, "ol__niufu", "qun", 4):addSkills { "shisuan", "zonglue" }
Fk:loadTranslationTable{
  ["ol__niufu"] = "牛辅",
  --["#ol__niufu"] = "",

  ["~ol__niufu"] = "",
}

General:new(extension, "ol__wuanguo", "qun", 4):addSkills { "liyongw" }
Fk:loadTranslationTable{
  ["ol__wuanguo"] = "武安国",
  --["#ol__wuanguo"] = "",

  ["~ol__wuanguo"] = "",
}

General:new(extension, "ol__guozhao", "wei", 3, 3, General.Female):addSkills { "jiaoyu", "neixun" }
Fk:loadTranslationTable{
  ["ol__guozhao"] = "郭照",
  --["#ol__guozhao"] = "",

  ["~ol__guozhao"] = "",
}

General:new(extension, "ol__liuzhang", "qun", 3):addSkills { "fengwei", "zonghu" }
Fk:loadTranslationTable{
  ["ol__liuzhang"] = "刘璋",
  --["#ol__liuzhang"] = "",

  ["~ol__liuzhang"] = "",
}

General:new(extension, "ol__yuanhuan", "qun", 3):addSkills { "deru", "linjie" }
Fk:loadTranslationTable{
  ["ol__yuanhuan"] = "袁涣",
  --["#ol__yuanhuan"] = "",

  ["~ol__yuanhuan"] = "",
}

General:new(extension, "ol__yangfeng", "qun", 4):addSkills { "jiawei" }
Fk:loadTranslationTable{
  ["ol__yangfeng"] = "杨奉",
  --["#ol__yangfeng"] = "",

  ["~ol__yangfeng"] = "",
}

General:new(extension, "hanshiwuhu", "wei", 4):addSkills { "juejueh", "pimi" }
Fk:loadTranslationTable{
  ["hanshiwuhu"] = "韩氏五虎",
  --["#hanshiwuhu"] = "",

  ["~hanshiwuhu"] = "我的儿呀！好你个老匹夫！",
}

General:new(extension, "ol__xiahouen", "wei", 4):addSkills { "yinfeng", "fulux" }
Fk:loadTranslationTable{
  ["ol__xiahouen"] = "夏侯恩",
  --["#ol__xiahouen"] = "",

  ["~ol__xiahouen"] = "丞相！就是他抢咱们东西！",
}

General:new(extension, "ol__yangfu", "wei", 3).hidden = true
Fk:loadTranslationTable{
  ["ol__yangfu"] = "杨阜",
  --["#ol__yangfu"] = "",

  ["~ol__yangfu"] = "",
}

General:new(extension, "ol__peiyuanshao", "qun", 4).hidden = true
Fk:loadTranslationTable{
  ["ol__peiyuanshao"] = "裴元绍",
  --["#ol__peiyuanshao"] = "",

  ["~ol__peiyuanshao"] = "",
}

General:new(extension, "olz__xunshuang", "qun", 3).hidden = true
Fk:loadTranslationTable{
  ["olz__xunshuang"] = "族荀爽",
  --["#olz__xunshuang"] = "",

  ["~olz__xunshuang"] = "",
}

General:new(extension, "ol__zhangmancheng", "qun", 5).hidden = true
Fk:loadTranslationTable{
  ["ol__zhangmancheng"] = "张曼成",
  --["#ol__zhangmancheng"] = "",

  ["~ol__zhangmancheng"] = "",
}

General:new(extension, "ol__guanhai", "qun", 4).hidden = true
Fk:loadTranslationTable{
  ["ol__guanhai"] = "管亥",
  --["#ol__guanhai"] = "",

  ["~ol__guanhai"] = "",
}

return extension
