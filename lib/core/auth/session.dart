import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'token_store.dart';

/// 当前登录用户档案（字段与后端 profiles 表一致）
class Profile {
  const Profile({
    required this.id,
    required this.realName,
    required this.className,
    required this.nickname,
    this.gender,
    this.avatarUrl,
    required this.displayMode,
    required this.commentAnonymous,
    this.email,
    required this.role,
  });

  final String id;
  final String realName;
  final String className;
  final String nickname;
  final String? gender;
  final String? avatarUrl;

  /// nickname_only=仅昵称 / nickname_real=真实姓名+班级
  final String displayMode;
  final bool commentAnonymous;
  final String? email;
  final String role;

  bool get isAdmin => role == 'admin';

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        realName: j['real_name'] as String? ?? '',
        className: j['class_name'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        gender: j['gender'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        displayMode: j['display_mode'] as String? ?? 'nickname_real',
        commentAnonymous: j['comment_anonymous'] as bool? ?? true,
        email: j['email'] as String?,
        role: j['role'] as String? ?? 'user',
      );
}

/// 会话状态：unknown=启动恢复中 / guest=未登录 / authed=已登录
sealed class SessionState {
  const SessionState();
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionGuest extends SessionState {
  const SessionGuest();
}

class SessionAuthed extends SessionState {
  const SessionAuthed(this.profile);
  final Profile profile;
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    await TokenStore.instance.load();
    if (TokenStore.instance.accessToken == null) return const SessionGuest();
    // 有本地令牌：尝试拉取档案，失败则尝试刷新后重试
    final profile = await _fetchProfile();
    if (profile != null) return SessionAuthed(profile);
    return const SessionGuest();
  }

  Future<Profile?> _fetchProfile() async {
    try {
      final resp = await ApiClient.instance.dio.get('/api/profile');
      final data = resp.data;
      if (data is Map && data['profile'] is Map) {
        return Profile.fromJson(
            Map<String, dynamic>.from(data['profile'] as Map));
      }
    } catch (_) {}
    return null;
  }

  /// 姓名 + 密码登录（班级由后端自动匹配，与网页版一致）
  Future<String?> login({
    required String realName,
    required String password,
  }) async {
    try {
      final resp = await ApiClient.instance.dio.post(
        '/api/auth/login',
        data: {'real_name': realName.trim(), 'password': password},
      );
      final data = resp.data;
      if (data is Map && data['ok'] == true) {
        await TokenStore.instance.save(
          access: data['access_token'] as String,
          refresh: data['refresh_token'] as String,
        );
        final profile = await _fetchProfile();
        if (profile != null) {
          state = AsyncData(SessionAuthed(profile));
          return null;
        }
        await TokenStore.instance.clear();
        return '登录后获取资料失败，请重试';
      }
      return '登录失败，请重试';
    } catch (e) {
      return ApiClient.errorMessage(e, fallback: '登录失败，请检查网络');
    }
  }

  /// 退出登录：通知后端注销会话 + 清空本地令牌
  Future<void> logout() async {
    try {
      await ApiClient.instance.dio.post('/api/auth/logout');
    } catch (_) {}
    await TokenStore.instance.clear();
    state = const AsyncData(SessionGuest());
  }

  /// 刷新档案（修改资料/隐私设置后调用）
  Future<void> reloadProfile() async {
    final profile = await _fetchProfile();
    if (profile != null) state = AsyncData(SessionAuthed(profile));
  }
}
