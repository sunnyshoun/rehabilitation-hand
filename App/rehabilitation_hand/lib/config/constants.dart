class AppConstants {
  // 動作相關
  static const int defaultHoldDuration = 1;
  static const int defaultMotionDuration = 2;
  static const int maxDurationSeconds = 10;

  // 動畫時間
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 1);
  static const Duration overlayAnimationDuration = Duration(milliseconds: 200);
  static const Duration themeTransitionDuration = Duration(milliseconds: 200);

  // 藍牙相關
  static const Duration bluetoothConnectionDelay = Duration(milliseconds: 500);
  static const Duration bluetoothEnableDelay = Duration(seconds: 2);

  // UI 尺寸
  static const double cardElevation = 2.0;
  static const double highlightedCardElevation = 12.0;
  static const double borderRadius = 8.0;
  static const double largerBorderRadius = 12.0;
  static const double buttonBorderRadius = 20.0;

  // Grid 配置
  static const int gridCrossAxisCount = 2;
  static const int tabletGridCrossAxisCount = 3;
  static const double gridAspectRatio = 2.5;
  static const double gridSpacing = 10.0;

  // 響應式設計斷點
  static const double tabletBreakpoint = 600.0;
  static const double compactHeightBreakpoint = 600.0;

  // SharedPreferences keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';
  static const String lastDeviceKey = 'last_device';
  static const String customTemplatesKey = 'custom_motion_templates';
  static const String defaultTemplatesOrderKey = 'default_templates_order';
  static const String playlistsKey = 'motion_playlists';
  static const String themeModeKey = 'theme_mode';
}

class AppStrings {
  // 應用程式名稱
  static const String appTitle = '復健手控制系統';

  // 手指名稱
  static const List<String> fingerNames = ['拇指', '食指', '中指', '無名指', '小指'];

  // 動作狀態
  static const String extendedState = '伸展';
  static const String relaxedState = '放鬆';
  static const String contractedState = '收緊';

  // 預設動作名稱
  static const String fistMotion = '握拳';
  static const String openMotion = '張開';
  static const String relaxMotion = '放鬆';
  static const String okGesture = 'OK手勢';

  // 主題相關
  static const String systemTheme = '根據系統';
  static const String lightTheme = '亮色模式';
  static const String darkTheme = '深色模式';

  // 錯誤訊息
  static const String loginFailed = '登入失敗，請檢查帳號密碼';
  static const String bluetoothNotConnected = '請先連接藍牙設備';
  static const String bluetoothPermissionDenied = '需要藍牙權限才能連接設備';
  static const String nameAlreadyExists = '此名稱已存在';
  static const String emptyPlaylistWarning = '動作列表為空，無法儲存';

  // 按鈕文字
  static const String save = '儲存';
  static const String update = '更新';
  static const String cancel = '取消';
  static const String delete = '刪除';
  static const String confirm = '確認';
  static const String play = '播放';
  static const String stop = '停止';
  static const String pause = '暫停';
  static const String resume = '繼續';
  static const String reset = '重置';
  static const String done = '完成';
  static const String settings = '設定';
}
