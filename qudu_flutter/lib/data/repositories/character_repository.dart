// 汉字识字 Repository
// 对应后端 API：GET /characters（列表）、GET /characters/:id（详情）
// 当前阶段：本地 Mock 数据 + 等后端 API 就绪后切换真实接口
import '../models/character_model.dart';

/// 汉字 Repository — 提供本地缓存 + API 双模式
/// TODO：后端 API 就绪后接入真实接口
class CharacterRepository {
  /// 获取某级别的汉字列表
  /// [level] 1-5，对应 L1-L5
  /// [childId] 可选，传入后返回该儿童的掌握进度
  Future<List<CharacterModel>> getCharactersByLevel(
    int level, {
    String? childId,
  }) async {
    // Mock 模式：返回本地模拟数据
    // TODO: 接入后端 API
    // final resp = await _api.get('/characters', queryParams: {
    //   'level': level.toString(),
    //   if (childId != null) 'childId': childId,
    // });
    // return (resp.data['list'] as List)
    //     .map((e) => CharacterModel.fromJson(e))
    //     .toList();

    return _mockCharacters(level);
  }

  /// 获取汉字详情（含例句、字源）
  Future<CharacterModel?> getCharacterDetail(String id) async {
    // TODO: 接入后端 API
    // final resp = await _api.get('/characters/$id');
    // return CharacterModel.fromJson(resp.data);

    return null;
  }

  /// 获取儿童的待复习汉字列表（遗忘曲线驱动）
  /// [childId] 儿童ID
  /// 返回今日需要复习的汉字
  Future<List<CharacterModel>> getReviewQueue(String childId) async {
    // TODO: 接入后端 API — learning/stats 接口的 dueReview 字段
    // final resp = await _api.get('/learning/stats/$childId');
    // final dueCount = resp.data['mastery']['dueReview'] as int? ?? 0;
    // return getCharactersByLevel(1, childId: childId)
    //     .then((chars) => chars.where((c) => c.needsReview).take(dueCount).toList());

    return [];
  }

  /// 本地 Mock 数据（L1 首批 20 个核心字作为演示）
  List<CharacterModel> _mockCharacters(int level) {
    // L1 核心字演示数据（简化版，实际由 seed.js 导入）
    final mockData = [
      _mockChar('1', '一', 'yī', '一', 1, '独体', 'core', 1, ['一个', '一下', '第一', '一直', '一天']),
      _mockChar('2', '二', 'èr', '二', 2, '独体', 'core', 1, ['二月', '二十', '第二', '二月天']),
      _mockChar('3', '三', 'sān', '一', 3, '独体', 'core', 1, ['三个', '三月', '三十', '三好生']),
      _mockChar('4', '上', 'shàng', '一', 3, '上下', 'core', 1, ['上学', '上午', '上面', '上班']),
      _mockChar('5', '下', 'xià', '一', 3, '上下', 'core', 1, ['下雨', '下午', '下面', '下班']),
      _mockChar('6', '大', 'dà', '大', 3, '独体', 'core', 1, ['大人', '大家', '大小', '大学', '大米']),
      _mockChar('7', '小', 'xiǎo', '小', 3, '独体', 'core', 1, ['小孩', '小心', '大小', '小米', '小鱼']),
      _mockChar('8', '人', 'rén', '人', 2, '独体', 'core', 1, ['大人', '人们', '人生', '人品', '中国人']),
      _mockChar('9', '日', 'rì', '日', 4, '独体', 'core', 1, ['生日', '今日', '日出', '日历', '日本']),
      _mockChar('10', '月', 'yuè', '月', 4, '独体', 'core', 1, ['月亮', '月光', '一月', '月饼', '明月']),
      _mockChar('11', '水', 'shuǐ', '水', 4, '独体', 'core', 1, ['水果', '喝水', '河水', '水滴', '开水']),
      _mockChar('12', '火', 'huǒ', '火', 4, '独体', 'core', 1, ['火车', '大火', '火山', '着火', '生气火']),
      _mockChar('13', '山', 'shān', '山', 3, '独体', 'core', 1, ['高山', '山上', '山水', '小山', '山高']),
      _mockChar('14', '口', 'kǒu', '口', 3, '独体', 'core', 1, ['口水', '入口', '门口', '出口', '人口']),
      _mockChar('15', '目', 'mù', '目', 5, '独体', 'core', 1, ['目光', '眼目', '目的', '耳目一新']),
      _mockChar('16', '手', 'shǒu', '手', 4, '独体', 'core', 1, ['左手', '右手', '手机', '握手', '大手']),
      _mockChar('17', '足', 'zú', '足', 7, '上下', 'extended', 1, ['足球', '手足', '远足', '满足', '知足']),
      _mockChar('18', '走', 'zǒu', '走', 7, '半包围', 'core', 1, ['走路', '行走', '走开', '小走', '走动']),
      _mockChar('19', '好', 'hǎo', '女', 6, '左右', 'core', 1, ['好人', '你好', '很好', '美好', '好朋友']),
      _mockChar('20', '我', 'wǒ', '戈', 7, '独体', 'core', 1, ['我们', '我的', '自我', '我爱你', '我自己']),
    ];

    return mockData;
  }

  CharacterModel _mockChar(
    String id,
    String char,
    String pinyin,
    String radical,
    int strokes,
    String structure,
    String coreLevel,
    int level,
    List<String> words,
  ) {
    return CharacterModel(
      id: id,
      character: char,
      pinyin: pinyin,
      radical: radical,
      strokeCount: strokes,
      structure: structure,
      coreLevel: coreLevel,
      level: level,
      words: words,
      sentences: [],
      mastery: 0.0,
    );
  }
}
