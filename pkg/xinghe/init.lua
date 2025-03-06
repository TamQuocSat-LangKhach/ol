local extension = Package:new("ol_xinghe")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/xinghe/skills")

Fk:loadTranslationTable{
  ["ol_xinghe"] = "OL-璀璨星河",
}

--天极：刘协x 曹昂x 何太后√ 孙鲁育√ 孙皓 王荣 左棻 刘琦 曹嵩x 卞夫人 刘辩x 清河公主 滕芳兰 芮姬 唐姬x 刘宏x 杜夫人x 曹宇 曹腾√ 刘焉x 秦朗√ 袁姬√
General:new(extension, "ol__hetaihou", "qun", 3, 3, General.Female):addSkills { "ol__zhendu", "ol__qiluan" }
Fk:loadTranslationTable{
  ["ol__hetaihou"] = "何太后",
  ["#ol__hetaihou"] = "弄权之蛇蝎",
  ["illustrator:ol__hetaihou"] = "DH",

  ["~ol__hetaihou"] = "扰乱朝堂之事，我怎么会做……",
}

local sunluyu = General:new(extension, "ol__sunluyu", "wu", 3, 3, General.Female)
sunluyu:addSkills { "ol__meibu", "ol__mumu" }
sunluyu:addRelatedSkill("ol__zhixi")
Fk:loadTranslationTable{
  ["ol__sunluyu"] = "孙鲁育",
  ["#ol__sunluyu"] = "舍身饲虎",
  ["illustrator:ol__sunluyu"] = "玉生贝利",

  ["~ol__sunluyu"] = "姐妹之间，何必至此？",
}




local caoteng = General:new(extension, "caoteng", "qun", 3)
caoteng:addSkills { "yongzu", "qingliu" }
caoteng:addRelatedSkills { "ex__jianxiong", "tianming" }
Fk:loadTranslationTable{
  ["caoteng"] = "曹腾",
  ["#caoteng"] = "魏高帝",
  ["illustrator:caoteng"] = "君桓文化",

  ["$ex__jianxiong_caoteng"] = "躬行禁闱，不敢争一时之气。",
  ["$tianming_caoteng"] = "天命在彼，事莫强为。",
  ["~caoteng"] = "种暠害我，望陛下明鉴！",
}

General:new(extension, "ol__qinlang", "wei", 3):addSkills { "xianying" }
Fk:loadTranslationTable{
  ["ol__qinlang"] = "秦朗",
  ["#ol__qinlang"] = "跼高蹐厚",

  ["~ol__qinlang"] = "我秦姓人，非属高门。",
}

General:new(extension, "ol__yuanji", "wu", 3, 3, General.Female):addSkills { "jieyan", "jinghua", "shuiyue" }
Fk:loadTranslationTable{
  ["ol__yuanji"] = "袁姬",
  ["#ol__yuanji"] = "日星隐曜",
  ["cv:ol__yuanji"] = "AI",

  ["~ol__yuanji"] = "空捧冰心抱玉壶……",
}

--四弼：伏完x 杨修x 陈琳x 诸葛瑾√ 马良 程昱 士燮 邓芝 董昭 司马朗x 步骘 董允 阚泽 王允 戏志才 孙乾 王粲x 吕虔x 孙邵 辛毗x 审配 荀谌 吕凯x 蒋干x
--潘濬x 严峻x 杜袭 杨仪 陈登 羊祜 伊籍 夏侯玄 马日磾x 屈晃 孙弘 谯周x 阎圃x 张华 曹羲 王瓘 陆凯 田畴 郭图 陶谦√ 韩馥√
General:new(extension, "ol__zhugejin", "wu", 3):addSkills { "huanshi", "ol__hongyuan", "ol__mingzhe" }
Fk:loadTranslationTable{
  ["ol__zhugejin"] = "诸葛瑾",
  ["#ol__zhugejin"] = "联盟的维系者",
  ["designer:ol__zhugejin"] = "玄蝶既白",
  ["illustrator:ol__zhugejin"] = "G.G.G.",

  ["$huanshi_ol__zhugejin1"] = "不因困顿夷初志，肯为联蜀改阵营。",
  ["$huanshi_ol__zhugejin2"] = "合纵连横，只为天下苍生。",
  ["~ol__zhugejin"] = "联盟若能得以维系，吾……无他愿矣……",
}



