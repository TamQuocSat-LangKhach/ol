local extension = Package:new("ol_mou")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_mou/skills")

Fk:loadTranslationTable{
  ["ol_mou"] = "OL-上兵伐谋",
  ["olmou"] = "OL谋",
}

--谋定天下：姜维 庞统
local jiangwei = General:new(extension, "olmou__jiangwei", "shu", 4)
jiangwei:addSkills { "zhuri", "ranji" }
jiangwei:addRelatedSkills { "kunfenEx", "ol_ex__zhaxiang" }
Fk:loadTranslationTable{
  ["olmou__jiangwei"] = "谋姜维",
  ["#olmou__jiangwei"] = "炎志灼心",
  ["designer:olmou__jiangwei"] = "王秀丽",
  ["illustrator:olmou__jiangwei"] = "西国红云",

  ["$kunfenEx_olmou__jiangwei"] = "虽千万人，吾往矣！",
  ["$ol_ex__zhaxiang_olmou__jiangwei"] = "亡国之将姜维，请明公驱驰！",
  ["~olmou__jiangwei"] = "姜维姜维……又将何为？",
}

local pangtong = General:new(extension, "olmou__pangtong", "shu", 3)
pangtong:addSkills { "hongtu", "qiwu" }
pangtong:addRelatedSkills { "feijun", "re__qianxi" }
Fk:loadTranslationTable{
  ["olmou__pangtong"] = "谋庞统",
  ["#olmou__pangtong"] = "定鼎巴蜀",
  ["illustrator:olmou__pangtong"] = "黯荧岛工作室",

  ["~olmou__pangtong"] = "未与孔明把酒锦官城，恨也，恨也……",
}

--武动乾坤：关羽 董卓
General:new(extension, "olmou__guanyu", "shu", 4):addSkills { "weilingy", "duoshou" }
Fk:loadTranslationTable{
  ["olmou__guanyu"] = "谋关羽",
  ["#olmou__guanyu"] = "威震华夏",
  ["illustrator:olmou__guanyu"] = "匠人绘",

  ["~olmou__guanyu"] = "玉碎不改白，竹焚不毁节……",
}

local dongzhuo = General:new(extension, "olmou__dongzhuo", "qun", 4)
dongzhuo:addSkills { "guanbian", "xiongni", "fengshang", "zhibing" }
dongzhuo:addRelatedSkills { "ty_ex__fencheng", "benghuai" }
Fk:loadTranslationTable{
  ["olmou__dongzhuo"] = "谋董卓",
  ["#olmou__dongzhuo"] = "翦覆四海",
  --["illustrator:olmou__dongzhuo"] = "",

  ["$ty_ex__fencheng_olmou__dongzhuo"] = "焚城为焰，炙脍犒三军！",
  ["~olmou__dongzhuo"] = "关东鼠辈，怎敢忤逆天命！",
}

--施仁布德：孔融
General:new(extension, "olmou__kongrong", "qun", 4):addSkills { "liwen", "ol__zhengyi" }
Fk:loadTranslationTable{
  ["olmou__kongrong"] = "谋孔融",
  ["#olmou__kongrong"] = "豪气贯长虹",
  ["illustrator:olmou__kongrong"] = "alien",

  ["~olmou__kongrong"] = "为父将去，子何以不辞？",
}

--奋勇扬威：太史慈 孙坚 袁绍 华雄 文丑 张绣
General:new(extension, "olmou__taishici", "wu", 4):addSkills { "ol__dulie", "douchan" }
Fk:loadTranslationTable{
  ["olmou__taishici"] = "谋太史慈",
  ["#olmou__taishici"] = "矢志全忠孝",
  ["illustrator:olmou__taishici"] = "君桓文化",

  ["~olmou__taishici"] = "人生得遇知己，死又何憾……",
}

General:new(extension, "olmou__sunjian", "wu", 4, 5):addSkills { "hulie", "yipo" }
Fk:loadTranslationTable{
  ["olmou__sunjian"] = "谋孙坚",
  ["#olmou__sunjian"] = "乌程侯",
  ["illustrator:olmou__sunjian"] = "黯荧岛",

  ["~olmou__sunjian"] = "江东子弟们，我先走一步了……",
}

General:new(extension, "olmou__yuanshao", "qun", 4):addSkills { "hetao", "shenliy", "yufeng", "shishouy" }
Fk:loadTranslationTable{
  ["olmou__yuanshao"] = "谋袁绍",
  ["#olmou__yuanshao"] = "席卷八荒",
  --["illustrator:olmou__yuanshao"] = "西国红云",

  ["~olmou__yuanshao"] = "众人合而无力，徒负大义也……",
}

