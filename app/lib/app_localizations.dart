import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリの表示言語(日本語/英語)を管理するクラス。
///
/// 注記: Flutter標準の本格的な国際化(flutter_localizations + ARBファイル +
/// コード生成)ではなく、シンプルな辞書引き方式にしている。
/// 理由: ビルドの仕組みを複雑にせず、既存の全画面に少しずつ
/// 翻訳を広げていけるようにするため。
class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final AppLanguage instance = AppLanguage._();

  static const _prefsKey = 'app_language';

  String _code = 'ja'; // 'ja' または 'en'
  String get code => _code;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_prefsKey) ?? 'ja';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_code == code) return;
    _code = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}

const Map<String, Map<String, String>> _translations = {
  'ja': {
    // --- ログイン画面 ---
    'app_title': 'すわほ',
    'login_google': 'Googleでログイン',
    'login_apple': 'Appleでログイン',
    'or_divider': 'または',
    'label_name': 'お名前',
    'label_email': 'メールアドレス',
    'label_password': 'パスワード',
    'button_login': 'ログイン',
    'button_register': '新規登録',
    'switch_to_register': 'はじめての方はこちら(新規登録)',
    'switch_to_login': 'すでにアカウントをお持ちの方はこちら',
    'forgot_password': 'パスワードをお忘れですか?',
    'guest_login': 'ゲストとして利用する(フレンド機能は使えません)',
    'guest_blocked_title': 'ゲストはご利用いただけません',
    'guest_blocked_body': 'フレンド機能(誰がどこに座っているかを把握する機能)は、アカウントを作成した方のみ利用できます。',
    'close': '閉じる',
    'forgot_password_title': 'パスワードを再設定',
    'forgot_password_desc': '登録済みのメールアドレスを入力してください。\n再設定用のリンクを記載したメールをお送りします。',
    'cancel': 'キャンセル',
    'send': '送信',

    // --- ホーム画面 ---
    'search_campus_hint': 'キャンパスを検索',
    'select_campus_title': 'キャンパスを選択してください',
    'nav_home': 'ホーム',
    'nav_friend': 'フレンド',
    'nav_qr': 'QRコード',
    'no_campus_found': '見つかりませんでした',

    // --- ドロワー ---
    'drawer_floor_select': 'フロア選択',
    'drawer_how_to_use': '使い方',
    'drawer_profile': 'プロフィール',
    'drawer_about': 'アプリについて',
    'drawer_feedback': 'フィードバック',
    'drawer_terms': '利用規約・プライバシーポリシー',
    'drawer_settings': '設定',
    'drawer_logout': 'ログアウト',
    'logout_confirm_title': 'ログアウトしますか?',

    // --- 座席詳細 ---
    'seat_shared_space': '共有スペース',
    'seat_individual_space': '個別ワークスペース',
    'seat_status_label': '利用状態',
    'seat_status_occupied': '使用中 🔴',
    'seat_status_vacant': '空席 🟢',
    'seat_capacity_label': '座れる人数',
    'seat_capacity_unit': '人',
    'seat_power_label': '電源 (コンセント)',
    'seat_power_yes': 'あり 🔌',
    'seat_power_no': 'なし ✕',
    'seat_amenities_label': '主なアメニティ',
    'seat_amenities_none': '特になし',

    // --- 災害用モード ---
    'disaster_toggle_tooltip': '災害用モード切替',
    'disaster_banner': '災害用モード:オレンジ色の座席がかまどベンチです',
    'kamado_usage_heading': 'A. かまどを使用する',
    'kamado_storage_heading': 'B. ユニットベンチを収納する(使用後)',
    'kamado_caution_heading': '使用上の注意',
    'kamado_1_title': 'かまどベンチ 1',
    'kamado_2_title': 'かまどベンチ 2',
    'kamado_usage_1': '安全のため、作業は必ず2人以上でおこなってください。専用レンチを準備します。',
    'kamado_usage_2': '専用レンチでビスをゆるめ、上部のユニットベンチ(座面)を取り外します。',
    'kamado_usage_3': 'ユニットベンチの補助脚を引き出します。',
    'kamado_usage_4': '内部の風防・炭置きパネルを確認し、風防はSフックでグリルに掛け、炭置きはグリルの下にセットします。',
    'kamado_usage_5': '炭置きの上に炭をセットして着火し、グリルの上に鍋・やかんを置いて調理します(設置場所が砂・土でない場合はレンガ等を敷いてから加熱してください)。',
    'kamado_storage_1': 'グリルの上に風防・炭置きパネルを重ねて収納し、その上にSフックを置きます。',
    'kamado_storage_2': 'ユニットベンチ(座面)は補助脚を折りたたんでから、脚を本体にセットします(脚をグリルの隙間に通してください)。',
    'kamado_storage_3': 'ユニットベンチと本体を専用レンチ・ビスで固定して完成です。',
    'kamado_caution_1': '加熱時は引火の恐れが無いように、製品の周りに十分なスペースを確保してください。',
    'kamado_caution_2': '設置場所が砂・土でない場合は、レンガ等を敷いた上で加熱をおこなってください。',
    'kamado_caution_3': '加熱後すぐに水をかけると製品が破損する恐れがあります。製品の温度が十分に下がってから清掃してください。',
    'kamado_caution_4': '消火後も製品はしばらく高温です。温度が下がるまで近づいたり、手を触れたりしないでください。',
    // --- フロアマップ設備ラベル ---
    'facility_stairs': '階段',
    'facility_reception': '受付カウンター',
    'facility_entrance': '出入口',
    'facility_entrance_small': '入口',
    'facility_sofa_corner': 'ソファコーナー',
    'facility_support_counter': '支援\nカウンター',
    'facility_search_terminal': '検索端末',
    'facility_lending_machine': '自動貸出\n返却機',
    'facility_storage': '倉庫',
    'facility_media_desk': 'メディア\nデーク',

    // --- チェックイン画面 ---
    'checkin_title': '座席にチェックイン',
    'checkin_scan_qr': 'QRコードをスキャン',
    'checkin_manual_entry': '座席番号を直接入力する',
    'checkin_manual_dialog_title': '座席番号を入力',
    'checkin_manual_hint': '例: seat_01',
    'checkin_button': 'チェックイン',
    'checkin_scan_hint': '座席のQRコードを枠内に合わせてください',
    'checkin_success': 'にチェックインしました',
    'checkin_fail': 'チェックインに失敗しました',
    'checkin_join_title': 'この座席は利用中です',
    'checkin_join_body_prefix': '現在「',
    'checkin_join_body_suffix': '」さんが利用しています。\n一緒にチェックインしますか?',
    'not_qr_seat': '座席用のQRコードではないようです',

    // --- フレンド画面 ---
    'friend_title': 'フレンド',
    'friend_my_qr': '自分のQRコード(相手に読み取ってもらう)',
    'friend_scan_button': 'QRコードを読み取ってフレンド申請',
    'friend_incoming_requests': '届いているフレンド申請',
    'friend_no_requests': '現在届いている申請はありません',
    'friend_request_received': 'フレンド申請が届いています',
    'friend_locations': 'フレンドの現在地',
    'friend_none_yet': 'まだフレンドがいません',
    'friend_seated_at': 'に着席中',
    'friend_not_checked_in': '現在チェックインしていません',
    'friend_scan_hint': 'フレンドのQRコードを読み取ってください',
    'friend_not_add_qr': 'フレンド追加用のQRコードではないようです',
    'friend_request_sent': 'フレンド申請を送りました',
    'friend_request_fail': '申請に失敗しました',

    // --- プロフィール画面 ---
    'profile_title': 'プロフィール',
    'profile_pick_photo': '写真を選択',
    'profile_remove_photo': '写真を削除する',
    'profile_name_label': '名前',
    'profile_updated': 'プロフィール写真を更新しました',
    'profile_update_failed': '写真の更新に失敗しました',
    'profile_removed': '写真を削除しました',
    'profile_remove_failed': '削除に失敗しました',

    // --- 写真切り抜き画面 ---
    'crop_title': '写真の位置を調整',
    'crop_confirm': '決定',
    'crop_instructions': 'ピンチで拡大縮小、ドラッグで位置を調整できます',
    'crop_failed': '切り抜きに失敗しました',

    // --- 初回チュートリアル ---
    'onboarding_skip': 'スキップ',
    'onboarding_next': '次へ',
    'onboarding_start': '始める',
    'onboarding_title_1': '座席の空き状況が一目で分かる',
    'onboarding_desc_1': 'キャンパスのフロアマップ上で、どの座席が空いているか\nリアルタイムに確認できます。',
    'onboarding_title_2': 'QRコードでサクッとチェックイン',
    'onboarding_desc_2': 'テーブルのQRコードを読み取るだけで、\n座席にチェックインできます。',
    'onboarding_title_3': 'フレンドの居場所も分かる',
    'onboarding_desc_3': 'フレンドを追加すると、お互いが\n今どの座席にいるかを確認できます。',
    'onboarding_title_4': '災害時にも役立ちます',
    'onboarding_desc_4': '災害用モードでは、かまどベンチの場所や\n使い方をすぐに確認できます。',

    // --- 使い方画面 ---
    'howto_title': '使い方',
    'howto_1_title': '座席の空き状況を確認する',
    'howto_1_step1': 'ホーム画面でキャンパスを選び、フロア(6F/9F)を選択します。',
    'howto_1_step2': '座席をタップすると、詳細(空席/使用中、電源の有無など)が確認できます。',
    'howto_1_step3': '青(空席)・赤(使用中)の色で一目で分かります。',
    'howto_2_title': 'QRコードでチェックインする',
    'howto_2_step1': '下部ナビの「QRコード」をタップします。',
    'howto_2_step2': 'テーブルに設置されたQRコードを読み取ると、その場でチェックインできます。',
    'howto_2_step3': 'QRが読み取れない場合は「座席番号を直接入力する」からでもチェックインできます。',
    'howto_3_title': 'フレンドを追加する',
    'howto_3_step1': '下部ナビの「フレンド」から、自分のQRコードを表示できます。',
    'howto_3_step2': '友達に読み取ってもらう(または友達のQRを読み取る)とフレンド申請が届きます。',
    'howto_3_step3': '申請を承認すると、フレンドが今どの座席にいるかが分かるようになります。',
    'howto_4_title': 'キャンパスをお気に入り登録する',
    'howto_4_step1': 'ホーム画面のキャンパスカード左上の☆をタップすると★になります。',
    'howto_4_step2': 'お気に入りにしたキャンパスは、次にアプリを開いた時に一覧の上位に表示されます。',
    'howto_5_title': '災害用モード',
    'howto_5_step1': 'フロアマップ画面右上の⚠️アイコンで切り替えられます。',
    'howto_5_step2': 'ONにすると、災害時に「かまどベンチ」として使える座席がオレンジ色で表示されます。',
    'howto_5_step3': 'タップすると使い方(組み立て方・注意事項)を確認できます。',

    // --- アプリについて ---
    'about_title': 'アプリについて',
    'about_version_prefix': 'バージョン',
    'about_description': '座席の空き状況をリアルタイムに確認できる、大学構内向けの座席管理アプリです。',
    'about_team_heading': '開発チーム',

    // --- フィードバック ---
    'feedback_title': 'フィードバック',
    'feedback_description': '不具合の報告や「こんな機能が欲しい」というご意見をお寄せください。',
    'feedback_hint': '内容を入力してください',
    'feedback_send': '送信する',
    'feedback_empty_error': '内容を入力してください',
    'feedback_sent': '送信しました。ありがとうございます!',
    'feedback_send_failed': '送信に失敗しました',

    // --- 利用規約 ---
    'terms_title': '利用規約・プライバシーポリシー',
    'terms_intro': '本アプリ「すわほ」は、大学の講義における企業連携プログラムの一環として、'
        '学生チームが開発したものです。以下は簡易的な利用規約・プライバシーポリシーです。',
    'terms_1_title': '1. 収集する情報',
    'terms_1_body': '本アプリでは、以下の情報を取得・保存する場合があります。\n'
        '・ログインに用いるメールアドレス、Google/Appleアカウントの表示名\n'
        '・プロフィール写真(任意で設定した場合のみ)\n'
        '・座席のチェックイン履歴(いつ・どの座席を利用したか)\n'
        '・フレンド関係、およびフレンドに公開される現在の座席位置\n'
        '・お気に入りに登録したキャンパスの情報',
    'terms_2_title': '2. 情報の利用目的',
    'terms_2_body': '取得した情報は、座席の空き状況の可視化、フレンド間での位置共有、'
        'アプリの改善(フィードバックの確認)以外の目的には利用しません。',
    'terms_3_title': '3. 情報の共有範囲',
    'terms_3_body': '座席の利用状況や現在地は、承認済みのフレンドにのみ共有されます。'
        'フレンド以外の第三者や、本アプリの開発チーム以外の外部組織に'
        '個人を特定できる情報を提供することはありません。',
    'terms_4_title': '4. データの削除',
    'terms_4_body': 'プロフィール写真は、プロフィール画面からいつでも削除できます。'
        'アカウント自体の削除や、保存されているデータ全体の削除を希望する場合は、'
        '開発チームまでフィードバック画面よりご連絡ください。',
    'terms_5_title': '5. 免責事項',
    'terms_5_body': '本アプリは学生プロジェクトの成果物であり、動作の完全性・正確性を'
        '保証するものではありません。座席状況の表示が実際の状況と'
        '異なる場合があります。',

    // --- 設定画面 ---
    'settings_title': '設定',
    'settings_notifications_heading': '通知',
    'settings_notif_friend_request': 'フレンド申請の通知',
    'settings_notif_friend_request_sub': 'フレンド申請が届いた時に通知します',
    'settings_notif_friend_seated': 'フレンド着席の通知',
    'settings_notif_friend_seated_sub': 'フレンドが座席にチェックインした時に通知します',
    'settings_notif_checkin_reminder': 'チェックイン放置リマインド',
    'settings_notif_checkin_reminder_sub': 'チェックインしたまま3分経つと通知します',
    'settings_language_heading': '表示言語 / Language',
    'settings_language_note': '現在は一部の画面のみ対応しています。',
  },
  'en': {
    // --- Login ---
    'app_title': 'Suwaho',
    'login_google': 'Sign in with Google',
    'login_apple': 'Sign in with Apple',
    'or_divider': 'or',
    'label_name': 'Name',
    'label_email': 'Email address',
    'label_password': 'Password',
    'button_login': 'Log in',
    'button_register': 'Sign up',
    'switch_to_register': 'First time here? Sign up',
    'switch_to_login': 'Already have an account? Log in',
    'forgot_password': 'Forgot your password?',
    'guest_login': 'Continue as guest (friend feature unavailable)',
    'guest_blocked_title': 'Guests cannot access this',
    'guest_blocked_body': 'The friend feature (seeing where friends are seated) is only available to users with an account.',
    'close': 'Close',
    'forgot_password_title': 'Reset your password',
    'forgot_password_desc': 'Enter your registered email address.\nWe will send you a link to reset your password.',
    'cancel': 'Cancel',
    'send': 'Send',

    // --- Home ---
    'search_campus_hint': 'Search campus',
    'select_campus_title': 'Please select a campus',
    'nav_home': 'Home',
    'nav_friend': 'Friends',
    'nav_qr': 'QR Code',
    'no_campus_found': 'No results found',

    // --- Drawer ---
    'drawer_floor_select': 'Select Floor',
    'drawer_how_to_use': 'How to Use',
    'drawer_profile': 'Profile',
    'drawer_about': 'About',
    'drawer_feedback': 'Feedback',
    'drawer_terms': 'Terms & Privacy Policy',
    'drawer_settings': 'Settings',
    'drawer_logout': 'Log Out',
    'logout_confirm_title': 'Log out?',

    // --- Seat detail ---
    'seat_shared_space': 'Shared Space',
    'seat_individual_space': 'Individual Workspace',
    'seat_status_label': 'Status',
    'seat_status_occupied': 'Occupied 🔴',
    'seat_status_vacant': 'Vacant 🟢',
    'seat_capacity_label': 'Capacity',
    'seat_capacity_unit': 'people',
    'seat_power_label': 'Power Outlet',
    'seat_power_yes': 'Yes 🔌',
    'seat_power_no': 'No ✕',
    'seat_amenities_label': 'Amenities',
    'seat_amenities_none': 'None',

    // --- Disaster mode ---
    'disaster_toggle_tooltip': 'Toggle disaster mode',
    'disaster_banner': 'Disaster mode: orange seats are kamado benches',
    'kamado_usage_heading': 'A. Using the kamado bench',
    'kamado_storage_heading': 'B. Storing the unit bench (after use)',
    'kamado_caution_heading': 'Cautions',
    'kamado_1_title': 'Kamado Bench 1',
    'kamado_2_title': 'Kamado Bench 2',
    'kamado_usage_1': 'For safety, always work in a team of two or more. Prepare the special wrench.',
    'kamado_usage_2': 'Loosen the screws with the special wrench and remove the unit bench (seat) on top.',
    'kamado_usage_3': 'Pull out the support legs of the unit bench.',
    'kamado_usage_4': 'Check the wind guard and charcoal panel inside; hang the wind guard on the grill with the S-hook, and set the charcoal panel below the grill.',
    'kamado_usage_5': 'Place charcoal on the panel and light it, then place a pot or kettle on the grill to cook (if the ground is not sand or soil, lay bricks down before heating).',
    'kamado_storage_1': 'Stack the wind guard and charcoal panel on the grill and place the S-hook on top.',
    'kamado_storage_2': 'Fold the support legs of the unit bench (seat), then attach the legs to the main body (pass the legs through the gap in the grill).',
    'kamado_storage_3': 'Secure the unit bench to the main body with the special wrench and screws to finish.',
    'kamado_caution_1': 'Keep enough clear space around the product while heating to avoid any fire risk.',
    'kamado_caution_2': 'If the ground is not sand or soil, lay bricks or similar material down before heating.',
    'kamado_caution_3': 'Pouring water on the product right after heating may damage it. Let it cool down fully before cleaning.',
    'kamado_caution_4': 'The product stays hot for a while after extinguishing. Do not approach or touch it until it has cooled.',
    // --- Floor map facility labels ---
    'facility_stairs': 'Stairs',
    'facility_reception': 'Reception Counter',
    'facility_entrance': 'Entrance',
    'facility_entrance_small': 'Entrance',
    'facility_sofa_corner': 'Sofa Corner',
    'facility_support_counter': 'Support\nCounter',
    'facility_search_terminal': 'Search\nTerminal',
    'facility_lending_machine': 'Self-Checkout\nMachine',
    'facility_storage': 'Storage',
    'facility_media_desk': 'Media\nDesk',

    // --- Check-in ---
    'checkin_title': 'Check In to a Seat',
    'checkin_scan_qr': 'Scan QR Code',
    'checkin_manual_entry': 'Enter seat number manually',
    'checkin_manual_dialog_title': 'Enter Seat Number',
    'checkin_manual_hint': 'e.g. seat_01',
    'checkin_button': 'Check In',
    'checkin_scan_hint': 'Align the seat QR code within the frame',
    'checkin_success': 'Checked in to',
    'checkin_fail': 'Check-in failed',
    'checkin_join_title': 'This seat is in use',
    'checkin_join_body_prefix': 'Currently in use by ',
    'checkin_join_body_suffix': '. Would you like to check in with them?',
    'not_qr_seat': "This doesn't look like a seat QR code",

    // --- Friends ---
    'friend_title': 'Friends',
    'friend_my_qr': 'Your QR code (let others scan it)',
    'friend_scan_button': 'Scan QR to send friend request',
    'friend_incoming_requests': 'Incoming Friend Requests',
    'friend_no_requests': 'No pending requests',
    'friend_request_received': 'Sent you a friend request',
    'friend_locations': "Friends' Current Locations",
    'friend_none_yet': 'No friends yet',
    'friend_seated_at': 'seated at',
    'friend_not_checked_in': 'Not currently checked in',
    'friend_scan_hint': "Scan your friend's QR code",
    'friend_not_add_qr': "This doesn't look like a friend-add QR code",
    'friend_request_sent': 'Friend request sent',
    'friend_request_fail': 'Failed to send request',

    // --- Profile ---
    'profile_title': 'Profile',
    'profile_pick_photo': 'Choose Photo',
    'profile_remove_photo': 'Remove Photo',
    'profile_name_label': 'Name',
    'profile_updated': 'Profile photo updated',
    'profile_update_failed': 'Failed to update photo',
    'profile_removed': 'Photo removed',
    'profile_remove_failed': 'Failed to remove photo',

    // --- Photo crop ---
    'crop_title': 'Adjust Photo Position',
    'crop_confirm': 'Done',
    'crop_instructions': 'Pinch to zoom, drag to reposition',
    'crop_failed': 'Failed to crop photo',

    // --- Onboarding ---
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_start': 'Get Started',
    'onboarding_title_1': 'See seat availability at a glance',
    'onboarding_desc_1': 'Check which seats are free on the campus\nfloor map in real time.',
    'onboarding_title_2': 'Check in instantly with a QR code',
    'onboarding_desc_2': 'Just scan the QR code on the table\nto check in to a seat.',
    'onboarding_title_3': 'See where your friends are',
    'onboarding_desc_3': 'Add friends to see which seat\nthey are currently at.',
    'onboarding_title_4': 'Useful in emergencies too',
    'onboarding_desc_4': "Disaster mode shows you where kamado\nbenches are and how to use them.",

    // --- How to use ---
    'howto_title': 'How to Use',
    'howto_1_title': 'Check seat availability',
    'howto_1_step1': 'From the home screen, choose a campus and a floor (6F/9F).',
    'howto_1_step2': 'Tap a seat to see details (vacant/occupied, power outlet, etc.).',
    'howto_1_step3': 'Blue means vacant, red means occupied, at a glance.',
    'howto_2_title': 'Check in with a QR code',
    'howto_2_step1': 'Tap "QR Code" in the bottom navigation.',
    'howto_2_step2': 'Scan the QR code on the table to check in instantly.',
    'howto_2_step3': "If you can't scan it, you can also enter the seat number manually.",
    'howto_3_title': 'Add friends',
    'howto_3_step1': 'Show your own QR code from "Friends" in the bottom navigation.',
    'howto_3_step2': "Have a friend scan it (or scan theirs) to send a friend request.",
    'howto_3_step3': 'Once approved, you can see which seat your friend is at.',
    'howto_4_title': 'Favorite a campus',
    'howto_4_step1': 'Tap the ☆ on the top-left of a campus card to mark it ★.',
    'howto_4_step2': 'Favorited campuses appear at the top of the list next time you open the app.',
    'howto_5_title': 'Disaster mode',
    'howto_5_step1': 'Toggle it with the ⚠️ icon at the top-right of the floor map.',
    'howto_5_step2': 'When on, seats usable as "kamado benches" in a disaster are shown in orange.',
    'howto_5_step3': 'Tap one to see how to assemble it and usage cautions.',

    // --- About ---
    'about_title': 'About',
    'about_version_prefix': 'Version',
    'about_description': 'A seat management app for university campuses that shows real-time seat availability.',
    'about_team_heading': 'Development Team',

    // --- Feedback ---
    'feedback_title': 'Feedback',
    'feedback_description': 'Please share bug reports or feature requests.',
    'feedback_hint': 'Type your feedback here',
    'feedback_send': 'Send',
    'feedback_empty_error': 'Please enter a message',
    'feedback_sent': 'Sent — thank you!',
    'feedback_send_failed': 'Failed to send',

    // --- Terms ---
    'terms_title': 'Terms & Privacy Policy',
    'terms_intro': 'This app, "Suwaho," was developed by a student team as part of a '
        'university industry-collaboration program. Below is a simplified terms of use and privacy policy.',
    'terms_1_title': '1. Information We Collect',
    'terms_1_body': 'This app may collect and store the following information:\n'
        '- Email address and display name used for login (Google/Apple account)\n'
        '- Profile photo (only if you choose to set one)\n'
        '- Seat check-in history (when and which seat you used)\n'
        '- Friend relationships, and your current seat location shared with friends\n'
        '- Campuses you have marked as favorites',
    'terms_2_title': '2. Purpose of Use',
    'terms_2_body': 'Collected information is used only to display seat availability, '
        'share location among friends, and improve the app (via feedback). It is not used for any other purpose.',
    'terms_3_title': '3. Information Sharing',
    'terms_3_body': 'Your seat usage and current location are only shared with approved friends. '
        'We do not provide personally identifiable information to any third party '
        'or external organization other than the app\'s development team.',
    'terms_4_title': '4. Data Deletion',
    'terms_4_body': 'You can delete your profile photo at any time from the Profile screen. '
        'If you wish to delete your account or all stored data, please contact '
        'the development team via the Feedback screen.',
    'terms_5_title': '5. Disclaimer',
    'terms_5_body': 'This app is the result of a student project and does not guarantee '
        'complete accuracy or reliability. Displayed seat status may differ from actual conditions.',

    // --- Settings ---
    'settings_title': 'Settings',
    'settings_notifications_heading': 'Notifications',
    'settings_notif_friend_request': 'Friend request notifications',
    'settings_notif_friend_request_sub': 'Notify me when I receive a friend request',
    'settings_notif_friend_seated': 'Friend seated notifications',
    'settings_notif_friend_seated_sub': 'Notify me when a friend checks in to a seat',
    'settings_notif_checkin_reminder': 'Check-in reminder',
    'settings_notif_checkin_reminder_sub': 'Notify me 3 minutes after checking in',
    'settings_language_heading': 'Display Language / 表示言語',
    'settings_language_note': 'Currently only some screens support this.',
  },
};

/// 翻訳文字列を取得するヘルパー。
/// 対応するキーが見つからない場合は、キー名をそのまま返す
/// (画面が真っ白になったりクラッシュしたりしないための安全策)。
class AppStrings {
  static String t(String key) {
    final lang = AppLanguage.instance.code;
    return _translations[lang]?[key] ?? _translations['ja']?[key] ?? key;
  }
}
