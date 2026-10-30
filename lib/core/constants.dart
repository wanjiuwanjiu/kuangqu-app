/// 全局常量
class AppConstants {
  AppConstants._();

  /// 后端 API 地址（与网页版同一后端，数据双向同步）
  static const String apiBaseUrl = 'https://kuangzhong.asia';

  /// 帖子分类（与网页版一致）
  static const List<String> categories = [
    '全部',
    '表白',
    '求助',
    '吐槽',
    '失物招领',
    '校园通知',
  ];

  /// 举报原因（与网页版一致）
  static const List<String> reportReasons = [
    '辱骂引战',
    '色情低俗',
    '广告',
    '其他违规',
  ];

  /// 帖子内容最大长度（与后端一致）
  static const int postMaxLength = 500;

  /// 帖子图片最大数量（与后端一致）
  static const int postMaxImages = 3;

  /// 年级段与班级（两级选择器）
  static const Map<String, List<String>> grades = {
    '高一': ['高一（1）班', '高一（2）班', '高一（3）班', '高一（4）班', '高一（5）班', '高一（6）班', '高一（7）班', '高一（8）班'],
    '高二': ['高二（1）班', '高二（2）班', '高二（3）班', '高二（4）班', '高二（5）班', '高二（6）班', '高二（7）班', '高二（8）班'],
    '高三': ['高三（1）班', '高三（2）班', '高三（3）班', '高三（4）班', '高三（5）班', '高三（6）班', '高三（7）班', '高三（8）班'],
  };
}