General:new(extension, "olmou__huaxiong", "qun", 6):addSkills { "bojue", "yangwei" }
Fk:loadTranslationTable{
  ["olmou__huaxiong"] = "谋华雄",
  ["#olmou__huaxiong"] = "汜水关死神",
  --["illustrator:olmou__huaxiong"] = "",

  ["~olmou__huaxiong"] = "我已连战三场，匹夫胜之不武！",
}

General:new(extension, "olmou__wenchou", "qun", 4):addSkills { "lunzhan", "juejuew" }
Fk:loadTranslationTable{
  ["olmou__wenchou"] = "谋文丑",
  ["#olmou__wenchou"] = "万夫之勇",
  --["illustrator:olmou__wenchou"] = "",

  ["~olmou__wenchou"] = "何人……杀吾兄弟……",
}

General:new(extension, "olmou__zhangxiu", "qun", 4):addSkills { "zhuijiao", "choulie" }
Fk:loadTranslationTable{
  ["olmou__zhangxiu"] = "谋张绣",
  ["#olmou__zhangxiu"] = "枪啸风吟",
  --["illustrator:olmou__zhangxiu"] = "",

  ["~olmou__zhangxiu"] = "文和，可有良计……救我……",
}

--达权通变：袁术
General:new(extension, "olmou__yuanshu", "qun", 4):addSkills { "jinming", "xiaoshi", "yanliangy" }
Fk:loadTranslationTable{
  ["olmou__yuanshu"] = "谋袁术",
  ["#olmou__yuanshu"] = "画脂镂冰",
  --["illustrator:olmou__yuanshu"] = "",

  ["~olmou__yuanshu"] = "谋事在人，奈何成事不在人……",
}

--测试服
General:new(extension, "olmou__dengai", "wei", 4, 5):addSkills { "jigud", "jiewan" }
Fk:loadTranslationTable{
  ["olmou__dengai"] = "谋邓艾",
  ["#olmou__dengai"] = "壮士解腕",
  --["illustrator:olmou__dengai"] = "",

  --["~olmou__dengai"] = "",
}

General:new(extension, "olmou__gongsunzan", "qun", 4):addSkills { "jiaodi", "baojing" }
Fk:loadTranslationTable{
  ["olmou__gongsunzan"] = "谋公孙瓒",
  ["#olmou__gongsunzan"] = "辽海龙吟",
  ["illustrator:olmou__gongsunzan"] = "西国红云",

  --["~olmou__gongsunzan"] = "",
}

General:new(extension, "olmou__huangyueying", "shu", 3, 3, General.Female):addSkills { "bingcai", "lixian" }
Fk:loadTranslationTable{
  ["olmou__huangyueying"] = "谋黄月英",
  ["#olmou__huangyueying"] = "才惠双绝",
  --["illustrator:olmou__huangyueying"] = "",

  --["~olmou__huangyueying"] = "",
}

General:new(extension, "olmou__jvshou", "qun", 3):addSkills { "guliang", "xutu" }
Fk:loadTranslationTable{
  ["olmou__jvshou"] = "谋沮授",
  ["#olmou__jvshou"] = "三军监统",
  --["illustrator:olmou__jvshou"] = "",

  --["~olmou__jvshou"] = "",
}

General:new(extension, "olmou__zhangfei", "shu", 4):addSkills { "jingxian", "xiayong" }
Fk:loadTranslationTable{
  ["olmou__zhangfei"] = "谋张飞",
  ["#olmou__zhangfei"] = "虎烈匡国",
  --["illustrator:olmou__zhangfei"] = "",

  --["~olmou__zhangfei"] = "",
}

General:new(extension, "olmou__zhaoyun", "shu", 4):addSkills { "nilan", "jueya" }
Fk:loadTranslationTable{
  ["olmou__zhaoyun"] = "谋赵云",
  ["#olmou__zhaoyun"] = "白首之心",
  --["illustrator:olmou__zhaoyun"] = "",

  --["~olmou__zhaoyun"] = "",
}

General:new(extension, "olmou__zhangrang", "qun", 3):addSkills { "lucun", "tuisheng" }
Fk:loadTranslationTable{
  ["olmou__zhangrang"] = "谋张让",
  ["#olmou__zhangrang"] = "侵威乱天常",
  --["illustrator:olmou__zhangrang"] = "",

  --["~olmou__zhangrang"] = "",
}

General:new(extension, "olmou__luzhi", "qun", 4):addSkills { "sibing", "liance" }
Fk:loadTranslationTable{
  ["olmou__luzhi"] = "谋卢植",
  --["#olmou__luzhi"] = "",
  --["illustrator:olmou__luzhi"] = "",

  --["~olmou__luzhi"] = "",
}

return extension