General:new(extension, "ol__taoqian", "qun", 3):addSkills { "zongluan", "ol__zhaohuo", "wenren" }
Fk:loadTranslationTable{
  ["ol__taoqian"] = "陶谦",
  ["#ol__taoqian"] = "恭谦忍顺",

  ["~ol__taoqian"] = "玄德……徐州就交给你了……",
}

General:new(extension, "ol__hanfu", "qun", 4):addSkills { "shuzi", "kuangshou" }
Fk:loadTranslationTable{
  ["ol__hanfu"] = "韩馥",
  ["#ol__hanfu"] = "挈瓶之知",

  ["~ol__hanfu"] = "本初，我可是请你吃过饭的！",
}

--天柱：潘凤x 诸葛诞√ 兀突骨 蹋顿 严白虎 李傕x 张济x 樊稠 郭汜x 沙摩柯x 丁原x 黄祖 高干 王双x 范疆张达 梁兴x 阿会喃 马玩 文钦 雅丹 张燕 何进√
--牛金√ 韩遂√ 李异 刘辟 轲比能√ 吴景x 马元义x
local zhugedan = General:new(extension, "ol__zhugedan", "wei", 4)
zhugedan:addSkills { "gongao", "ol__juyi" }
zhugedan:addRelatedSkills { "benghuai", "ol__weizhong" }
Fk:loadTranslationTable{
  ["ol__zhugedan"] = "诸葛诞",
  ["#ol__zhugedan"] = "薤露蒿里",
  ["illustrator:ol__zhugedan"] = "君桓文化",

  ["$gongao_ol__zhugedan1"] = "大魏獒犬，恪忠于国。",
  ["$gongao_ol__zhugedan2"] = "斯人已逝，余者奋威。",
  ["$benghuai_ol__zhugedan"] = "诞，能得诸位死力，无憾矣。",
  ["~ol__zhugedan"] = "成功！成仁！",
}




General:new(extension, "ol__hejin", "qun", 4):addSkills { "ol__mouzhu", "ol__yanhuo" }
Fk:loadTranslationTable{
  ["ol__hejin"] = "何进",
  ["#ol__hejin"] = "色厉内荏",
  ["cv:ol__hejin"] = "冷泉月夜",
  ["illustrator:ol__hejin"] = "鬼画府",

  ["~ol__hejin"] = "阉人造反啦！护卫！呀——",
}

General:new(extension, "ol__niujin", "wei", 4):addSkills { "ol__cuorui", "ol__liewei" }
Fk:loadTranslationTable{
  ["ol__niujin"] = "牛金",
  ["#ol__niujin"] = "独进的兵胆",
  ["illustrator:ol__niujin"] = "凡果_棉鞋",

  ["~ol__niujin"] = "司马氏负我！",
}

General:new(extension, "ol__hansui", "qun", 4):addSkills { "ol__niluan", "ol__xiaoxi" }
Fk:loadTranslationTable{
  ["ol__hansui"] = "韩遂",
  ["#ol__hansui"] = "雄踞北疆",
  ["illustrator:ol__hansui"] = "Thinking",

  ["~ol__hansui"] = "英雄一世，奈何祸起萧墙……",
}





General:new(extension, "ol__kebineng", "qun", 4):addSkills { "pingduan" }
Fk:loadTranslationTable{
  ["ol__kebineng"] = "轲比能",
  ["#ol__kebineng"] = "瀚海鲸波",
  ["illustrator:ol__kebineng"] = "黯荧岛",
  ["designer:ol__kebineng"] = "cyc",

  ["~ol__kebineng"] = "未驱青马饮于黄河，死难瞑目。",
}

--女史：灵雎√ 关银屏√ 大乔小乔x 张星彩x 马云騄 董白 赵襄 花鬘x 张昌蒲x 杨婉x 郭槐 陆郁生 丁尚涴 李婉 胡金定 孙茹√ 董翓√ 阮慧x
General:new(extension, "ol__lingju", "qun", 3, 3, General.Female):addSkills { "ol__jieyuan", "ol__fenxin" }
Fk:loadTranslationTable{
  ["ol__lingju"] = "灵雎",
  ["#ol__lingju"] = "情随梦逝",
  ["illustrator:ol__lingju"] = "疾速k",

  ["~ol__lingju"] = "情随梦境散，花随时节落。",
}

