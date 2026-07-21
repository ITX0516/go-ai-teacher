/// 应用版本信息
/// 规则：每次打包版本号 +0.0.01（十进制递增）
/// 示例：1.0.00 → 1.0.01 → ... → 1.0.09 → 1.0.10 → 1.0.11
class AppInfo {
  /// 当前分支
  static const String branch = 'master';

  /// 主版本.次版本.补丁号（补丁号十进制递增）
  static const String version = '1.0.03';

  /// 完整版本标识：分支+版本号
  static String get fullVersion => '$branch$version';
}
