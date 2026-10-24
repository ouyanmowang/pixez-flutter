import 'dart:io';

import 'package:pixez/main.dart';
import 'package:pixez/saf_plugin.dart';

/// 小说保存位置管理：
/// - 未设置自定义目录时，写入公共下载目录 Download/PixEz/
/// - 设置后写入用户通过系统目录选择器选定的目录（SAF tree uri，权限持久化）
class NovelSaveTarget {
  static const String TREE_URI_KEY = "novel_save_tree_uri";
  static const String TREE_DISPLAY_KEY = "novel_save_tree_display";
  static const String DEFAULT_DISPLAY = "Download/PixEz";

  static String? get treeUri => userSetting.prefs.getString(TREE_URI_KEY);

  static String? get treeDisplay =>
      userSetting.prefs.getString(TREE_DISPLAY_KEY);

  static bool get isCustom => (treeUri ?? '').isNotEmpty;

  /// 界面上展示的当前保存目录
  static String get display =>
      isCustom ? (treeDisplay ?? "自定义目录") : DEFAULT_DISPLAY;

  /// 打开系统目录选择器并记住选择；返回是否选择成功
  static Future<bool> pick() async {
    if (!Platform.isAndroid) return false;
    final result = await SAFPlugin.pickSaveDir();
    if (result == null) return false;
    final uri = result['uri'] ?? '';
    if (uri.isEmpty) return false;
    await userSetting.prefs.setString(TREE_URI_KEY, uri);
    await userSetting.prefs.setString(
      TREE_DISPLAY_KEY,
      (result['display'] ?? '').isEmpty ? "自定义目录" : result['display']!,
    );
    return true;
  }

  /// 恢复默认保存位置（Download/PixEz）
  static Future<void> reset() async {
    await userSetting.prefs.remove(TREE_URI_KEY);
    await userSetting.prefs.remove(TREE_DISPLAY_KEY);
  }

  /// 保存文本文件：优先自定义目录，未设置或失败时回退到 Download/PixEz。
  /// [subDir] 非空时收纳到该子目录，用于整系列下载归档。
  /// 返回用于提示的可读路径，全部失败返回 null。
  static Future<String?> save(
    String name,
    String mimeType,
    String text, {
    String? subDir,
  }) async {
    if (!Platform.isAndroid) return null;
    final sub = (subDir ?? '').trim();
    final uri = treeUri;
    if (uri != null && uri.isNotEmpty) {
      final saved = await SAFPlugin.saveToTree(
        uri,
        name,
        mimeType,
        text,
        subDir: sub.isEmpty ? null : sub,
      );
      if (saved != null && saved.isNotEmpty) return saved;
    }
    return SAFPlugin.saveToDownloads(
      name,
      mimeType,
      text,
      relativePath: sub.isEmpty ? 'PixEz' : 'PixEz/$sub',
    );
  }
}