General:new(extension, "ol__guanyinping", "shu", 3, 3, General.Female):addSkills { "ol__xuehen", "ol__huxiao", "ol__wuji" }
Fk:loadTranslationTable{
  ["ol__guanyinping"] = "关银屏",
  ["#ol__guanyinping"] = "武姬",
  ["designer:ol__guanyinping"] = "千幻",
  ["illustrator:ol__guanyinping"] = "光域鹿鸣",

  ["~ol__guanyinping"] = "红已花残，此仇未能报……",
}





General:new(extension, "ol__sunru", "wu", 3, 3, General.Female):addSkills { "chishi", "weimian" }
Fk:loadTranslationTable{
  ["ol__sunru"] = "孙茹",
  ["#ol__sunru"] = "淑慎温良",
  ["illustrator:ol__sunru"] = "土豆",

  ["~ol__sunru"] = "从来无情者，皆出帝王家……",
}

General:new(extension, "ol__dongxie", "qun", 3, 5, General.Female):addSkills { "jiaoweid", "bianyu", "fengyao" }
Fk:loadTranslationTable{
  ["ol__dongxie"] = "董翓",
  ["#ol__dongxie"] = "魔女",

  ["~ol__dongxie"] = "牛家哥哥，我来……与你黄泉作伴……",
}

--少微：张宝 张鲁 诸葛果 卑弥呼x 司马徽x 许靖 张陵 黄承彦 张芝 卢氏 彭羕


--虎贲：公孙瓒x 曹洪x 夏侯霸x 诸葛恪√ 乐进x 祖茂x 丁奉√ 文聘x 吾彦 李通 贺齐 马忠 麹义 鲁芝 苏飞 黄权 唐咨 吕旷吕翔 高览 周鲂x 曹性x 朱灵x 田豫
--赵俨 邓忠 霍峻 文鸯x 阎柔x 朱儁 马承 傅肜 胡班 马休马铁 张翼 罗宪 郝普 孟达 段熲 牵招 凌操√ 刘磐 蔡瑁 王匡√ 成公英√
General:new(extension, "zhugeke", "wu", 3):addSkills { "aocai", "duwu" }
Fk:loadTranslationTable{
  ["zhugeke"] = "诸葛恪",
  ["#zhugeke"] = "兴家赤族",
  ["designer:zhugeke"] = "韩旭",
  ["illustrator:zhugeke"] = "LiuHeng",

  ["~zhugeke"] = "重权震主，是我疏忽了……",
}

General:new(extension, "ol__dingfeng", "wu", 4):addSkills { "ol__duanbing", "ol__fenxun" }
Fk:loadTranslationTable{
  ["ol__dingfeng"] = "丁奉",
  ["#ol__dingfeng"] = "清侧重臣",
  ["illustrator:ol__dingfeng"] = "枭瞳",

  ["~ol__dingfeng"] = "命乎！命乎……",
}



General:new(extension, "ol__lingcao", "wu", 4):addSkills { "ol__dujin" }
Fk:loadTranslationTable{
  ["ol__lingcao"] = "凌操",
  ["#ol__lingcao"] = "激流勇进",
  ["illustrator:ol__lingcao"] = "美有",

  ["~ol__lingcao"] = "不好，此处有埋伏……",
}






General:new(extension, "wangkuang", "qun", 4):addSkills { "renxia" }
Fk:loadTranslationTable{
  ["wangkuang"] = "王匡",
  ["#wangkuang"] = "任侠纵横",
  ["illustrator:wangkuang"] = "花狐貂",
  ["designer:wangkuang"] = "U",

  ["~wangkuang"] = "人心不古，世态炎凉。",
}

General:new(extension, "chenggongying", "qun", 4):addSkills { "kuangxiang" }
Fk:loadTranslationTable{
  ["chenggongying"] = "成公英",
  ["#chenggongying"] = "尽欢竭忠",

  ["~chenggongying"] = "假使英本主人在，实不来此也。",
}

--列肆：糜竺 卫兹 刘巴 张世平 吕伯奢


return extension
