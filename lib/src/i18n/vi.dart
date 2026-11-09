// Toàn bộ chữ hiển thị cho người dùng của ứng dụng VNLF Social.
//
// Phần giữa các dấu GENERATED được sinh từ packages/i18n/src/vi.ts của web,
// nên khóa và câu chữ giống hệt web (vi.pageLogin.dangNhapVnlfSocial...).
// Sửa câu chữ của web ở đó rồi chạy `python3 tool/sync_vi_strings.py`.
// Câu chữ riêng của ứng dụng native nằm trong ViApp ở cuối file, sửa tay.
// Placeholder dạng {name} được điền bằng format().

/// Mọi câu chữ của ứng dụng, cùng cấu trúc với `vi` của web.
const vi = Vi._();

final _placeholder = RegExp(r'\{(\w+)\}');

/// Điền placeholder {name}; placeholder thiếu tham số được giữ nguyên để dễ
/// thấy, như format() của web.
String format(String template, Map<String, Object?> params) =>
    template.replaceAllMapped(_placeholder, (match) {
      final value = params[match[1]];
      return value == null ? match[0]! : '$value';
    });

final class Vi {
  const Vi._();

  /// Câu chữ riêng của ứng dụng native, không có trên web.
  final app = const ViApp._();

  // BEGIN GENERATED: python3 tool/sync_vi_strings.py
  final common = const ViCommon._();
  final accountViews = const ViAccountViews._();
  final activityCalendar = const ViActivityCalendar._();
  final adminViews = const ViAdminViews._();
  final adminIcons = const ViAdminIcons._();
  final adminVoiceViews = const ViAdminVoiceViews._();
  final articleEditor = const ViArticleEditor._();
  final articleImageNode = const ViArticleImageNode._();
  final articleRenderer = const ViArticleRenderer._();
  final articleTypes = const ViArticleTypes._();
  final avatarCrop = const ViAvatarCrop._();
  final avatarCropDialog = const ViAvatarCropDialog._();
  final channelViews = const ViChannelViews._();
  final chatPresentation = const ViChatPresentation._();
  final chatUi = const ViChatUi._();
  final commentsPanel = const ViCommentsPanel._();
  final communicationList = const ViCommunicationList._();
  final confirm = const ViConfirm._();
  final contentVote = const ViContentVote._();
  final linkPreview = const ViLinkPreview._();
  final channelSearch = const ViChannelSearch._();
  final conversationSearch = const ViConversationSearch._();
  final decor = const ViDecor._();
  final dailyCheckin = const ViDailyCheckin._();
  final dialog = const ViDialog._();
  final directMessageLiveView = const ViDirectMessageLiveView._();
  final error = const ViError._();
  final stickers = const ViStickers._();
  final projects = const ViProjects._();
  final adminProjects = const ViAdminProjects._();
  final adminStickers = const ViAdminStickers._();
  final feedbackThread = const ViFeedbackThread._();
  final feedbackWidget = const ViFeedbackWidget._();
  final feedViews = const ViFeedViews._();
  final floatingMessages = const ViFloatingMessages._();
  final gifPicker = const ViGifPicker._();
  final hub = const ViHub._();
  final profileLinks = const ViProfileLinks._();
  final distroBadge = const ViDistroBadge._();
  final wardrobe = const ViWardrobe._();
  final guestbook = const ViGuestbook._();
  final icons = const ViIcons._();
  final klipy = const ViKlipy._();
  final layout = const ViLayout._();
  final leaderboardView = const ViLeaderboardView._();
  final loading = const ViLoading._();
  final localArticleView = const ViLocalArticleView._();
  final manifest = const ViManifest._();
  final appInstall = const ViAppInstall._();
  final videoPlayer = const ViVideoPlayer._();
  final mediaGallery = const ViMediaGallery._();
  final miscViews = const ViMiscViews._();
  final myArticlesView = const ViMyArticlesView._();
  final notFound = const ViNotFound._();
  final notificationCenter = const ViNotificationCenter._();
  final notificationCopy = const ViNotificationCopy._();
  final opengraphImage = const ViOpengraphImage._();
  final page = const ViPage._();
  final pageAdminMembers = const ViPageAdminMembers._();
  final pageAdminPoints = const ViPageAdminPoints._();
  final pageAdminReportsReportid = const ViPageAdminReportsReportid._();
  final pageAdminVoiceNew = const ViPageAdminVoiceNew._();
  final pageAdminVoiceRoomid = const ViPageAdminVoiceRoomid._();
  final pageALocalArticleid = const ViPageALocalArticleid._();
  final pageASlug = const ViPageASlug._();
  final pageChannelsSlug = const ViPageChannelsSlug._();
  final pageChannelsSlugMembers = const ViPageChannelsSlugMembers._();
  final pageChannelsSlugSettings = const ViPageChannelsSlugSettings._();
  final pageCommunityGuidelines = const ViPageCommunityGuidelines._();
  final pageExplore = const ViPageExplore._();
  final pageForgotPassword = const ViPageForgotPassword._();
  final caramosHelp = const ViCaramosHelp._();
  final poll = const ViPoll._();
  final shortcuts = const ViShortcuts._();
  final caramosSupport = const ViCaramosSupport._();
  final pageHelp = const ViPageHelp._();
  final pageLeaderboard = const ViPageLeaderboard._();
  final pageLogin = const ViPageLogin._();
  final pageMessagesConversationid = const ViPageMessagesConversationid._();
  final pageMessagesConversationidInfo =
      const ViPageMessagesConversationidInfo._();
  final pagePrivacy = const ViPagePrivacy._();
  final pageRegister = const ViPageRegister._();
  final pageResetPassword = const ViPageResetPassword._();
  final pageSearch = const ViPageSearch._();
  final pageSettingsNotifications = const ViPageSettingsNotifications._();
  final pageStats = const ViPageStats._();
  final pageTTag = const ViPageTTag._();
  final pageUUsername = const ViPageUUsername._();
  final pageVoiceRoomid = const ViPageVoiceRoomid._();
  final people = const ViPeople._();
  final pushSettings = const ViPushSettings._();
  final reactionPicker = const ViReactionPicker._();
  final routeFeedxml = const ViRouteFeedxml._();
  final searchView = const ViSearchView._();
  final select = const ViSelect._();
  final seo = const ViSeo._();
  final settingsViews = const ViSettingsViews._();
  final linkedAccounts = const ViLinkedAccounts._();
  final socialChrome = const ViSocialChrome._();
  final socialLayoutClient = const ViSocialLayoutClient._();
  final socialOverlays = const ViSocialOverlays._();
  final socialRuntime = const ViSocialRuntime._();
  final statsViews = const ViStatsViews._();
  final voiceContext = const ViVoiceContext._();
  final voiceView = const ViVoiceView._();
  final api = const ViApi._();
  final email = const ViEmail._();
  final worker = const ViWorker._();
  // END GENERATED
}

// BEGIN GENERATED: python3 tool/sync_vi_strings.py
final class ViCommon {
  const ViCommon._();
  final accountActive = 'Đang hoạt động';
  final accountSuspended = 'Tạm khóa';
  final accountBanned = 'Bị cấm';
  final accountPendingDeletion = 'Chờ xóa';
  final yeuCauThatBai = 'Có lỗi xảy ra (mã {status}). Thử lại sau ít phút.';
  final channels2 = 'Channels';
  final cheDoToi = 'Giao diện tối';
  final cheDoSang = 'Giao diện sáng';
  final voiceRooms = 'Voice';
  final roleMember = 'Thành viên';
  final roleModerator = 'Moderator';
  final roleAdmin = 'Admin';
  final roleOwner = 'Owner';
  final thuLai = 'Thử lại';
  final veBangTin = 'Về bảng tin';
  final tinNhan = 'Tin nhắn';
  final lichSuDiem = 'Lịch sử điểm';
  final caiDat = 'Cài đặt';
  final chinhSuaHoSo = 'Chỉnh sửa hồ sơ';
  final baoMat = 'Bảo mật';
  final hienThi = 'Hiển thị';
  final riengTu = 'Riêng tư';
  final quanTri = 'Quản trị';
  final quanLyBaiViet = 'Quản lý bài viết';
  final gopYBaoLoi = 'Góp ý & báo lỗi';
  final quanLyChannels = 'Quản lý channel';
  final taoChannel = 'Tạo channel';
  final baiVietCuaBan = 'Bài viết của bạn';
  final baiViet = 'Bài viết';
  final timKiem = 'Tìm kiếm';
  final bangXepHangTuan = 'Bảng xếp hạng tuần';
  final thongBao = 'Thông báo';
  final chiaSeBaiViet = 'Chia sẻ bài';
  final dangNhap = 'Đăng nhập';
  final quyChuanCongDong = 'Quy chuẩn cộng đồng';
  final quanLyVoiceRooms = 'Quản lý voice room';
  final hoSo = 'Hồ sơ';
  final dong = 'Đóng';
  final boLuuBaiViet = 'Bỏ lưu bài';
  final luuBaiViet = 'Lưu bài';
  final baoCao = 'Báo cáo';
  final huy = 'Hủy';
  final dangGui = 'Đang gửi…';
  final chiTiet = 'Chi tiết';
  final tatCa = 'Tất cả';
  final binhLuan = 'Bình luận';
  final theoDoi = 'Theo dõi';
  final dangTai = 'Đang tải…';
  final dangXuLy = 'Đang xử lý…';
  final chan = 'Chặn';
  final xemTinMoiNhat = 'Xem tin mới nhất';
  final anhDinhKem = 'Ảnh đính kèm';
  final dangLuu = 'Đang lưu…';
  final thanhVien = 'Thành viên';
  final xoa = 'Xóa';
  final luu = 'Lưu';
  final sua = 'Sửa';
  final anhPhaiNhoHon10mb = 'Ảnh phải nhỏ hơn 10MB.';
  final daLuu = 'Đã lưu';
  final moTa = 'Mô tả';
  final luuThayDoi = 'Lưu thay đổi';
  final channels = 'Channels';
  final dashboard = 'Tổng quan';
  final khoiPhuc = 'Khôi phục';
  final tinNhanDaDuocXoa = 'Tin nhắn đã bị xóa';
  final khongTimThayVoiceRoom = 'Không tìm thấy voice room.';
  final khongTimThayUser = 'Không tìm thấy thành viên.';
  final khongTimThayTinNhan = 'Không tìm thấy tin nhắn.';
}

final class ViAccountViews {
  const ViAccountViews._();
  final chuaTheCapNhatBai = 'Chưa cập nhật được bài';
  final thanhVienVnlfSocial = 'Thành viên VNLF Social.';
  final chuaTheCapNhatTheo = 'Chưa cập nhật được theo dõi';
  final dangCapNhat = 'Đang cập nhật…';
  final dangTheoDoi = 'Đang theo dõi';
  final moTuyChonHoSo = 'Mở tùy chọn hồ sơ';
  final caiDatTaiKhoan = 'Cài đặt tài khoản';
  final nhanTin = 'Nhắn tin';
  final xemDiemHoatDong = 'Xem điểm hoạt động';
  final baoCaoHoSo = 'Báo cáo hồ sơ';
  final levelSo = 'Level {level}';
  final xpTong = 'Tổng XP';
  final ngayStreak = 'ngày liên tiếp';
  final dangTheoDoi2 = 'đang theo dõi';
  final nguoiTheoDoi = 'người theo dõi';
  final noiDungHoSo = 'Nội dung hồ sơ';
  final chuaCoBaiVietPublic = 'Chưa có bài đăng công khai';
  final chuaCoBinhLuanPublic = 'Chưa có bình luận công khai';
  final chuaLuuBaiViet = 'Chưa lưu bài nào';
  final noiDungMoiSeXuat = 'Khi có bài mới, bạn sẽ thấy ở đây.';
  final baoCao = 'Báo cáo @{username}';
  final anToanCongDong = 'An toàn cộng đồng';
  final choModeratorBietDieuGi = 'Kể cho moderator chuyện gì đã xảy ra…';
  final daGuiBaoCaoHo = 'Đã gửi báo cáo về @{username}';
  final chuaTheGuiBaoCao = 'Chưa gửi được báo cáo';
  final guiBaoCao = 'Gửi báo cáo';
}

final class ViActivityCalendar {
  const ViActivityCalendar._();
  final th = 'Th{value}';
  final lichDiemDanh = 'Lịch điểm danh';
  final lichDiemHoatDong = 'Lịch điểm hoạt động';
  final chuaDenNgay = 'Chưa tới ngày';
  final daDiemDanhChuoiNgay = 'Đã điểm danh, streak {value} ngày';
  final chuaDiemDanh = 'Chưa điểm danh';
  final homNay = ', hôm nay';
  final itDiem = 'Ít điểm';
  final daDiemDanh = 'Đã điểm danh';
  final nhieuDiem = 'Nhiều điểm';
  final daDiemDanhChuoiNgay2 = 'Đã điểm danh · Streak {streakDay} ngày';
}

final class ViAdminViews {
  const ViAdminViews._();
  final nhanBinhLuan = 'Nhận bình luận';
  final diemNhanBinhLuan = 'Điểm khi bài nhận bình luận';
  final xpNhanBinhLuan =
      'XP cho chủ bài · mỗi người tính 1 lần mỗi bài · tối đa 15 lần/ngày';
  final trangThaiBaoCaoOpen = 'Mới';
  final trangThaiBaoCaoInReview = 'Đang xử lý';
  final trangThaiBaoCaoResolved = 'Đã xử lý';
  final xemBaoCao = 'Xem báo cáo: {title}';
  final restoreUser = 'Mở khóa';
  final suspend = 'Tạm khóa';
  final productInboxTrend = 'Hộp góp ý';
  final dangHoatDong = 'Đang hoạt động';
  final baiVietPublic = 'Bài viết công khai';
  final dangPublic = 'Đang hiển thị';
  final reportChoXuLy = 'Báo cáo chờ xử lý';
  final canXem = 'Cần xem';
  final dangMo = 'Đang mở';
  final ownerConsole = 'Quản trị';
  final giuCongDongKhoeManh = 'Giữ cộng đồng khỏe mạnh.';
  final gopYLoi = 'Góp ý & lỗi';
  final voiceRooms = 'Voice rooms';
  final cauHinh = 'Cài đặt';
  final reportGanDay = 'Báo cáo gần đây';
  final xemQueue = 'Xem tất cả';
  final pointRules = 'Quy tắc tính điểm';
  final suaRules = 'Sửa quy tắc';
  final dangBaiThuong = 'Đăng bài thường';
  final xp = '+{post} XP';
  final dangArticle = 'Đăng Article';
  final xp2 = '+{article} XP';
  final gopYBaoLoi = 'Góp ý / Báo lỗi';
  final streakMultiplier = 'Hệ số streak';
  final configurable = 'Tùy chỉnh được';
  final voiceRoom = 'Voice room';
  final tamTat = 'Tạm tắt';
  final moi = 'Mới';
  final dangXem = 'Đang xem';
  final daXuLy = 'Đã xử lý';
  final daDong = 'Đã đóng';
  final deLamSau = 'Để làm sau';
  final dangTaiMedia = 'Đang tải tệp…';
  final khongTaiDuocMedia = 'Không tải được tệp';
  final videoBaoLoi = 'Video báo lỗi';
  final anhDinhKemGopY = 'Ảnh đính kèm góp ý';
  final daCapNhatProductInbox = 'Đã cập nhật góp ý';
  final chuaTheCapNhatGop = 'Chưa cập nhật được góp ý';
  final productInbox = 'Hộp góp ý';
  final phieuTrongBoLoc = 'phiếu khớp bộ lọc';
  final productFeedbackTachKhoiReport =
      'Góp ý và báo lỗi được tách riêng khỏi báo cáo vi phạm. Chỉ thấy người gửi khi họ đã đăng nhập lúc gửi.';
  final loaiProductFeedback = 'Loại góp ý';
  final baoLoi = 'Báo lỗi';
  final gopY = 'Góp ý';
  final trangThaiProductFeedback = 'Trạng thái góp ý';
  final moiTrangThai = 'Mọi trạng thái';
  final chuaTaiDuocProductInbox = 'Chưa tải được hộp góp ý.';
  final khongCoPhieuPhuHop = 'Không có phiếu nào khớp';
  final doiBoLocHoacQuay = 'Thử đổi bộ lọc hoặc quay lại sau.';
  final danhSachGopYVa = 'Danh sách góp ý và báo lỗi';
  final khachAnDanh = 'Khách ẩn danh';
  final tep = ' · {count} tệp';
  final chiTiet = 'Chi tiết {title}';
  final loaiTicket = 'Loại';
  final nguoiGui = 'Người gửi';
  final trang = 'Trang';
  final mediaDinhKem = 'Tệp đính kèm';
  final ghiChuNoiBo = 'Ghi chú nội bộ';
  final caramos = 'CaramOS';
  final hoTroCaramos = 'Hỗ trợ CaramOS';
  final loaiHoTro = 'Loại hỗ trợ';
  final moiLoaiHoTro = 'Mọi loại hỗ trợ';
  final hoTroKhac = 'Hỗ trợ khác';
  final khachCaramos = 'Khách từ CaramOS';
  final lienHeRiengTu = 'Liên hệ (chỉ admin thấy)';
  final khongDeLaiLienHe = 'Không để lại';
  final chiaSeCongDong = 'Chia sẻ với cộng đồng';
  final nguoiGuiChoPhep = 'Người gửi cho phép';
  final nguoiGuiKhongChoPhep = 'Không cho phép';
  final locChiaSe = 'Lọc theo chia sẻ';
  final moiChiaSe = 'Mọi lựa chọn chia sẻ';
  final choDang = 'Chờ đăng';
  final congKhai = ' · Công khai';
  final dangChoCongDong = 'Đăng cho cộng đồng';
  final dangChoCongDongMoTa =
      'Sửa hoặc xoá thông tin cá nhân trước khi đăng. Liên hệ, địa chỉ IP và link theo dõi không bao giờ hiện.';
  final daDangLuc = 'Đã đăng lúc {time}. {count} câu trả lời.';
  final tieuDeCongKhai = 'Tiêu đề công khai';
  final noiDungCongKhai = 'Nội dung công khai';
  final hienKetQuaDriverCheck = 'Hiện kết quả Driver Check';
  final hienLinkHoSoPhanCung = 'Hiện link hồ sơ phần cứng';
  final anAnh = 'Ẩn ảnh {value}';
  final anVideo = 'Ẩn video {value}';
  final coTheLaThongTinCaNhan = 'Có thể là thông tin cá nhân: {items}';
  final dang = 'Đăng';
  final capNhatBaiDang = 'Cập nhật bài đăng';
  final goKhoiCongDong = 'Gỡ khỏi cộng đồng';
  final goKhoiCongDongHoi = 'Gỡ khỏi cộng đồng?';
  final goKhoiCongDongMoTa =
      'Trang công khai sẽ báo không tìm thấy. Câu trả lời vẫn được giữ, đăng lại thì hiện lại.';
  final xemTrangCongKhai = 'Xem trang công khai';
  final daDangChoCongDong = 'Đã đăng cho cộng đồng.';
  final daCapNhatBaiDang = 'Đã cập nhật bài đăng.';
  final daGoKhoiCongDong = 'Đã gỡ khỏi cộng đồng.';
  final chuaDangDuoc = 'Chưa đăng được. Thử lại sau ít phút.';
  final ungDung = 'Ứng dụng';
  final heThong = 'Hệ thống';
  final hoSoPhanCung = 'Hồ sơ phần cứng';
  final moTrenLinuxHardware = 'Mở trên linux-hardware.org';
  final trangTheoDoi = 'Trang theo dõi';
  final moTrangNguoiGui = 'Mở trang của người gửi';
  final ketQuaDriverCheck = 'Kết quả Driver Check';
  final nhatKyUngDung = 'Nhật ký ứng dụng';
  final baoCaoDayDu = 'Báo cáo đầy đủ (JSON)';
  final traLoiNguoiGui = 'Trả lời người gửi';
  final traLoiHienOTrangTheoDoi =
      'Hiện ở trang theo dõi của người gửi, và ở trang công khai nếu đã đăng. Ghi chú nội bộ thì không.';
  final vietCauTraLoi = 'Cách xử lý, driver cần cài, lệnh cần chạy…';
  final ghiQuyetDinhHoacBuoc = 'Ghi lại quyết định hoặc cách xử lý…';
  final nhanXuLy = 'Nhận xử lý';
  final daXuLyReport = 'Đã xử lý báo cáo';
  final daNhanXuLyReport = 'Đã nhận xử lý báo cáo';
  final chuaTheCapNhatReport = 'Chưa cập nhật được báo cáo';
  final moderation = 'Kiểm duyệt';
  final reportQueue = 'Báo cáo vi phạm';
  final locReport = 'Lọc báo cáo';
  final resolve = 'Đã xử lý';
  final khongCoReportTrongTrang = 'Không có báo cáo nào ở trạng thái này.';
  final khongTaiDuocReport = 'Không tải được báo cáo.';
  final kiemTraKetNoiRoi = 'Kiểm tra kết nối rồi thử lại.';
  final khongTimThayReport = 'Không tìm thấy báo cáo.';
  final reportKhongTonTaiHoac = 'Báo cáo không tồn tại hoặc đã bị xóa.';
  final daResolveReport = 'Đã đánh dấu đã xử lý';
  final report = 'Báo cáo #{id}';
  final doiTuong = 'Bị báo cáo';
  final khongCoMoTaThem = 'Không có mô tả thêm.';
  final ghiChuKiemDuyet = 'Ghi chú kiểm duyệt';
  final cachXuLy = 'Cách xử lý';
  final chiDongBaoCao = 'Không gỡ gì, chỉ cập nhật báo cáo';
  final goTrangTri = 'Gỡ trang trí';
  final goTrangTriMoTa =
      'Đưa trang cá nhân về mặc định: bỏ ảnh bìa, hình nền, nhạc, màu tên, icon và đồ trong tủ.';
  final khoaTrangTri = 'Khóa trang trí';
  final khongKhoaTrangTri = 'Không khóa';
  final khoaTrangTriNgay = '{days} ngày';
  final goLoiNhan = 'Gỡ lời nhắn';
  final goLoiNhanMoTa = 'Lời nhắn biến mất khỏi sổ lưu bút.';
  final goIcon = 'Gỡ icon';
  final goIconMoTa =
      'Icon rời kho và rời tên mọi người đang dùng. Muốn khóa người tải, vào Quản lý icon.';
  final anBoSticker = 'Ẩn bộ sticker';
  final anBoStickerMoTa =
      'Bộ biến khỏi khay của mọi người; sticker của bộ không còn hiện, kể cả trong tin nhắn cũ.';
  final boStickerDaAn = 'Đã ẩn';
  final xemBoSticker = 'Xem bộ sticker';
  final xemTrangCaNhan = 'Xem trang cá nhân';
  final xemQuanLyIcon = 'Mở Quản lý icon';
  final noiDungBiBaoCao = 'Nội dung bị báo cáo';
  final nguoiBaoCao = 'Người báo cáo';
  final loaiDoiTuong = 'Loại';
  final moTaNguoiBaoCao = 'Người báo cáo viết thêm';
  final moNoiDung = 'Mở để xem';
  final daGoNoiDung = 'Đã gỡ';
  final khongCoChu = 'Không có chữ (chỉ có ảnh hoặc GIF).';
  final doiTuongKhongCon = 'Không tìm thấy nội dung này nữa, có thể đã bị xóa.';
  final tinNhanRiengKhongMo =
      'Tin nhắn riêng chỉ hai người trong cuộc đọc được, nên không có liên kết để mở.';
  final trongNoiDung = 'Trong {place}';
  final goNoiDung = 'Gỡ nội dung';
  final goNoiDungMoTa =
      'Ẩn với mọi người và trừ điểm người viết đã nhận từ nội dung này.';
  final anDuAn = 'Ẩn dự án';
  final anDuAnMoTa =
      'Dự án biến khỏi trang Dự án và trang cá nhân; người khác mở link thì báo không tìm thấy.';
  final xemThanhVien = 'Mở Quản lý thành viên';
  final lyDoBaoCao = const <String, String>{
    'spam': 'Spam hoặc quảng cáo',
    'harassment': 'Quấy rối',
    'misinformation': 'Thông tin sai lệch',
    'other': 'Khác',
    'offensive': 'Phản cảm',
    'impersonation': 'Giả mạo',
    'copyright': 'Vi phạm bản quyền',
    'music': 'Nhạc không phù hợp',
    'wrong': 'Hướng dẫn sai hoặc nguy hiểm',
    'offtopic': 'Lạc đề',
    'channel_message': 'Tin nhắn trong channel',
    'voice': 'Trong voice room',
    'profile': 'Trang cá nhân',
    'malware': 'Phần mềm độc hại',
  };
  final loaiBaoCao = const <String, String>{
    'ARTICLE': 'Bài viết',
    'COMMENT': 'Bình luận',
    'MESSAGE': 'Tin nhắn',
    'VOICE_MESSAGE': 'Tin nhắn trong voice',
    'USER': 'Thành viên',
    'VOICE_USER': 'Thành viên trong voice',
    'PROFILE_DECOR': 'Trang cá nhân',
    'GUESTBOOK_ENTRY': 'Lời nhắn sổ lưu bút',
    'PROFILE_ICON': 'Icon',
    'DM_CONVERSATION': 'Cuộc trò chuyện riêng',
    'HELP_ANSWER': 'Câu trả lời hỗ trợ CaramOS',
    'STICKER_PACK': 'Bộ sticker',
    'PROJECT': 'Dự án',
  };
  final ghiLaiQuyetDinh = 'Ghi lại quyết định…';
  final timGopY =
      'Tìm theo #số phiếu, mã VNLF-…, chữ trong phiếu hoặc @người gửi';
  final lyDoGo = const <String, String>{
    'rules': 'Vi phạm quy định cộng đồng.',
    'spam': 'Spam hoặc quảng cáo.',
    'harassment': 'Quấy rối hoặc xúc phạm người khác.',
    'misinformation': 'Thông tin sai lệch.',
    'offensive': 'Nội dung phản cảm.',
    'impersonation': 'Giả mạo người khác.',
    'copyright': 'Vi phạm bản quyền.',
    'malware': 'Phần mềm độc hại hoặc link lừa đảo.',
    'offtopic': 'Lạc đề, không đúng nơi đăng.',
  };
  final lyDoKhac = 'Lý do khác…';
  final lyDoTuViet = 'Lý do thành viên sẽ đọc';
  final lyDoGuiThanhVien = 'Lý do gửi cho thành viên';
  final lyDoGuiThanhVienMoTa =
      'Thành viên nhận thông báo kèm lý do này, không thấy tên người xử lý.';
  final hanhDongViPham = const <String, String>{
    'REMOVE_CONTENT': 'Gỡ nội dung',
    'REMOVE': 'Gỡ bài',
    'ARCHIVE': 'Lưu trữ bài',
    'RESTORE': 'Khôi phục bài',
    'SUSPEND_USER': 'Tạm khóa',
    'BAN_USER': 'Cấm',
    'REINSTATE_USER': 'Mở khóa',
    'RESET_DECOR': 'Gỡ trang trí',
  };
  final lichSuViPhamCua = 'Lịch sử vi phạm của {name}';
  final xemLichSuViPham = 'Lịch sử vi phạm';
  final chuaTaiDuocLichSu = 'Chưa tải được lịch sử vi phạm.';
  final lanGoNoiDung = 'lần gỡ nội dung';
  final lanTamKhoa = 'lần tạm khóa';
  final lanCam = 'lần cấm';
  final lanGoTrangTri = 'lần gỡ trang trí';
  final chuaCoViPham = 'Chưa có vi phạm nào.';
  final khongGhiLyDo = 'Không ghi lý do.';
  final xuLyBoi = 'Xử lý bởi {name} (@{username})';
  final denNgay = 'đến {date}';
  final community = 'Cộng đồng';
  final timTheoTenHoacUsername = 'Tìm theo tên hoặc username';
  final vaiTro = 'Vai trò của {displayName}';
  final banNhap = 'Bản nháp';
  final daDang = 'Đã đăng';
  final daLuuTru = 'Đã lưu trữ';
  final daGo = 'Đã gỡ';
  final goBaiViet = 'Gỡ bài viết?';
  final luuTruBaiViet = 'Lưu trữ bài viết?';
  final khoiPhucBaiViet = 'Khôi phục bài viết?';
  final baiVietSeHienThi = 'Bài viết sẽ hiển thị công khai trở lại.';
  final baiVietSeKhongCon =
      'Bài viết sẽ bị ẩn khỏi mọi người. Admin vẫn khôi phục được bài đã đăng.';
  final goBai = 'Gỡ bài';
  final luuTru = 'Lưu trữ';
  final moderationTuTrangQuanTri = 'Kiểm duyệt từ trang quản trị';
  final chuaCapNhatDuocBai =
      'Chưa cập nhật được bài viết. Kiểm tra kết nối rồi thử lại.';
  final kiemDuyetNoiDung = 'Kiểm duyệt nội dung';
  final timBaiViet = 'Tìm bài viết';
  final timNoiDungHoacUsername = 'Tìm nội dung hoặc username';
  final trangThaiBaiViet = 'Trạng thái bài viết';
  final tatCaTrangThai = 'Mọi trạng thái';
  final chuaTaiDuocBaiViet = 'Chưa tải được bài viết.';
  final baiVietDinhKemAnh = 'Bài viết có ảnh đính kèm';
  final banNhapChuaCoNoi = 'Bản nháp trống';
  final luotThich = '@{username} · {likeCount} lượt thích';
  final khongCoBaiVietPhu = 'Không có bài viết nào khớp.';
  final hienThi100BaiCap =
      'Đang hiện 100 bài cập nhật gần nhất. Tìm kiếm hoặc lọc theo trạng thái để thu hẹp.';
  final daTaoVersionPointRules = 'Đã lưu phiên bản quy tắc tính điểm mới';
  final chuaTheLuuPointRules = 'Chưa lưu được quy tắc tính điểm';
  final batHeSoStreak = 'Bật hệ số streak?';
  final tatHeSoStreak = 'Tắt hệ số streak?';
  final xpMoiSeTiepTuc =
      'XP mới sẽ lại được nhân theo streak hiện tại. Điểm cũ không tính lại.';
  final xpMoiSeDung1 =
      'XP mới sẽ tính hệ số 1.00x. Streak, lịch điểm danh và streak dài nhất vẫn giữ nguyên.';
  final batHeSo = 'Bật hệ số';
  final tatHeSo = 'Tắt hệ số';
  final daBatHeSoStreak = 'Đã bật hệ số streak';
  final daTatHeSoStreak = 'Đã tắt hệ số streak';
  final chuaTheDoiCauHinh = 'Chưa đổi được hệ số streak';
  final gamification = 'Điểm thưởng';
  final diemHeSoStreak = 'Điểm & hệ số streak';
  final dangTat = 'Đang tắt';
  final dangBat = 'Đang bật';
  final nhanXpTheoChuoiStreak = 'Nhân XP theo streak';
  final khiTatHoatDongMoi =
      'Khi tắt, hoạt động mới vẫn được cộng điểm nhưng luôn tính 1.00x. Streak và lịch điểm danh không đổi.';
  final n3Ngay = '3 ngày';
  final n7Ngay = '7 ngày';
  final n14Ngay = '14 ngày';
  final n30Ngay = '30 ngày';
  final diemHoatDongV = 'Điểm hoạt động · v{version}';
  final thayDoiTaoVersionMoi =
      'Mỗi lần lưu tạo một phiên bản mới, không sửa điểm cũ. Góp ý và báo lỗi cách nhau ít nhất 10 phút mới được tính.';
  final luuVersion = 'Lưu phiên bản';
  final xpToiDa5Lan = 'XP · tối đa 5 lần/ngày';
  final xpToiDa2Lan = 'XP · tối đa 2 lần/ngày';
  final binhLuanCoNoiDung = 'Bình luận có nội dung';
  final xpToiDa15Lan = 'XP · tối đa 15 lần/ngày';
  final nhanLuotThich = 'Nhận lượt thích';
  final xpToiDa30Ngay = 'XP · tối đa 30/ngày';
  final guiGopY = 'Gửi góp ý';
  final diemGuiGopY = 'Điểm gửi góp ý';
  final xpToiDa3Lan = 'XP · tối đa 3 lần/ngày';
  final guiBaoLoi = 'Gửi báo lỗi';
  final diemGuiBaoLoi = 'Điểm gửi báo lỗi';
  final tamTatTrongMvp = 'Tạm tắt ở bản đầu';
}

final class ViAdminIcons {
  const ViAdminIcons._();
  final quanLyIcon = 'Quản lý icon';
  final moTa =
      'Icon vào kho ngay khi được tải lên. Xóa icon vi phạm và khóa người tải nếu cần.';
  final boLoc = 'Lọc icon';
  final locMoiNhat = 'Mới nhất';
  final locBiBaoCao = 'Bị báo cáo';
  final locDungNhieu = 'Dùng nhiều';
  final locDaXoa = 'Đã xóa';
  final timKiem = 'Tìm theo tên icon hoặc username người tải';
  final taiLenLuc = 'Tải lên {date}';
  final soBaoCao = '{count} báo cáo';
  final soNguoiDung = '{count} người dùng';
  final xoaIcon = 'Xóa icon';
  final xoaIconTieuDe = 'Xóa icon “{name}”';
  final lyDo = 'Lý do';
  final lyDoGoiY = 'Ví dụ: hình phản cảm, giả mạo logo';
  final xuLyNguoiTai = 'Người tải lên';
  final khongXuLyThem = 'Không xử lý thêm';
  final tamKhoa = 'Tạm khóa';
  final soNgayKhoa = 'Số ngày khóa';
  final khoaVinhVien = 'Cấm vĩnh viễn';
  final xoaMoiIconCuaNguoiNay = 'Xóa luôn mọi icon của người này';
  final daXoaIcon = 'Đã xóa icon';
  final chuaXoaDuocIcon = 'Chưa xóa được icon';
  final daXoaLuc = 'Đã xóa {date}: {reason}';
  final khongCoIcon = 'Không có icon nào.';
  final trangThaiNguoiTai = const <String, String>{
    'ACTIVE': 'Đang hoạt động',
    'SUSPENDED': 'Đang bị tạm khóa',
    'BANNED': 'Bị cấm',
    'PENDING_DELETION': 'Đang chờ xóa tài khoản',
  };
}

final class ViAdminVoiceViews {
  const ViAdminVoiceViews._();
  final communityVoice = 'Voice';
  final taoRoom = 'Tạo room';
  final roomDangMo = 'room đang mở';
  final participantDangKetNoi = 'người đang kết nối';
  final trangThaiVoiceRoom = 'Trạng thái voice room';
  final dangMo = 'Đang mở';
  final daLuuTru = 'Đã lưu trữ';
  final voiceToiDaNguoi = '/voice/{slug} · tối đa {capacity} người';
  final duaLen = 'Đưa {name} lên';
  final duaXuong = 'Đưa {name} xuống';
  final sua = 'Sửa {name}';
  final luuTru = 'Lưu trữ {name}';
  final chuaTheMoLaiRoom = 'Chưa mở lại được room';
  final dangMo2 = 'Đang mở…';
  final moLai = 'Mở lại';
  final khongCoRoomTrongTrang = 'Không có room nào ở trạng thái này.';
  final luuTru2 = 'Lưu trữ {name}?';
  final userSeKhongTheVao =
      'Thành viên sẽ không vào room được nữa. Ai đang trong room sẽ bị ngắt kết nối.';
  final roomDaChuyenSangMuc = 'Đã lưu trữ room';
  final chuaTheLuuTruRoom = 'Chưa lưu trữ được room';
  final dangLuuTru = 'Đang lưu trữ…';
  final luuTruRoom = 'Lưu trữ room';
  final dienDuTenSlugVa = 'Điền đủ tên, slug và mô tả room.';
  final sucChuaPhaiTu2 = 'Sức chứa phải từ 2 đến 250 người.';
  final slugDaDuocMotVoice = 'Slug này đã có room khác dùng.';
  final chuaTheLuuVoiceRoom =
      'Chưa lưu được room. Kiểm tra lại thông tin rồi thử lại.';
  final voiceAdmin = 'Quản lý room';
  final khongTimThayRoom = 'Không tìm thấy room.';
  final roomCoTheDaBi = 'Room có thể đã bị xóa khỏi dữ liệu cục bộ.';
  final danhSachRoom = 'Danh sách room';
  final voiceRoom = 'Voice room';
  final taoVoiceRoom = 'Tạo voice room';
  final cauHinhRoomCoDinh = 'Cài đặt room cố định';
  final roomLuonTonTaiThanh =
      'Room luôn mở sẵn. Thành viên bấm vào là vào room ngay, mic tắt sẵn.';
  final tenRoom = 'Tên room';
  final viDuSanhVnlf = 'Ví dụ: Sảnh VNLF';
  final slug = 'Slug';
  final sanhVnlf = 'sanh-vnlf';
  final roomDungDeNoiVe = 'Room này để nói về gì?';
  final sucChua = 'Sức chứa';
  final n2250Nguoi = '2–250 người';
  final quyenThamGia = 'Ai được vào';
  final moiThanhVien = 'Mọi thành viên';
  final mvpChuaHoTroRoom = 'Chưa hỗ trợ room riêng tư';
}

final class ViArticleEditor {
  const ViArticleEditor._();
  final vietMarkdown = 'Viết bằng Markdown';
  final veTrinhSoanThuong = 'Về trình soạn thường';
  final viet = 'Viết';
  final noiDungMarkdown = 'Nội dung bài bằng Markdown';
  final markdownGoiY =
      '**đậm**, *nghiêng*, ~~gạch~~, `code`, [link](https://…), # tiêu đề, - danh sách, > trích dẫn, ``` khối code';
  final khongChuyenMarkdown =
      'Bài có ảnh chèn giữa nội dung nên chưa chuyển sang Markdown được.';
  final buocHuongDan = 'Bước hướng dẫn';
  final buocSo = 'Bước {value}: ';
  final congDong = 'Cộng đồng';
  final banDangNghiGi = 'Bạn đang nghĩ gì?';
  final noiDungBaiViet = 'Nội dung bài';
  final moiBaiToiDa20 = 'Mỗi bài chèn được tối đa 20 ảnh.';
  final chuaTheTaiAnhLen = 'Chưa tải ảnh lên được. Thử lại sau.';
  final anhDangTaiLenVui = 'Ảnh đang tải lên, chờ chút nhé.';
  final dongBaiDangViet = 'Đóng bài đang viết?';
  final thayDoiMoiNhatChua =
      'Thay đổi mới nhất chưa được lưu. Đóng bây giờ có thể mất phần này.';
  final tiepTucViet = 'Tiếp tục viết';
  final dongBai = 'Đóng bài';
  final vietVaiDongHoacThem = 'Viết vài dòng hoặc thêm ảnh rồi hãy đăng.';
  final chuaTheDangBaiDraft = 'Chưa đăng được bài. Bản nháp vẫn được giữ lại.';
  final chuaTheXoaAnhKhoi = 'Chưa xóa được ảnh khỏi bản nháp.';
  final chuyenSangBaiThuong = 'Chuyển sang bài đăng thường?';
  final dinhDangChuVanDuoc =
      'Định dạng chữ vẫn giữ nguyên. Ảnh trong bài và ảnh bìa sẽ thành ảnh đính kèm; tiêu đề sẽ không hiện.';
  final chuyenSangBaiThuong2 = 'Chuyển sang bài thường';
  final giuArticle = 'Giữ Article';
  final taoBaiDang = 'Tạo bài đăng';
  final vietArticle = 'Viết Article';
  final tuLuuSau2Giay = 'Tự lưu sau 2 giây';
  final luuLoi = 'Chưa lưu được';
  final daLuuDraft = 'Đã lưu nháp';
  final draftMoi = 'Bản nháp mới';
  final vietBaiDaiArticle = 'Viết bài dài';
  final vietBaiDai = 'Viết bài dài';
  final article = '(Article)';
  final baiThuong = 'Bài thường';
  final soan = 'Soạn';
  final xemTruoc = 'Xem trước';
  final congKhai = 'Công khai';
  final tieuDeArticle = 'Tiêu đề bài';
  final chonAnhChenVaoBai = 'Chọn ảnh để chèn vào bài';
  final thaAnhVaoViTri = 'Thả ảnh vào vị trí này';
  final dangTaiAnh = 'Đang tải ảnh…';
  final themAnh = 'Thêm ảnh';
  final anh = '{count} ảnh';
  final keoThaDanHoacChon =
      'Kéo thả hoặc dán ảnh, video vào đây · ảnh tối đa 10MB, video tối đa 30 giây';
  final goiYHashtag = 'Gợi ý chủ đề';
  final themVideo = 'Thêm video';
  final chonVideo = 'Chọn video';
  final dangTaiVideo = 'Đang tải video…';
  final dangXuLyVideo = 'Đang xử lý…';
  final videoDangXuLyDangSau = 'Đang xử lý video. Xong là đăng được.';
  final motVideo = '1 video';
  final boVideo = 'Bỏ video';
  final moiBaiMotVideo = 'Mỗi bài chỉ có 1 video.';
  final articleChuaCoVideo =
      'Article chưa nhận video. Bỏ video trước khi chuyển sang viết bài dài.';
  final chuaTaiVideoLen = 'Chưa tải video lên được. Thử lại sau.';
  final videoSaiDinhDang = 'Chỉ nhận video MP4, MOV hoặc WebM.';
  final videoQuaLon = 'Video phải nhỏ hơn 200MB.';
  final videoQuaDai = 'Video dài hơn 30 giây. Cắt ngắn rồi thử lại nhé.';
  final videoKhongDocDuoc = 'Không đọc được video này. Thử video khác.';
  final videoLoi = 'Chưa xử lý được video. Bỏ video rồi thử lại.';
  final videoLoiNgan = 'Lỗi';
  final khongTaiDuoc = 'Không tải được {name}';
  final anhBia = 'Ảnh bìa';
  final thayAnh = 'Thay ảnh';
  final go = 'Gỡ';
  final themAnhBia = 'Thêm ảnh bìa';
  final jpgPngWebpHoacGif = 'JPG, PNG, WebP hoặc GIF';
  final chonAnhBia = 'Chọn ảnh bìa';
  final altTextAnhBia = 'Mô tả ảnh bìa (alt text)';
  final chuDeToiDa3 = 'Chủ đề · tối đa 3';
  final excerptTuyChon = 'Tóm tắt (không bắt buộc)';
  final moTaNganChoFeed =
      'Vài dòng giới thiệu hiện trên bảng tin và kết quả tìm kiếm…';
  final anhInline = '{imageCount} ảnh trong bài';
  final tu = '{count} từ';
  final daLuuNhap = 'Đã lưu nháp';
  final dangDang = 'Đang đăng…';
  final dang = 'Đăng';
  final doanVan = 'Đoạn văn';
  final dam = 'Đậm';
  final nghieng = 'Nghiêng';
  final lienKet = 'Liên kết';
  final danhSach = 'Danh sách';
  final danhSachSo = 'Danh sách số';
  final trichDan = 'Trích dẫn';
  final duongPhanCach = 'Đường phân cách';
  final anh2 = 'Ảnh';
  final hoanTac = 'Hoàn tác';
  final lamLai = 'Làm lại';
  final diaChiLienKet = 'Địa chỉ liên kết';
  final apDung = 'Áp dụng';
  final themBlock = 'Thêm khối';
  final headingLon = 'Tiêu đề lớn';
  final headingNho = 'Tiêu đề nhỏ';
  final codeBlock = 'Code block';
  final anhInline2 = 'Ảnh trong bài';
  final anhDinhKem = '{count} ảnh đính kèm';
  final anhDinhKem2 = 'Ảnh đính kèm {value}';
  final xoaAnh = 'Xóa ảnh {value}';
}

final class ViArticleImageNode {
  const ViArticleImageNode._();
  final chiHoTroJpgPng = 'Chỉ nhận ảnh JPG, PNG, WebP và GIF.';
  final keoAnh = 'Kéo để di chuyển ảnh';
  final khongTaiDuocAnh = 'Không tải được ảnh';
  final themChuThich = 'Thêm chú thích…';
  final chuThichAnh = 'Chú thích ảnh';
  final altTextChoAccessibilityVa =
      'Mô tả ảnh cho trình đọc màn hình và tìm kiếm';
  final altText = 'Mô tả ảnh';
  final kichThuoc = 'Kích thước';
  final vua = 'Vừa';
  final rong = 'Rộng';
  final toanKhung = 'Tràn khung';
  final chonAnhThayThe = 'Chọn ảnh thay thế';
  final thayAnh = 'Thay ảnh';
}

final class ViArticleRenderer {
  const ViArticleRenderer._();
  final anhKhongConTrongBo = 'Ảnh không còn trên máy này.';
  final saoChepCode = 'Sao chép code';
  final saoChep = 'Sao chép';
  final daChep = 'Đã chép';
  final chuaChepDuoc = 'Chưa chép được';
}

final class ViArticleTypes {
  const ViArticleTypes._();
  final baiVietMoi = 'Bài viết mới';
}

final class ViAvatarCrop {
  const ViAvatarCrop._();
  final trinhDuyetChuaHoTro = 'Trình duyệt của bạn chưa hỗ trợ xử lý ảnh.';
  final khongTheXuLyAnh = 'Không xử lý được ảnh này. Thử chọn ảnh khác.';
}

final class ViAvatarCropDialog {
  const ViAvatarCropDialog._();
  final anhQuaLonHoacKhong =
      'Ảnh quá lớn hoặc không đọc được. Chọn ảnh dưới 64 megapixel.';
  final khongDocDuocAnhHay =
      'Không đọc được ảnh. Chọn ảnh JPG, PNG, WebP hoặc GIF khác.';
  final chuaLuuDuocAnhGiu =
      'Chưa lưu được ảnh. Vùng cắt vẫn được giữ, bạn thử lại nhé.';
  final chinhAnhDaiDien = 'Chỉnh ảnh đại diện';
  final keoAnhDeChonVi = 'Kéo ảnh để căn vị trí, phóng to hoặc xoay rồi lưu.';
  final vungCatAnh = 'Vùng cắt ảnh';
  final xemTruocAnhDaiDien = 'Xem trước ảnh đại diện';
  final anhKhongKhaDung = 'Không hiển thị được ảnh';
  final dangDocAnh = 'Đang đọc ảnh…';
  final dungChuotChamKeoHoac =
      'Kéo bằng chuột, ngón tay hoặc dùng phím mũi tên để căn ảnh vào khung.';
  final dieuChinhAnh = 'Điều chỉnh ảnh';
  final phongTo = 'Phóng to';
  final thuNhoAnh = 'Thu nhỏ ảnh';
  final phongToAnh = 'Phóng to ảnh';
  final xoay90 = 'Xoay 90°';
  final datLai = 'Đặt lại';
  final dangLuuAnh = 'Đang lưu ảnh…';
  final luuAnh = 'Lưu ảnh';
}

final class ViChannelViews {
  const ViChannelViews._();
  final offline = 'offline';
  final thamGiaPhong = 'Vào room {name}';
  final restore = 'Khôi phục';
  final archive = 'Lưu trữ';
  final chuaCapNhatDuocMention =
      'Chưa cập nhật được lượt mention. Nhấn @ để thử lại.';
  final chiAdminSuaDuoc = 'Chỉ Admin sửa được channel';
  final chiAdminSuaDuocMoTa =
      'Bạn vẫn đọc và nhắn trong channel như bình thường.';
  final aiDuocNhan = 'Ai được nhắn';
  final moiThanhVien = 'Mọi thành viên';
  final moderatorTroLen = 'Moderator trở lên';
  final chiAdmin = 'Chỉ Admin';
  final channelChiDoc = 'Channel chỉ để đọc';
  final chiAdminNhanDuoc = 'Chỉ Admin đăng tin ở channel này.';
  final chiModeratorNhanDuoc = 'Chỉ Moderator và Admin đăng tin ở channel này.';
  final khongTimThayChannel = 'Không tìm thấy channel.';
  final channelKhongTonTaiDa =
      'Channel không tồn tại, đã được lưu trữ hoặc bạn không có quyền xem.';
  final danhSachChannel = 'Danh sách channel';
  final chuaCoChannelHoatDong = 'Chưa có channel nào hoạt động.';
  final adminCoTheTaoChannel =
      'Admin có thể tạo channel mới trong trang quản trị.';
  final chuaGuiDuocTinNhan = 'Chưa gửi được tin nhắn. Nội dung vẫn còn nguyên.';
  final baoCaoTinNhanTrong = 'Báo cáo tin nhắn trong #{name}';
  final daGuiBaoCao = 'Đã gửi báo cáo';
  final chuaTheGuiBaoCao = 'Chưa gửi được báo cáo';
  final linuxVietNam = 'Linux Việt Nam';
  final luotNhacHoacTraLoi =
      '{attentionCount} lượt mention hoặc trả lời chưa đọc';
  final tinChuaDoc = '{count} tin chưa đọc';
  final hayGiuKhongGianNay = 'Cùng giữ nơi này tử tế và hữu ích nhé.';
  final quayLaiDanhSachChannel = 'Quay lại danh sách channel';
  final xemThanhVien = 'Xem thành viên';
  final caiDatChannel = 'Cài đặt channel';
  final thongTinChannel = 'Thông tin channel';
  final xemThongTinChannel = 'Xem thông tin channel';
  final dongThongTinChannel = 'Đóng thông tin channel';
  final denTinNhanNhacDen = 'Đến tin nhắn mention bạn';
  final nhanVao = 'Nhắn vào #{name}';
  final chonAnhDinhKemChannel = 'Chọn ảnh đính kèm';
  final voiceDangHoatDong = 'Voice room đang mở';
  final nguoiDangKetNoi = '{participantCount} người đang kết nối';
  final thanhVienOnline = 'Đang online — {count}';
  final anCotThanhVien = 'Ẩn cột thành viên';
  final hienCotThanhVien = 'Hiện cột thành viên';
  final xemTatCaThanhVien = 'Xem tất cả';
  final khongTheTaoChannelKiem =
      'Chưa tạo được channel. Kiểm tra lại thông tin rồi thử lại.';
  final adminCommunitySpace = 'Quản trị · Channels';
  final tenChannel = 'Tên channel';
  final viDuKernelDrivers = 'Ví dụ: Kernel & Drivers';
  final slug = 'Slug';
  final channelNayDungDeTrao = 'Channel này để trao đổi về…';
  final dangTao = 'Đang tạo…';
  final thanhVienChannel = 'Thành viên channel';
  final quayLai = 'Quay lại';
  final dangOnline = 'đang online';
  final xemHoSo = 'Xem hồ sơ';
  final khongTheCapNhatChannel = 'Chưa cập nhật được channel.';
  final communityStructure = 'Channel cộng đồng';
  final channelsSlowModeS = '/channels/{name} · slow mode {slowMode}s';
  final duaLen = 'Đưa {label} lên';
  final duaXuong = 'Đưa {label} xuống';
  final sua = 'Sửa {label}';
  final slowMode = 'Slow mode';
  final tat = 'Tắt';
  final n5Giay = '5 giây';
  final n30Giay = '30 giây';
  final channelDangOTrangThai = 'Channel này đang được lưu trữ.';
  final daKhoiPhucChannel = 'Đã khôi phục channel';
  final daArchiveChannel = 'Đã lưu trữ channel';
  final daLuuCaiDatChannel = 'Đã lưu cài đặt channel';
}

final class ViChatPresentation {
  const ViChatPresentation._();
  final homQua = 'Hôm qua';
}

final class ViChatUi {
  const ViChatUi._();
  final chuaGuiDuoc = 'Chưa gửi được.';
  final boTin = 'Bỏ';
  final xemTinCuHon = 'Xem tin cũ hơn';
  final dangTaiTinCu = 'Đang tải tin cũ…';
  final tinNhanCua = 'Tin nhắn của {name}';
  final lichSuTinNhan = 'Lịch sử tin nhắn';
  final chuaTaiDuocTinNhan = 'Chưa tải được tin nhắn';
  final chuaCoTinNhanBat = 'Chưa có tin nhắn nào. Gửi lời chào đi!';
  final tinChuaDoc = '{unreadCount} tin chưa đọc';
  final nguoiDungDaChan = 'Người bạn đã chặn';
  final chuaTheCapNhatTin = 'Chưa cập nhật được tin nhắn. Thử lại nhé.';
  final ban = 'Bạn';
  final xemTinNhanCua = 'Xem tin nhắn của {name}';
  final daTraLoi = 'đã trả lời';
  final chinhMinh = 'chính mình';
  final ban2 = 'bạn';
  final anhTrongTinNhanCua = 'Ảnh trong tin nhắn của {name}';
  final xemHoSo = 'Xem hồ sơ {name}';
  final chinhSuaTinNhan = 'Sửa tin nhắn';
  final suaNoiDungTinNhan = 'Sửa nội dung tin nhắn';
  final daChinhSua = 'Đã chỉnh sửa';
  final bayToCamXuc = 'Thả cảm xúc';
  final traLoiTinNhan = 'Trả lời tin nhắn';
  final tuyChonTinNhan = 'Tùy chọn tin nhắn';
  final daGui = 'Đã gửi';
  final daXem = 'Đã xem';
  final traLoi = 'Trả lời';
  final thich = 'Thích';
  final daSaoChepTinNhan = 'Đã sao chép tin nhắn';
  final chuaTheSaoChepTin = 'Chưa sao chép được tin nhắn.';
  final saoChep = 'Sao chép';
  final tinNhanChiDuocSua = 'Chỉ sửa được tin nhắn trong 15 phút sau khi gửi';
  final hetThoiGianSua15 = 'Đã quá 15 phút, không sửa được nữa';
  final xoaTinNhan = 'Xóa tin nhắn?';
  final noiDungSeBiXoa =
      'Tin nhắn sẽ bị xóa khỏi cuộc trò chuyện và không khôi phục được.';
  final xoaTinNhan2 = 'Xóa tin nhắn';
  final xemAiDaThaCamXuc = 'Xem ai đã thả cảm xúc';
  final camXucVeTinNhan = 'Cảm xúc với tin nhắn';
  final luot = '{emoji}: {count} lượt';
  final luot2 = '{count} lượt';
  final coBan = ' · Có bạn';
  final vaNguoiKhac = 'và {count} người khác';
  final xemHoSoNguoiTha = 'Xem hồ sơ {name}';
  final chonAnhDinhKemTin = 'Chọn ảnh để gửi kèm';
  final nhacDenThanhVien = 'Mention thành viên';
  final goiYChannel = 'Gợi ý channel';
  final goiYEmoji = 'Gợi ý emoji';
  final xemChannel = 'Mở channel {name}';
  final traLoi2 = 'Trả lời {name}: {content}';
  final huyTraLoi = 'Hủy trả lời';
  final boGif = 'Bỏ GIF';
  final chonEmoji = 'Chọn emoji';
  final stickerVaGif = 'Sticker và GIF';
  final xemTruocDinhDang = 'Xem trước định dạng';
  final dinhKemAnh = 'Đính kèm ảnh';
  final enterDeGuiShiftEnter =
      'Enter để gửi · Shift+Enter để xuống dòng · Esc để hủy trả lời';
  final guiTinNhan = 'Gửi tin nhắn';
  final chuaTaiDuocAnh = 'Chưa tải được ảnh';
  final thaAnhVaoDay = 'Thả ảnh vào đây để gửi';
  final thaAnhGoiY = 'Tối đa {count} ảnh, mỗi ảnh dưới 10MB';
  final anhKhongHopLe = 'Chỉ gửi được ảnh JPG, PNG, WebP hoặc GIF dưới 10MB.';
  final toiDaAnh = 'Mỗi tin nhắn gửi kèm tối đa {count} ảnh.';
  final boAnh = 'Bỏ ảnh {name}';
  final xemAnhLon = 'Xem ảnh lớn';
  final anhTrongCuocTroChuyen = 'Ảnh trong cuộc trò chuyện';
  final danhSachAnh = 'Danh sách ảnh';
  final anhThu = 'Ảnh {value} / {count}';
  final dangGui = 'Đang gửi…';
  final taiLaiAnh = 'Tải lại ảnh';
  final slowModeCho = 'Slow mode · gửi tiếp sau {seconds}s';
  final slowModeConLai = 'Slow mode: còn {seconds} giây nữa mới gửi được';
  final xemTinNhanCoAnh = 'Xem tin nhắn có ảnh này';
  final anhDaGui = 'Ảnh đã gửi';
  final anhDaGuiMoTa = 'Mọi ảnh trong cuộc trò chuyện, mới nhất trước.';
  final dongAnhDaGui = 'Đóng ảnh đã gửi';
  final chuaTaiDuocAnhDaGui = 'Chưa tải được ảnh đã gửi';
  final chuaCoAnh = 'Chưa có ảnh nào';
  final chuaCoAnhMoTa = 'Ảnh gửi trong cuộc trò chuyện sẽ hiện ở đây.';
  final taiThemAnh = 'Tải thêm ảnh';
  final xemTatCaAnh = 'Xem tất cả';
  final anhCua = 'Ảnh {value} của {name}';
}

final class ViCommentsPanel {
  const ViCommentsPanel._();
  final ghim = 'Ghim';
  final boGhim = 'Bỏ ghim';
  final daGhim = 'Đã ghim';
  final chonAnhJpgPngWebp =
      'Chọn ảnh JPG, PNG, WebP hoặc GIF, mỗi ảnh tối đa 10MB.';
  final moiBinhLuanToiDa = 'Mỗi bình luận tối đa 10 ảnh.';
  final chuaTaiDuocBaiViet =
      'Chưa tải được bài nên chưa gửi được bình luận. Thử lại sau.';
  final chuaGuiDuocBinhLuan =
      'Chưa gửi được bình luận. Những gì bạn đã soạn vẫn còn.';
  final thaAnhVaoBinhLuan = 'Thả ảnh vào bình luận';
  final toiDa10Anh = 'Tối đa 10 ảnh';
  final thaoLuan = 'Thảo luận';
  final binhLuan = '{count} bình luận';
  final binhLuanDuocNhacDen = 'Bình luận này không còn nữa.';
  final dangTaiBinhLuan = 'Đang tải bình luận…';
  final chuaTaiDuocBinhLuan = 'Chưa tải được bình luận';
  final chuaCoBinhLuan = 'Chưa có bình luận';
  final moDauCuocThaoLuan = 'Hãy là người mở đầu.';
  final traLoi = 'Trả lời {displayName}';
  final huyTraLoi = 'Hủy trả lời';
  final anhDinhKemBinhLuan = 'Ảnh đính kèm';
  final anhBinhLuan = 'Ảnh bình luận {value}';
  final boAnh = 'Bỏ ảnh {value}';
  final noiDungBinhLuan = 'Nội dung bình luận';
  final vietBinhLuan = 'Viết bình luận…';
  final dangNhapDeBinhLuan = 'Đăng nhập để bình luận';
  final chonAnhBinhLuan = 'Chọn ảnh';
  final dinhKemAnhBinhLuan = 'Đính kèm ảnh';
  final guiBinhLuan = 'Gửi bình luận';
  final xoaBinhLuan = 'Xóa bình luận?';
  final binhLuanNaySeBi = 'Bình luận sẽ bị xóa và không khôi phục được.';
  final khongConGiSeXoa =
      'Bình luận không còn chữ, ảnh hay GIF nên sẽ bị xóa và không khôi phục được.';
  final xoaBinhLuan2 = 'Xóa bình luận';
  final chuaLuuDuocThayDoi = 'Chưa lưu được thay đổi. Thử lại nhé.';
  final xemHoSo = 'Xem hồ sơ {displayName}';
  final daSua = ' · Đã sửa';
  final suaBinhLuan = 'Sửa bình luận';
  final traLoi2 = 'Trả lời';
  final stickerVaGif = 'Sticker và GIF';
  final boGif = 'Bỏ GIF';
  final boSticker = 'Bỏ sticker';
  final gif = 'GIF';
  final sticker = 'Sticker';
}

final class ViCommunicationList {
  const ViCommunicationList._();
  final timKenhHoacNguoi = 'Tìm channel hoặc người';
  final thuGonChannel = 'Thu gọn danh sách channel';
  final moRongChannel = 'Mở danh sách channel';
  final khongCoChannel = 'Không có channel nào khớp.';
  final khongCoNguoi = 'Không có cuộc trò chuyện nào khớp.';
}

final class ViConfirm {
  const ViConfirm._();
  final xacNhan = 'Xác nhận';
}

final class ViContentVote {
  const ViContentVote._();
  final downvote = 'Downvote {label}';
  final upvote = 'Upvote {label}';
  final baiViet = 'bài';
  final binhLuan = 'bình luận';
  final chuaLuuDuocBinhChon = 'Chưa ghi nhận được bình chọn. Thử lại nhé.';
  final binhChon = 'Bình chọn {label}';
  final boUpvote = 'Bỏ upvote {label}';
  final diemBinhChon = 'Điểm bình chọn';
  final boDownvote = 'Bỏ downvote {label}';
}

final class ViLinkPreview {
  const ViLinkPreview._();
  final videoYoutube = 'Video YouTube';
  final phatVideo = 'Phát video {title}';
}

final class ViChannelSearch {
  const ViChannelSearch._();
  final timTrong = 'Tìm trong {name}';
  final chiTimTrongChannel = 'Chỉ tìm tin nhắn trong channel này.';
  final nguoiGui = 'Người gửi';
  final locTheoNguoiGui = 'Lọc theo người gửi';
  final goiYNguoiGui = 'Người đã nhắn trong channel';
  final khongThayNguoi = 'Không thấy ai đã nhắn ở đây với tên này.';
  final boLocNguoiGui = 'Bỏ lọc người gửi';
  final nhapHoacChonNguoi = 'Nhập ít nhất 2 ký tự hoặc chọn người gửi.';
  final moTimKiem = 'Tìm trong channel';
}

final class ViConversationSearch {
  const ViConversationSearch._();
  final soKetQuaGanNhat = '{count} kết quả gần nhất';
  final soKetQua = '{count} kết quả';
  final timTrongHoiThoai = 'Tìm trong cuộc trò chuyện';
  final chiTimTinNhanTrong = 'Chỉ tìm trong cuộc trò chuyện này.';
  final dongTimKiem = 'Đóng tìm kiếm';
  final tuKhoaTimTinNhan = 'Từ khóa';
  final nhapItNhat2Ky = 'Nhập ít nhất 2 ký tự';
  final xoaTuKhoa = 'Xóa từ khóa';
  final timLaiTinNhan = 'Tìm tin nhắn';
  final nhapItNhat2Ky2 = 'Nhập ít nhất 2 ký tự để bắt đầu.';
  final dangTim = 'Đang tìm…';
  final chuaTimDuocTinNhan = 'Chưa tìm được. Thử lại nhé.';
  final khongTimThayTinNhan = 'Không thấy tin nhắn nào khớp.';
}

final class ViDecor {
  const ViDecor._();
  final anhBia = 'Ảnh bìa';
  final anhBiaMoTa =
      'Tỉ lệ 3:1. Ảnh JPG, PNG, WebP tối đa 10MB, hoặc GIF tối đa 15 giây, 15MB.';
  final themAnhBia = 'Thêm ảnh bìa';
  final doiAnhBia = 'Đổi ảnh bìa';
  final goAnhBia = 'Gỡ ảnh bìa';
  final chonAnhBia = 'Chọn ảnh bìa';
  final daCapNhatAnhBia = 'Đã cập nhật ảnh bìa';
  final daGoAnhBia = 'Đã gỡ ảnh bìa';
  final chuaGoDuocAnhBia = 'Chưa gỡ được ảnh bìa. Thử lại sau.';
  final tepAnhBiaKhongHopLe =
      'Chọn ảnh JPG, PNG, WebP dưới 10MB, hoặc GIF dưới 15MB.';
  final chinhAnhBia = 'Chỉnh ảnh bìa';
  final keoDeChonPhanHien =
      'Kéo để chọn phần hiện trên ảnh bìa, phóng to nếu cần rồi lưu.';
  final vungCatAnhBia = 'Vùng cắt ảnh bìa';
  final xemTruocAnhBia = 'Xem trước ảnh bìa';
  final anhDongGiuChuyenDong =
      'GIF giữ chuyển động và chạy lặp lại. Xử lý mất vài giây.';
  final gifAvatarGiuChuyenDong =
      'Ảnh GIF giữ chuyển động trên trang cá nhân; ở bảng tin và chat hiện khung đầu tiên. Xử lý mất vài giây.';
  final dangTaiLen = 'Đang tải lên…';
  final dangXuLy = 'Đang xử lý…';
  final luuAnhBia = 'Lưu ảnh bìa';
  final xuLyLauHonDuKien =
      'Xử lý lâu hơn dự kiến. Ảnh sẽ tự cập nhật khi xong.';
  final tamDungAnhBia = 'Tạm dừng ảnh bìa';
  final phatAnhBia = 'Phát ảnh bìa';
  final dungAnhDong = 'Dừng ảnh động';
  final phatAnhDong = 'Phát ảnh động';
  final mauTen = 'Màu tên';
  final mauTenMoTa =
      'Mọi người thấy tên bạn với màu này ở bảng tin, bình luận, chat và voice. App tự chỉnh độ sáng để tên luôn dễ đọc trên nền sáng và nền tối.';
  final kieuMau = 'Kiểu màu';
  final macDinh = 'Mặc định';
  final motMau = 'Một màu';
  final haiMau = 'Hai màu';
  final mauThu = 'Màu {n}';
  final dangChinhMau = 'Đang chỉnh';
  final gocChuyenMau = 'Góc chuyển màu';
  final mauGoiY = 'Màu gợi ý';
  final dungGanDay = 'Dùng gần đây';
  final maMau = 'Mã màu';
  final maMauKhongHopLe = 'Nhập mã màu dạng #RRGGBB.';
  final layMauTrenManHinh = 'Lấy màu trên màn hình';
  final doDamVaDoSang = 'Độ đậm và độ sáng';
  final doDamDoSangGiaTri = 'Độ đậm {s}%, độ sáng {v}%';
  final sacDo = 'Sắc độ';
  final xemTruoc = 'Xem trước';
  final nenSang = 'Nền sáng';
  final nenToi = 'Nền tối';
  final xemTruocBangTin = 'Bảng tin';
  final xemTruocChat = 'Chat';
  final xemTruocThanhVien = 'Thành viên';
  final cauMau = 'Vừa cài xong Arch Linux.';
  final vuaXong = 'vừa xong';
  final chinhTrenNenSang =
      'Trên nền sáng, màu được chỉnh thành {hex} để dễ đọc.';
  final chinhTrenNenToi = 'Trên nền tối, màu được chỉnh thành {hex} để dễ đọc.';
  final chuaLuuDuocTrangTri = 'Chưa lưu được trang trí. Thử lại sau.';
  final trangTriDangBiKhoa = 'Trang trí đang bị khóa tới {date}.';
  final theme = 'Theme';
  final mauNhan = 'Màu nhấn';
  final theoTheme = 'Theo theme';
  final tuChon = 'Tự chọn';
  final hinhNen = 'Hình nền';
  final hinhNenMoTa =
      'Ảnh JPG, PNG, WebP tối đa 10MB, hoặc GIF tối đa 15 giây. Hình nền phủ cả trang, phía sau các thẻ.';
  final chuaCoHinhNen = 'Chưa có hình nền';
  final taiHinhNen = 'Tải hình nền';
  final doiHinhNen = 'Đổi hình nền';
  final chonHinhNen = 'Chọn hình nền';
  final tepHinhNenKhongHopLe =
      'Chọn ảnh JPG, PNG, WebP dưới 10MB, hoặc GIF dưới 15MB.';
  final daCapNhatHinhNen = 'Đã cập nhật hình nền';
  final chuaGoDuocHinhNen = 'Chưa gỡ được hình nền. Thử lại sau.';
  final doToi = 'Độ tối';
  final doMo = 'Độ mờ';
  final kieuHinhNen = 'Kiểu hiển thị';
  final phuKin = 'Phủ kín';
  final lapO = 'Lặp ô';
  final coDinh = 'Cố định khi cuộn';
  final xemTren = 'Xem trên';
  final mayTinh = 'Máy tính';
  final dienThoai = 'Điện thoại';
  final xemTruocNha = 'Xem trước trang cá nhân';
  final tenTheme = const <String, String>{
    'vnlf': 'VNLF',
    'nord': 'Nord',
    'gruvbox': 'Gruvbox',
    'dracula': 'Dracula',
    'catppuccin': 'Catppuccin',
    'solarized': 'Solarized',
    'tokyoNight': 'Tokyo Night',
    'ubuntu': 'Ubuntu',
    'fedora': 'Fedora',
    'arch': 'Arch',
    'debian': 'Debian',
    'terminal': 'Terminal',
  };
  final nhac = 'Nhạc';
  final nhacMoTa =
      'Dán link một video YouTube. Video tự phát nhưng tắt tiếng; khách bấm để bật tiếng.';
  final linkYoutube = 'Link YouTube';
  final batDauTuGiay = 'Bắt đầu từ giây';
  final lapLai = 'Phát lặp lại';
  final goNhac = 'Gỡ nhạc';
  final daGoNhac = 'Đã gỡ nhạc';
  final nhacCua = 'Nhạc của @{username}';
  final batTieng = 'Bật tiếng';
  final tatTieng = 'Tắt tiếng';
  final phatNhac = 'Phát nhạc';
  final trenYoutube = 'trên YouTube';
  final videoKhongPhatDuoc = 'Video này không phát được. Hãy chọn video khác.';
  final doiNhac = 'Đổi nhạc';
  final chuaCoNhac = 'Chưa có nhạc';
  final trangThai = 'Trạng thái';
  final trangThaiMoTa =
      'Một emoji và một câu ngắn hiện cạnh tên bạn ở thẻ hồ sơ, danh sách thành viên và tin nhắn.';
  final emojiTrangThai = 'Emoji';
  final noiDungTrangThai = 'Bạn đang làm gì?';
  final noiDungTrangThaiGoiY = 'Đang build kernel…';
  final tuXoaSau = 'Tự xóa sau';
  final motGio = '1 giờ';
  final motNgay = '1 ngày';
  final motTuan = '1 tuần';
  final khongTuXoa = 'Không tự xóa';
  final xoaTrangThai = 'Xóa trạng thái';
  final hetHanLuc = 'Hết hạn {time}';
  final mayCuaToi = 'Máy của tôi';
  final mayCuaUser = 'Máy của @{username}';
  final xoaThongTinMay = 'Xóa thông tin máy';
  final dotfilesGoiY = 'https://github.com/…';
  final truongMay = const <String, String>{
    'os': 'OS',
    'kernel': 'Kernel',
    'de': 'DE',
    'wm': 'WM',
    'shell': 'Shell',
    'terminal': 'Terminal',
    'editor': 'Editor',
    'cpu': 'CPU',
    'gpu': 'GPU',
    'dotfiles': 'Dotfiles',
  };
  final ghimBai = 'Ghim bài';
  final ghimBaiMoTa = 'Chọn tối đa 3 bài hiện trên đầu trang cá nhân.';
  final daGhim = 'Đã ghim';
  final chuaCoBaiDeGhim = 'Bạn chưa có bài đăng công khai.';
  final toiDaBaBai = 'Chỉ ghim được tối đa 3 bài.';
  final xemTrangCaNhan = 'Xem trang cá nhân';
  final levelSo = 'Level {level}';
  final theHoSo = 'Thẻ hồ sơ của @{username}';
  final dongTheHoSo = 'Đóng thẻ hồ sơ';
  final trangNguoiKhac = 'Trang cá nhân của người khác';
  final trangNguoiKhacMoTa =
      'Chọn cách bạn xem phần trang trí của người khác. Trang của bạn luôn hiện đúng như bạn trang trí.';
  final anhDong = 'Ảnh động (avatar, ảnh bìa, hình nền)';
  final anhDongTuDong = 'Tự động';
  final anhDongTuDongMoTa =
      'Chạy ở mọi nơi; đứng yên khi bật Giảm chuyển động hoặc Tiết kiệm dữ liệu';
  final anhDongReChuot = 'Khi rê chuột';
  final anhDongKhong = 'Không bao giờ';
  final hienHinhNen = 'Hiện hình nền và theme của người khác';
  final nhacTrangCaNhan = 'Nhạc trang cá nhân';
  final nhacTuPhat = 'Tự phát, tắt tiếng';
  final nhacKhiBam = 'Chỉ phát khi bấm';
  final nhacTat = 'Tắt';
  final tuBatTieng = 'Tự bật tiếng nhạc khi trình duyệt cho phép';
  final hienMauTen = 'Hiện màu tên, icon và hiệu ứng tên của người khác';
  final hienHieuUng = 'Hiện hiệu ứng vào nhà, thú cưng và hiệu ứng tên động';
  final tietKiemDuLieu = 'Tiết kiệm dữ liệu';
  final tietKiemDuLieuMoTa =
      'Không tải ảnh động, hình nền và YouTube cho tới khi bạn bấm';
  final mau = const <String, String>{
    'red': 'Đỏ',
    'orange': 'Cam',
    'amber': 'Hổ phách',
    'leaf': 'Lá',
    'jade': 'Ngọc',
    'sky': 'Trời',
    'blue': 'Dương',
    'indigo': 'Chàm',
    'purple': 'Tím',
    'pink': 'Hồng',
    'brown': 'Nâu',
    'slate': 'Xám xanh',
  };
  final loi = const <String, String>{
    'DECOR_FLASHING': 'Ảnh nhấp nháy hơn 3 lần mỗi giây nên không dùng được: có thể gây co giật cho người nhạy cảm với ánh sáng. Hãy chọn ảnh khác.',
    'DECOR_TOO_LONG': 'GIF dài quá 15 giây. Hãy cắt ngắn rồi tải lại.',
    'DECOR_TOO_MANY_FRAMES':
        'GIF có hơn 300 khung hình. Hãy chọn GIF ngắn hơn.',
    'DECOR_TOO_HEAVY': 'GIF quá nặng sau khi xử lý. Hãy chọn GIF ngắn hơn hoặc ít chi tiết hơn.',
    'DECOR_INVALID': 'Không đọc được tệp này. Hãy thử tệp khác.',
    'DECOR_REPLACED': 'Ảnh này đã được thay bằng ảnh bạn tải lên sau.',
    'DECOR_MODERATED': 'Trang trí của bạn vừa bị gỡ hoặc đang bị khóa, nên ảnh này không được dùng.',
  };
}

final class ViDailyCheckin {
  const ViDailyCheckin._();
  final diemDanhHangNgay = 'Điểm danh hằng ngày';
  final chucMungBanDaDang =
      'Tuyệt! Bạn đã đăng nhập {currentStreak} ngày liên tiếp. Mai ghé lại để giữ streak nhé.';
  final ngayLienTiep = 'ngày liên tiếp';
  final xemLichHoatDong = 'Xem lịch hoạt động';
  final tiepTuc = 'Tiếp tục';
}

final class ViDialog {
  const ViDialog._();
  final dongHopThoai = 'Đóng hộp thoại';
}

final class ViDirectMessageLiveView {
  const ViDirectMessageLiveView._();
  final chuaGuiDuocTinNhan = 'Chưa gửi được tin nhắn. Nội dung vẫn còn nguyên.';
  final chuaCoHoiThoai = 'Chưa có cuộc trò chuyện nào';
  final moHoSoMotThanh = 'Vào hồ sơ một thành viên để gửi lời mời nhắn tin.';
  final daChanNguoiDungVa = 'Đã chặn và khóa cuộc trò chuyện';
  final chuaTheChanNguoiDung = 'Chưa chặn được. Thử lại sau.';
  final daBoChanCanGui = 'Đã bỏ chặn. Gửi lại lời mời để nhắn tin tiếp.';
  final chuaTheBoChanNguoi = 'Chưa bỏ chặn được. Thử lại sau.';
  final daGuiLaiYeuCau = 'Đã gửi lại lời mời nhắn tin';
  final chuaTheGuiYeuCau = 'Chưa gửi được lời mời nhắn tin';
  final baoCaoTinNhan = 'Báo cáo tin nhắn {id}';
  final daGuiBaoCao = 'Đã gửi báo cáo';
  final chuaTheGuiBaoCao = 'Chưa gửi được báo cáo';
  final tinNhanRieng = 'Tin nhắn riêng';
  final timCuocTroChuyen = 'Tìm cuộc trò chuyện';
  final chapNhan = 'Đồng ý nhắn tin với {displayName}';
  final tuChoi = 'Từ chối {displayName}';
  final chuaCoTinNhan = 'Chưa có tin nhắn';
  final quayLaiDanhSachTin = 'Quay lại danh sách tin nhắn';
  final veDanhSachTinNhan = 'Về danh sách tin nhắn';
  final xemHoSo = 'Xem hồ sơ {displayName}';
  final chuaRoTrangThai = 'Chưa rõ trạng thái';
  final dangHoatDong = 'Đang hoạt động';
  final ngoaiTuyen = 'Không hoạt động';
  final timTrongCuocTroChuyen = 'Tìm trong cuộc trò chuyện';
  final moTuyChonHoiThoai = 'Mở tùy chọn cuộc trò chuyện';
  final vietTinNhan = 'Viết tin nhắn…';
  final hoiThoaiDaBiKhoa = 'Cuộc trò chuyện đã bị khóa';
  final boChanDeGuiLai = 'Bỏ chặn để gửi lại lời mời.';
  final boChan = 'Bỏ chặn';
  final canGuiYeuCau = 'Cần gửi lời mời';
  final daGuiLoiMoi = 'Đã gửi lời mời nhắn tin';
  final nhanTiepKhiChapNhan = 'Bạn nhắn tiếp được khi {name} chấp nhận.';
  final nguoiKiaPhaiChapNhan =
      'Người kia cần đồng ý thì hai bạn mới nhắn tin được.';
  final guiYeuCau = 'Gửi lời mời';
  final tuyChonHoiThoai = 'Tùy chọn cuộc trò chuyện';
  final xemTrangCaNhan = 'Xem trang cá nhân';
  final baoCaoTuGiaoDien = 'Báo cáo từ cuộc trò chuyện';
  final daGuiBaoCaoHoi = 'Đã báo cáo cuộc trò chuyện';
  final chuaTheGuiBaoCao2 = 'Chưa báo cáo được cuộc trò chuyện';
}

final class ViError {
  const ViError._();
  final coLoiXayRa = 'Có lỗi rồi';
  final trangChuaTaiDuoc = 'Chưa tải được trang.';
  final thuTaiLaiNeuLoi =
      'Thử tải lại trang. Nếu vẫn lỗi, gửi báo lỗi để đội ngũ kiểm tra.';
  final chuaTaiDuocNoiDung = 'Chưa tải được nội dung.';
  final shellVaDieuHuongVan =
      'Bạn vẫn dùng được menu và điều hướng. Thử tải lại phần này nhé.';
}

final class ViStickers {
  const ViStickers._();
  final tieuDe = 'Sticker';
  final boStickerCuaBan = 'Bộ sticker của bạn';
  final moTa =
      'Tạo bộ sticker từ ảnh, GIF hoặc video ngắn rồi chia sẻ link, hoặc gửi lên chợ sticker, để mọi người thêm vào khay của họ, như Telegram.';
  final taoBo = 'Tạo bộ sticker';
  final tenBo = 'Tên bộ';
  final tenBoGoiY = 'Ví dụ: Mèo VNLF';
  final tao = 'Tạo';
  final chuaCoBo =
      'Bạn chưa có bộ sticker nào. Đặt tên rồi bấm Tạo để bắt đầu.';
  final themSticker = 'Thêm sticker';
  final themStickerMoTa =
      'PNG, JPG, WebP, GIF hoặc video WebM/MP4, tối đa 10MB. Nền trong suốt được giữ nguyên; sticker động dài tối đa 3 giây. Có thể kéo thả nhiều tệp.';
  final dangXuLy = 'Đang xử lý';
  final loi = const <String, String>{
    'STICKER_INVALID': 'Không đọc được tệp này.',
    'STICKER_TOO_LONG': 'Sticker động dài tối đa 3 giây.',
    'STICKER_TOO_HEAVY':
        'Tệp vẫn quá nặng sau khi nén. Thử bản ngắn hoặc nhỏ hơn.',
    'STICKER_TOO_MANY_FRAMES': 'Ảnh động có quá nhiều khung hình.',
  };
  final chuaTaiLenDuoc = 'Chưa tải lên được {name}.';
  final emojiCuaSticker = 'Emoji của sticker {position}: {emoji}';
  final doiEmoji = 'Bấm để chọn emoji khác';
  final xoaSticker = 'Xoá sticker {position}';
  final xoaBo = 'Xoá bộ';
  final xacNhanXoaBo =
      'Xoá bộ "{title}"? Bộ sẽ biến khỏi khay của mọi người; tin nhắn đã gửi vẫn giữ sticker.';
  final tenBoMoi = 'Tên bộ {title}';
  final saoChepLink = 'Sao chép link';
  final daSaoChep = 'Đã sao chép link bộ sticker.';
  final soSticker = '{count} sticker';
  final soNguoiThem = '{count} người đã thêm';
  final cuaNguoiTao = 'của {name}';
  final themVaoKhay = 'Thêm bộ sticker';
  final daThem = 'Đã thêm vào khay';
  final boKhoiKhay = 'Bỏ khỏi khay';
  final boDaThem = 'Bộ đã thêm';
  final chuaThemBoNao =
      'Bạn chưa thêm bộ của ai. Bấm vào sticker trong chat để xem và thêm bộ của nó.';
  final dangNhapDeThem = 'Đăng nhập để thêm';
  final moTrangBo = 'Mở trang bộ sticker';
  final baoCaoBo = 'Báo cáo bộ sticker';
  final daGuiBaoCao = 'Đã gửi báo cáo bộ sticker. Cảm ơn bạn.';
  final boDaBiAn = 'Bộ sticker này đã bị ẩn sau báo cáo.';
  final stickerDaBiAn = 'Sticker đã bị ẩn';
  final boTrong = 'Bộ này chưa có sticker.';
  final quanLy = 'Tạo và quản lý sticker';
  final stickerCuaBan = 'Sticker của bạn';
  final stickerKlipy = 'Sticker KLIPY';
  final xemBo = 'Xem bộ sticker {title}';
  final khongTimThayBo = 'Không tìm thấy bộ sticker này.';
  final chuaTaiDuoc = 'Chưa tải được sticker.';
  final daCapNhat = 'Đã lưu.';
  final chuaLuuDuoc = 'Chưa lưu được. Thử lại sau ít phút.';
  final choSticker = 'Chợ sticker';
  final boCuaToi = 'Bộ của tôi';
  final daThemTab = 'Đã thêm';
  final cacMuc = 'Các mục sticker';
  final choMoTa =
      'Bộ sticker do thành viên tạo, đã qua moderator duyệt. Thêm cả bộ vào khay, hoặc mở bộ để lưu riêng từng sticker.';
  final timTrenCho = 'Tìm bộ sticker';
  final sapXep = 'Sắp xếp bộ sticker';
  final phoBien = 'Phổ biến';
  final moi = 'Mới';
  final choTrong =
      'Chợ chưa có bộ nào. Gửi bộ của bạn lên chợ ở tab Bộ của tôi nhé.';
  final khongCoBoKhop = 'Không có bộ nào khớp. Thử từ khóa khác nhé.';
  final xemThem = 'Xem thêm';
  final cuaBan = 'Bộ của bạn';
  final coTrenCho = 'Có trên chợ sticker';
  final trangThaiDuyet = const <String, String>{
    'NONE': 'Chưa lên chợ',
    'PENDING': 'Đang chờ duyệt',
    'APPROVED': 'Đang có trên chợ',
    'REJECTED': 'Chưa được duyệt',
  };
  final guiLenCho = 'Gửi lên chợ sticker';
  final guiLenChoMoTa =
      'Moderator xem bộ trước khi đưa lên chợ để mọi người tìm thấy và thêm.';
  final canItNhatMotSticker = 'Thêm ít nhất 1 sticker rồi gửi lên chợ nhé.';
  final daGuiDuyet = 'Đã gửi bộ lên chợ. Moderator sẽ xem sớm.';
  final rutLai = 'Rút lại';
  final goKhoiCho = 'Gỡ khỏi chợ';
  final xacNhanGoKhoiCho =
      'Gỡ "{title}" khỏi chợ sticker? Người đã thêm vẫn giữ bộ; muốn lên chợ lại thì gửi duyệt lại.';
  final seDuyetLai = 'Thêm sticker hoặc đổi tên thì bộ sẽ được duyệt lại.';
  final ghiChuModerator = 'Moderator ghi chú:';
  final stickerDaLuu = 'Sticker đã lưu';
  final luuSticker = 'Lưu sticker {position}';
  final bamDeLuu =
      'Bấm vào một sticker để lưu riêng nó vào Sticker đã lưu, dùng được ở mọi khung chat.';
  final boLuuSticker = 'Bỏ lưu sticker {title}';
  final chuaLuuSticker =
      'Bạn chưa lưu sticker nào. Mở một bộ rồi bấm vào sticker để lưu.';
  final xong = 'Xong';
}

final class ViProjects {
  const ViProjects._();
  final tieuDe = 'Dự án';
  final moTaTrang =
      'Dự án do cộng đồng VNLF làm và giới thiệu: app, công cụ, theme, bộ gõ… Làm gì hay ho thì đăng lên cho mọi người cùng xem nhé.';
  final metaMoTa =
      'Dự án mã nguồn mở do cộng đồng Linux Việt Nam làm và giới thiệu, cùng các dự án của Vietnam Linux Family.';
  final dangDuAn = 'Đăng dự án';
  final vnlf = 'Vietnam Linux Family';
  final loai = const <String, String>{
    'APP': 'Ứng dụng',
    'TOOL': 'Công cụ & script',
    'LIBRARY': 'Thư viện',
    'DISTRO': 'Distro & hệ điều hành',
    'CUSTOMIZE': 'Theme & dotfiles',
    'EXTENSION': 'Extension & plugin',
    'VIETNAMESE': 'Tiếng Việt',
    'SYSTEM': 'Hệ thống & phần cứng',
    'SELFHOST': 'Self-host & DevOps',
    'GAME': 'Game',
    'LEARNING': 'Tài liệu & học tập',
    'OTHER': 'Khác',
  };
  final loaiMoTa = const <String, String>{
    'APP': 'App desktop, web hoặc điện thoại',
    'TOOL': 'CLI, TUI, script tự động hoá',
    'LIBRARY': 'Library, framework, SDK',
    'DISTRO': 'Distro, bản phối, ISO',
    'CUSTOMIZE': 'Dotfiles, rice, theme, icon, wallpaper',
    'EXTENSION':
        'Extension GNOME/KDE, plugin Neovim/VS Code, add-on trình duyệt',
    'VIETNAMESE': 'Bộ gõ, font, bản dịch, từ điển',
    'SYSTEM': 'Driver, kernel, firmware, embedded, IoT',
    'SELFHOST': 'Server, homelab, Docker, mirror',
    'GAME': 'Game, mod, giả lập',
    'LEARNING': 'Hướng dẫn, sách, awesome list, đồ án',
    'OTHER': 'Không thuộc loại nào ở trên',
  };
  final quanHe = const <String, String>{
    'AUTHOR': 'Tác giả',
    'MAINTAINER': 'Cùng phát triển',
    'CONTRIBUTOR': 'Có đóng góp',
    'SHARED': 'Giới thiệu',
  };
  final sapXep = const <String, String>{
    'featured': 'Mặc định',
    'new': 'Mới duyệt',
    'stars': 'Nhiều star',
    'rating': 'Đánh giá cao',
    'updated': 'Mới cập nhật',
    'trending': 'Đang lên',
  };
  final tier = const <String, String>{
    'VNLF': 'Dự án của VNLF',
    'PARTNER': 'Đối tác',
    'COMMUNITY': 'Tự do',
  };
  final tierTieuDe = const <String, String>{
    'VNLF': 'Dự án của VNLF',
    'PARTNER': 'Đối tác',
    'COMMUNITY': 'Dự án tự do',
  };
  final tierMoTa = const <String, String>{
    'VNLF': 'Do Vietnam Linux Family làm và duy trì.',
    'PARTNER': 'Dự án của các đối tác đồng hành cùng VNLF.',
    'COMMUNITY': 'Thành viên tự làm hoặc giới thiệu.',
  };
  final tierNhan = const <String, String>{'VNLF': 'VNLF', 'PARTNER': 'Đối tác'};
  final danhGia = 'Đánh giá';
  final soDanhGia = '{count} đánh giá';
  final chuaCoDanhGia = 'Chưa có đánh giá';
  final diemTrenNam = '{average} trên 5 điểm, {count} đánh giá';
  final danhGiaCuaBan = 'Đánh giá của bạn';
  final soSao = '{count} sao';
  final boDanhGia = 'Bỏ đánh giá';
  final daDanhGia = 'Đã lưu đánh giá.';
  final daBoDanhGia = 'Đã bỏ đánh giá.';
  final chuaDanhGiaDuoc = 'Chưa lưu được đánh giá. Thử lại sau ít phút.';
  final dangNhapDeDanhGia = 'Đăng nhập để đánh giá';
  final khongTuDanhGia = 'Đây là dự án của bạn nên bạn không tự đánh giá được.';
  final phanBoDanhGia = 'Số đánh giá theo số sao';
  final dongPhanBo = '{stars} sao: {count} đánh giá';
  final soLieuGithub = 'Số liệu trên GitHub';
  final sapXepLabel = 'Sắp xếp';
  final theLoai = 'Thể loại';
  final tatCaTheLoai = 'Mọi thể loại';
  final ngonNgu = 'Ngôn ngữ';
  final tatCaNgonNgu = 'Mọi ngôn ngữ';
  final timNguoiDongGop = 'Tìm người đóng góp';
  final timKiem = 'Tìm dự án';
  final timKiemGoiY = 'Tên, mô tả, topic, ngôn ngữ…';
  final boLoc = 'Lọc dự án';
  final demTheLoai = '{label} ({count})';
  final trong = 'Chưa có dự án nào. Bạn làm gì hay ho thì đăng lên nhé!';
  final trongLoc = 'Không có dự án nào khớp bộ lọc.';
  final trongDangLen = 'Tuần này chưa có dự án nào tăng star.';
  final xemThem = 'Xem thêm';
  final chuaTaiDuoc = 'Chưa tải được danh sách dự án. Thử lại sau ít phút.';
  final soStar = '{count} star';
  final soFork = '{count} fork';
  final soContributor = '{count} contributor';
  final soIssue = '{count} issue mở';
  final soPr = '{count} PR mở';
  final soWatcher = '{count} người theo dõi';
  final soLuotTai = '{count} lượt tải';
  final starTuanNay = '+{count} star tuần này';
  final truoc = '{time} trước';
  final vuaXong = 'vừa xong';
  final capNhat = 'Cập nhật {time}';
  final dangLaySoLieu = 'Đang lấy số liệu từ GitHub…';
  final nhan = const <String, String>{
    'featured': 'Nổi bật',
    'seeking': 'Tìm người đóng góp',
    'archived': 'Đã lưu trữ',
    'inactive': 'Ít hoạt động',
    'fork': 'Fork từ {repo}',
    'noLicense': 'Chưa có license',
    'unknownLicense': 'License chưa rõ',
    'unavailable': 'Repo không còn công khai',
    'noSource': 'Không có mã nguồn công khai',
  };
  final giaiThichLicense =
      'Chưa có license thì về luật, người khác chưa được dùng lại, sửa hay chia sẻ code. Thêm file LICENSE là xong (xem choosealicense.com).';
  final giaiThichLicenseChuaRo =
      'GitHub chưa nhận ra license của repo, có thể là license tự viết.';
  final dangBoi = 'Đăng bởi';
  final gioiThieuBoi = 'Giới thiệu bởi';
  final xemGithub = 'Xem trên GitHub';
  final taiBan = 'Tải {tag}';
  final chiaSe = 'Chia sẻ';
  final daSaoChepLink = 'Đã sao chép link dự án.';
  final chiaSeTieuDe = 'Chia sẻ dự án';
  final chiaSeMoTa = 'Gửi cho bạn bè hoặc đăng lên mạng xã hội.';
  final chiaSeKhac = 'Khác';
  final email = 'Email';
  final linkDuAn = 'Link dự án';
  final saoChep = 'Sao chép';
  final daChep = 'Đã chép';
  final chuaChepDuoc = 'Chưa sao chép được. Chọn link rồi nhấn Ctrl+C.';
  final sua = 'Sửa';
  final lamMoi = 'Làm mới số liệu';
  final daLamMoi = 'Đã yêu cầu làm mới. Số liệu cập nhật sau ít giây.';
  final baoCao = 'Báo cáo dự án';
  final daGuiBaoCao = 'Đã gửi báo cáo. Moderator sẽ xem sớm.';
  final lyDoMaoNhan = 'Mạo nhận dự án của người khác';
  final lyDoMaDoc = 'Phần mềm độc hại';
  final lyDoSai = 'Thông tin sai';
  final xoa = 'Xoá dự án';
  final xoaXacNhan =
      'Xoá dự án "{name}"? Dự án biến khỏi VNLF; bài giới thiệu trên bảng tin vẫn giữ.';
  final daXoa = 'Đã xoá dự án.';
  final chuaXoaDuoc = 'Chưa xoá được dự án. Thử lại sau ít phút.';
  final tuyChon = 'Tuỳ chọn dự án';
  final quayLai = 'Tất cả dự án';
  final gioiThieu = 'Giới thiệu';
  final anhChup = 'Ảnh chụp màn hình';
  final xemAnh = 'Ảnh {index} của {name}';
  final thaoLuan = 'Thảo luận';
  final thaoLuanMoTa = 'Bình luận dưới bài giới thiệu dự án trên bảng tin.';
  final moBaiThaoLuan = 'Mở bài giới thiệu';
  final soBinhLuan = '{count} bình luận';
  final thongTin = 'Thông tin';
  final nguoiDang = 'Người đăng';
  final contributor = 'Contributor';
  final vaNguoiKhac = 'và {count} người khác';
  final hoatDong = 'Hoạt động 52 tuần';
  final soCommit = '{count} commit trong 52 tuần';
  final lichSuStar = 'Star theo ngày';
  final lichSuStarMoTa = '{from} → {to}: {start} → {end} star';
  final lienKet = 'Liên kết';
  final topic = 'Topic';
  final license = 'License';
  final taoRepo = 'Tạo repo';
  final pushCuoi = 'Push lần cuối';
  final banPhatHanh = 'Bản phát hành';
  final repo = 'Repo';
  final canGi = 'Cần giúp';
  final goodFirstIssue = 'Xem issue trên GitHub';
  final linkLoai = const <String, String>{
    'WEBSITE': 'Website',
    'DOCS': 'Tài liệu',
    'DOWNLOAD': 'Tải về',
    'AUR': 'AUR',
    'FLATHUB': 'Flathub',
    'CHAT': 'Nhóm chat',
    'VIDEO': 'Video',
    'REPO': 'Repo liên quan',
    'OTHER': 'Link',
  };
  final choDuyet = 'Dự án đang chờ duyệt. Có kết quả mình báo bạn ngay.';
  final biTuChoi = 'Dự án chưa được duyệt: {note}';
  final biTuChoiGoiY = 'Sửa lại rồi gửi lại nhé.';
  final thayDoiChoDuyet =
      'Bạn có thay đổi đang chờ duyệt. Mọi người vẫn thấy bản cũ tới khi được duyệt.';
  final thayDoiBiTuChoi = 'Thay đổi lần trước chưa được duyệt: {note}';
  final biAn =
      'Dự án đang bị ẩn sau khi kiểm duyệt. Chỉ bạn và moderator thấy trang này.';
  final repoMat =
      'GitHub báo không còn thấy repo này. Số liệu dừng ở lần cập nhật cuối.';
  final trangThai = const <String, String>{
    'PENDING': 'Chờ duyệt',
    'APPROVED': 'Đã duyệt',
    'REJECTED': 'Chưa được duyệt',
    'HIDDEN': 'Đã ẩn',
    'DELETED': 'Đã xoá',
  };
  final tabDuAn = 'Dự án';
  final chuaCoDuAn = 'Chưa có dự án nào.';
  final chuaCoDuAnCuaBan = 'Bạn chưa đăng dự án nào.';
  final duAnNoiBat = 'Dự án nổi bật';
  final xemTatCa = 'Xem tất cả';
  final khac = 'Khác';
  final dangDuAnTieuDe = 'Đăng dự án';
  final suaDuAnTieuDe = 'Sửa dự án';
  final moTaForm = 'Dự án hiện ở trang Dự án sau khi moderator duyệt.';
  final luuYSua =
      'Đổi tên, mô tả, giới thiệu, ảnh hay link thì moderator duyệt lại; trong lúc đó mọi người vẫn thấy bản cũ.';
  final canDangNhap = 'Đăng nhập để đăng dự án.';
  final linkRepo = 'Link repo GitHub';
  final linkRepoGoiY = 'https://github.com/ten-ban/du-an';
  final linkRepoMoTa =
      'Dán link là tự điền tên, mô tả và lấy số star, fork, contributor.';
  final linkRepoKhongDoi = 'Dự án đã duyệt thì không đổi repo được.';
  final khongCoRepo = 'Dự án không có repo công khai';
  final khongCoRepoMoTa =
      'Cần ít nhất một link, ví dụ website hoặc trang tải về.';
  final dangHoiGithub = 'Đang hỏi GitHub…';
  final linkChuaDung =
      'Link chưa đúng. Dán link repo GitHub, ví dụ https://github.com/VN-Linux-Family/CaramOS.';
  final canhBao = const <String, String>{
    'fork': 'Repo này là fork của {parent}.',
    'archived': 'Repo đã lưu trữ (archived).',
    'empty': 'Repo còn trống.',
    'noLicense': 'Repo chưa có license.',
  };
  final daCoTrenVnlf = 'Repo này đã có trên VNLF: {name}.';
  final xemDuAn = 'Xem dự án';
  final ten = 'Tên dự án';
  final moTaNgan = 'Mô tả ngắn';
  final moTaNganGoiY = 'Một câu nói dự án làm gì';
  final gioiThieuLabel = 'Giới thiệu';
  final gioiThieuGoiY =
      'Dự án làm gì, dành cho ai, cài và dùng thế nào… Viết bằng Markdown.';
  final gioiThieuDem = 'Ít nhất {min} ký tự · {count}/{max}';
  final theLoaiGoiY = 'Gợi ý theo topic của repo: {type}';
  final lienKetLabel = 'Liên kết';
  final loaiLink = 'Loại link';
  final themLink = 'Thêm link';
  final xoaLink = 'Xoá link';
  final logo = 'Logo';
  final logoMoTa =
      'Ảnh vuông, kéo thả hoặc bấm vào ô để chọn. Để trống thì dùng avatar chủ repo.';
  final chonLogo = 'Chọn logo';
  final xoaLogo = 'Bỏ logo';
  final anhChupMoTa =
      'Tối đa {count} ảnh PNG, JPG, WebP hoặc GIF, mỗi ảnh tối đa 10MB.';
  final themAnh = 'Thêm ảnh';
  final xoaAnh = 'Xoá ảnh';
  final dangTaiAnh = 'Đang tải ảnh…';
  final chuaTaiAnhDuoc =
      'Chưa tải ảnh lên được. Thử ảnh khác hoặc thử lại sau.';
  final timNguoiDongGopLabel = 'Đang tìm người đóng góp';
  final canGiGoiY =
      'Cần gì? Ví dụ: dịch tiếng Việt, test trên Fedora, thiết kế icon';
  final dangBaiGioiThieu = 'Đăng bài giới thiệu lên bảng tin khi được duyệt';
  final dangBaiGioiThieuMoTa =
      'Bình luận dưới bài là phần Thảo luận của dự án.';
  final xemTruoc = 'Thẻ dự án sẽ hiện thế này';
  final guiDuyet = 'Gửi duyệt';
  final guiLai = 'Gửi lại';
  final luuThayDoi = 'Lưu thay đổi';
  final dangGui = 'Đang gửi…';
  final daGui = 'Đã gửi. Dự án chờ moderator duyệt.';
  final daLuu = 'Đã lưu.';
  final daGuiThayDoi =
      'Đã gửi thay đổi. Mọi người vẫn thấy bản cũ tới khi được duyệt.';
  final chuaLuuDuoc = 'Chưa lưu được dự án. Thử lại sau ít phút.';
  final tenMacDinh = 'Tên dự án';
  final moTaMacDinh = 'Mô tả ngắn của dự án';
  final cacBuoc = const <(String, String)>[
    ('Cơ bản', 'Thông tin chính'),
    ('Chi tiết', 'Liên kết, cộng đồng'),
    ('Hoàn tất', 'Xem lại và gửi'),
  ];
  final cacBuocLabel = 'Các bước đăng dự án';
  final phuDeForm =
      'Chia sẻ dự án bạn làm, hoặc dự án hay bạn biết, với cộng đồng.';
  final tiepTuc = 'Tiếp tục';
  final quayLaiBuoc = 'Quay lại';
  final chuaXongBuoc = 'Bước này còn chỗ chưa xong, xem các dòng chữ đỏ.';
  final phanCoBan = 'Thông tin cơ bản';
  final phanCoBanMoTa = 'Bạn đăng với tư cách nào và mã nguồn nằm ở đâu.';
  final phanHienThi = 'Hiện trên trang dự án';
  final phanHienThiMoTa = 'Ai xem dự án cũng thấy những thông tin này.';
  final phanGioiThieu = 'Giới thiệu và hình ảnh';
  final phanGioiThieuMoTa = 'Kể về dự án và cho mọi người xem nó chạy thế nào.';
  final phanLienKetMoTa =
      'Website, tài liệu, trang tải, AUR, Flathub, nhóm chat…';
  final phanCongDong = 'Cộng đồng';
  final phanCongDongMoTa = 'Rủ thêm người cùng làm dự án.';
  final phanXemLai = 'Xem lại và gửi';
  final phanXemLaiMoTa = 'Kiểm tra lần cuối trước khi gửi moderator duyệt.';
  final tuCach = 'Bạn đăng dự án với tư cách nào?';
  final tuCachMoTa = 'Gửi rồi vẫn sửa lại được.';
  final cuaToi = 'Dự án của tôi';
  final cuaToiMoTa = 'Tôi làm hoặc cùng làm dự án này';
  final gioiThieuNguoiKhac = 'Giới thiệu dự án';
  final gioiThieuNguoiKhacMoTa =
      'Dự án hay của người khác mà tôi muốn mọi người biết';
  final vaiTro = 'Vai trò của bạn';
  final canChonTuCach = 'Chọn bạn đăng với tư cách nào.';
  final canLinkRepo =
      'Dán link repo GitHub, hoặc chọn Dự án không có repo công khai.';
  final xoaLinkRepo = 'Xoá link repo';
  final daLayTuGithub = 'Đã lấy thông tin từ GitHub.';
  final repoTomTat = '{repo} · {stars} star';
  final tenMoTa = 'Ngắn, dễ nhớ, không kèm mô tả.';
  final moTaNganMoTa = 'Một câu nói dự án làm gì, không lặp lại tên.';
  final demKyTu = '{count}/{max}';
  final canTen = 'Nhập tên dự án.';
  final canMoTaNgan = 'Nhập một câu nói dự án làm gì.';
  final theLoaiMoTa = 'Giúp người xem lọc ra dự án của bạn.';
  final chonTheLoai = 'Chọn thể loại';
  final chonTheLoaiMoTa = 'Tìm hoặc chọn loại hợp nhất với dự án của bạn.';
  final timTheLoai = 'Tìm thể loại';
  final timTheLoaiGoiY = 'Ví dụ: dotfiles, bộ gõ, server…';
  final khongCoTheLoai = 'Không có thể loại nào khớp.';
  final goiY = 'Gợi ý';
  final canTheLoai = 'Chọn thể loại.';
  final gioiThieuNenCo = 'Giới thiệu nên có gì';
  final gioiThieuNenCoMoTa = 'Không cần dài, trả lời được mấy ý này là đủ:';
  final goiYGioiThieu = const <(String, String)>[
    ('Dự án là gì', 'Một câu: dự án làm gì, thuộc loại nào.'),
    ('Giải quyết chuyện gì', 'Vì sao bạn làm, nó giúp được ai việc gì.'),
    ('Tính năng chính', 'Ba tới năm điểm nổi bật.'),
    ('Dành cho ai', 'Nói cụ thể, tránh kiểu dành cho tất cả mọi người.'),
    ('Cài và dùng thế nào', 'Distro, desktop chạy được và các bước cài.'),
  ];
  final daHieu = 'Đã hiểu';
  final canGioiThieu = 'Giới thiệu cần ít nhất {min} ký tự.';
  final anhChupTieuDe = 'Ảnh chụp màn hình ({count}/{max})';
  final hoacKeoTha = 'hoặc kéo thả vào đây';
  final thaAnhVaoDay = 'Thả ảnh vào đây';
  final chiNhanAnh =
      'Chỉ nhận ảnh PNG, JPG, WebP hoặc GIF, mỗi ảnh tối đa 10MB.';
  final duAnh = 'Đã đủ {count} ảnh. Xoá bớt rồi thêm ảnh khác.';
  final doiAnhTaiXong = 'Đợi ảnh tải lên xong.';
  final canMotLink = 'Dự án không có repo công khai cần ít nhất một link.';
  final linkKhongDung =
      'Link chưa đúng, cần bắt đầu bằng http:// hoặc https://.';
  final timNguoiDongGopMoTa =
      'Thẻ và trang dự án hiện nhãn Tìm người đóng góp.';
  final tomTat = const <String, String>{
    'relation': 'Tư cách',
    'repo': 'Repo',
    'type': 'Thể loại',
    'media': 'Ảnh chụp',
    'links': 'Liên kết',
    'seeking': 'Tìm người đóng góp',
  };
  final khongCoRepoNgan = 'Không có repo công khai';
  final soLink = '{count} link';
  final soAnh = '{count} ảnh';
  final co = 'Có';
  final khongCo = 'Không';
  final suaMuc = 'Sửa {label}';
  final sauKhiGui =
      'Moderator xem dự án trước khi nó hiện ở trang Dự án. Có kết quả bạn sẽ nhận thông báo.';
  final huongDan = 'Hướng dẫn đăng dự án';
  final moTaFormGioiHan =
      'Dự án hiện ở trang Dự án sau khi moderator duyệt. Mỗi ngày bạn gửi được tối đa {count} lần.';
  final meoDang = 'Mẹo đăng dự án';
  final meo = const <(String, String)>[
    (
      'Dán link GitHub trước',
      'Form tự điền tên, mô tả, thể loại; star, fork, contributor tự cập nhật mỗi ngày.',
    ),
    (
      'Tên gọn, mô tả một câu',
      'Người xem lướt danh sách chỉ đọc tên và mô tả ngắn.',
    ),
    (
      'Ảnh chụp thật',
      'Giao diện hay lúc chạy trong terminal, nhìn là hiểu dự án làm gì.',
    ),
    (
      'Có link tải thì thêm',
      'Website, AUR, Flathub, AppImage… để người xem dùng thử ngay.',
    ),
    ('Cần người phụ?', 'Bật Tìm người đóng góp và ghi rõ cần gì.'),
  ];
  final nenTranh = 'Nên tránh';
  final tranh = const <String>[
    'Spam, quảng cáo, hoặc nhận dự án của người khác là của mình.',
    'Giới thiệu chung chung, chép nguyên README hay để AI viết mà không đọc lại.',
    'Ảnh mờ, không liên quan tới dự án.',
    'Link hỏng, repo trống.',
  ];
}

final class ViAdminProjects {
  const ViAdminProjects._();
  final tieuDe = 'Duyệt dự án';
  final moTa =
      'Dự án thành viên gửi lên. Duyệt thì dự án hiện ở trang Dự án; từ chối thì người đăng đọc được ghi chú của bạn.';
  final tab = const <String, String>{
    'PENDING': 'Chờ duyệt',
    'CHANGES': 'Thay đổi chờ duyệt',
    'APPROVED': 'Đã duyệt',
    'REJECTED': 'Từ chối',
    'HIDDEN': 'Đã ẩn',
  };
  final trong = const <String, String>{
    'PENDING': 'Không có dự án nào chờ duyệt.',
    'CHANGES': 'Không có thay đổi nào chờ duyệt.',
    'APPROVED': 'Chưa có dự án nào được duyệt.',
    'REJECTED': 'Không có dự án nào bị từ chối.',
    'HIDDEN': 'Không có dự án nào bị ẩn.',
  };
  final tabDem = '{label} ({count})';
  final boLoc = 'Lọc dự án';
  final timKiem = 'Tìm theo tên dự án, repo hoặc username';
  final duyet = 'Duyệt';
  final tuChoi = 'Từ chối';
  final duyetThayDoi = 'Duyệt thay đổi';
  final tuChoiThayDoi = 'Từ chối thay đổi';
  final an = 'Ẩn dự án';
  final boAn = 'Bỏ ẩn';
  final noiBat = 'Chọn nổi bật';
  final boNoiBat = 'Bỏ nổi bật';
  final loaiDuAn = 'Loại dự án';
  final lamMoi = 'Làm mới số liệu';
  final chuyenChu = 'Chuyển chủ dự án';
  final chuyenChuMoTa =
      'Người nhận sửa được dự án từ giờ. Dùng khi tác giả thật nhận lại dự án người khác đã giới thiệu.';
  final usernameNguoiNhan = 'Username người nhận';
  final doiLoai = 'Đổi thể loại';
  final ghiChu = 'Ghi chú cho người đăng';
  final ghiChuMoTa = 'Người đăng đọc được ghi chú này.';
  final ghiChuGoiY = 'Ví dụ: thêm ảnh chụp màn hình, mô tả rõ dự án làm gì';
  final ghiChuLanTruoc = 'Ghi chú lần trước';
  final lyDoMau = const <String>[
    'Repo còn trống.',
    'Trùng với dự án đã có.',
    'Chưa rõ dự án làm gì, bạn thêm mô tả nhé.',
    'Fork chưa có thay đổi đáng kể.',
    'Chưa liên quan tới cộng đồng Linux hay mã nguồn mở Việt.',
    'Dự án của người khác nhưng ghi là của bạn.',
    'Vi phạm nội quy cộng đồng.',
  ];
  final lyDoAn = 'Lý do ẩn';
  final anMoTa =
      'Dự án biến khỏi trang Dự án và trang cá nhân; người khác mở link thì báo không tìm thấy. Bỏ ẩn được ở tab Đã ẩn.';
  final tuChoiTieuDe = 'Từ chối "{name}"';
  final tuChoiThayDoiTieuDe = 'Từ chối thay đổi của "{name}"';
  final anTieuDe = 'Ẩn "{name}"';
  final chuyenChuTieuDe = 'Chuyển chủ "{name}"';
  final boAnMoTa = 'Bỏ ẩn "{name}"? Dự án hiện lại như trước khi bị ẩn.';
  final daDuyet = 'Đã duyệt. Dự án đã lên trang Dự án.';
  final daTuChoi = 'Đã từ chối và gửi ghi chú cho người đăng.';
  final daDuyetThayDoi = 'Đã duyệt thay đổi.';
  final daTuChoiThayDoi = 'Đã từ chối thay đổi và gửi ghi chú cho người đăng.';
  final daAn = 'Đã ẩn dự án.';
  final daBoAn = 'Đã bỏ ẩn dự án.';
  final daLuu = 'Đã lưu.';
  final daLamMoi = 'Đã yêu cầu làm mới số liệu.';
  final chuaLuuDuoc = 'Chưa lưu được. Thử lại sau ít phút.';
  final chuaTaiDuoc = 'Chưa tải được danh sách. Thử lại sau ít phút.';
  final xemTrang = 'Xem trang dự án';
  final kiemTra = 'Kiểm tra tự động';
  final canhBao = const <String, String>{
    'noRepo': 'Không có repo công khai',
    'missing': 'GitHub không thấy repo',
    'pending': 'Chưa lấy được số liệu từ GitHub',
    'fork': 'Fork của {parent}',
    'archived': 'Repo đã lưu trữ',
    'empty': 'Repo trống',
    'noLicense': 'Chưa có license',
    'unknownLicense': 'License chưa rõ',
    'old': 'Không push hơn 12 tháng',
    'newAccount': 'Tài khoản mới tạo {days} ngày',
    'reports': '{count} báo cáo chưa xử lý',
  };
  final khongCoGiDangLuuY = 'Không có gì cần lưu ý.';
  final nguoiDang = 'Người đăng';
  final thongTinNguoiDang =
      'Level {level} · tham gia {date} · {approved} dự án đã duyệt, {rejected} bị từ chối';
  final guiLuc = 'Gửi duyệt {date}';
  final thayDoiLuc = 'Gửi thay đổi {date}';
  final xuLyLuc = 'Xử lý {date}';
  final xuLyBoi = 'Xử lý {date} · {name}';
  final anLuc = 'Ẩn {date}';
  final thayDoi = 'Thay đổi chờ duyệt';
  final truoc = 'Hiện tại';
  final sau = 'Sau khi duyệt';
  final truong = const <String, String>{
    'name': 'Tên',
    'tagline': 'Mô tả ngắn',
    'intro': 'Giới thiệu',
    'type': 'Thể loại',
    'relation': 'Quan hệ',
    'links': 'Liên kết',
    'logo': 'Logo',
    'media': 'Ảnh chụp',
    'seekingNote': 'Cần giúp',
  };
  final khongDoi = 'Không đổi';
  final githubConLuot =
      'GitHub: còn {remaining}/{limit} lượt đến {time}. Số liệu mỗi dự án cập nhật một lần mỗi ngày.';
  final githubChuaRo = 'GitHub: chưa hỏi lần nào trong giờ này.';
  final repoGithub = 'Repo GitHub';
  final lichSu = 'Lịch sử duyệt';
  final levelThamGia = 'Level {level} · tham gia {date}';
  final lichSuNguoiDang = '{approved} dự án đã duyệt · {rejected} bị từ chối';
  final soLieuLay = 'Số liệu lấy {time}';
  final anhChupDem = 'Ảnh chụp ({count})';
  final themThaoTac = 'Thêm thao tác';
  final caiDatDuAn = 'Cài đặt dự án';
}

final class ViAdminStickers {
  const ViAdminStickers._();
  final tieuDe = 'Duyệt sticker';
  final moTa =
      'Bộ sticker thành viên gửi lên chợ. Duyệt thì bộ hiện trên chợ; từ chối hoặc gỡ khỏi chợ thì người tạo đọc được ghi chú của bạn.';
  final trangKiemDuyet = 'Các trang kiểm duyệt';
  final boLoc = 'Lọc bộ sticker';
  final tab = const <String, String>{
    'PENDING': 'Chờ duyệt',
    'APPROVED': 'Đã duyệt',
    'REJECTED': 'Từ chối',
    'HIDDEN': 'Đã ẩn',
  };
  final tabDem = '{label} ({count})';
  final timKiem = 'Tìm theo tên bộ hoặc username người tạo';
  final trong = const <String, String>{
    'PENDING': 'Không có bộ nào chờ duyệt.',
    'APPROVED': 'Chưa có bộ nào trên chợ.',
    'REJECTED': 'Không có bộ nào bị từ chối.',
    'HIDDEN': 'Không có bộ nào bị ẩn.',
  };
  final soLuotLuu = '{count} lượt lưu';
  final dangXuLy = '{count} sticker đang xử lý';
  final guiLuc = 'Gửi duyệt {date}';
  final xuLyLuc = 'Xử lý {date}';
  final xuLyBoi = 'Xử lý {date} · {name}';
  final anLuc = 'Ẩn {date}';
  final ghiChu = 'Ghi chú';
  final ghiChuLanTruoc = 'Ghi chú lần trước';
  final ghiChuGoiY = 'Ví dụ: ảnh mờ, chữ khó đọc, trùng bộ khác';
  final ghiChuMoTa = 'Người tạo đọc được ghi chú này.';
  final lyDoAn = 'Lý do ẩn';
  final anMoTa =
      'Bộ biến khỏi mọi khay và khỏi chợ; tin nhắn cũ hiện "Sticker đã bị ẩn". Bỏ ẩn được ở tab Đã ẩn.';
  final duyet = 'Duyệt';
  final tuChoi = 'Từ chối';
  final goKhoiCho = 'Gỡ khỏi chợ';
  final anBo = 'Ẩn bộ';
  final boAn = 'Bỏ ẩn';
  final tuChoiTieuDe = 'Từ chối "{title}"';
  final goKhoiChoTieuDe = 'Gỡ "{title}" khỏi chợ';
  final anBoTieuDe = 'Ẩn "{title}"';
  final boAnMoTa =
      'Bỏ ẩn "{title}"? Bộ trở lại khay của người đã thêm và lên chợ lại nếu đã được duyệt.';
  final daDuyet = 'Đã duyệt. Bộ đã lên chợ.';
  final daTuChoi = 'Đã từ chối và gửi ghi chú cho người tạo.';
  final daGoKhoiCho = 'Đã gỡ bộ khỏi chợ.';
  final daAn = 'Đã ẩn bộ sticker.';
  final daBoAn = 'Đã bỏ ẩn bộ sticker.';
  final chuaTaiDuoc = 'Chưa tải được danh sách. Thử lại sau ít phút.';
}

final class ViFeedbackThread {
  const ViFeedbackThread._();
  final tieuDe = 'Góp ý {reference}';
  final thaoLuan = 'Thảo luận';
  final doiVnlf = 'Đội VNLF';
  final ban = 'Bạn';
  final chuaCoTinNhan =
      'Chưa có tin nhắn. Bạn có thể bổ sung thông tin hoặc hỏi lại đội VNLF ở đây.';
  final chuaCoTinNhanStaff =
      'Chưa có tin nhắn. Hỏi thêm người gửi hoặc báo họ cách xử lý ở đây; họ nhận được thông báo.';
  final vietTinNhan = 'Viết tin nhắn cho đội VNLF…';
  final traLoiNguoiGui = 'Nhắn cho người gửi…';
  final gui = 'Gửi';
  final ctrlEnterDeGui = 'Ctrl+Enter để gửi';
  final chuaGuiDuoc = 'Chưa gửi được tin nhắn. Thử lại sau ít phút.';
  final chuaTaiDuoc = 'Chưa tải được cuộc thảo luận.';
  final khachKhongNhanDuoc =
      'Người gửi là khách (không đăng nhập) nên không nhắn qua đây được.';
  final dangNhapDeXem = 'Đăng nhập để xem góp ý của bạn.';
  final khongTimThay = 'Không tìm thấy góp ý này, hoặc nó không phải của bạn.';
  final noiDungGopY = 'Nội dung bạn gửi';
  final tepDinhKem = '{count} tệp đính kèm';
  final xemVaTraLoi = 'Xem và trả lời';
  final soTinNhan = '{count} tin nhắn';
  final vnlfDaTraLoi = 'VNLF đã trả lời';
  final choTraLoi = 'Chờ trả lời';
  final luc = '{time}';
  final tinNhanCua = 'Tin nhắn của {name}';
  final tatCaGopY = 'Tất cả góp ý của bạn';
}

final class ViFeedbackWidget {
  const ViFeedbackWidget._();
  final demTep = '{count}/5 tệp';
  final ticket = 'Ticket';
  final taoTicket = 'Tạo ticket';
  final lichSu = 'Lịch sử';
  final lichSuTicket = 'Ticket đã gửi';
  final xemLichSu = 'Xem lịch sử';
  final xpChoTicketDau = ' · XP tính cho {limit} ticket đầu mỗi ngày';
  final moTaTicket =
      'Gặp lỗi thì kể bạn đã làm gì và thấy gì. Có ý tưởng thì nói bạn muốn VNLF tốt hơn ở đâu.';
  final chiNhanAnhHoacVideo =
      'Chỉ nhận ảnh JPG, PNG, WebP, GIF hoặc video MP4, WebM.';
  final dangNhapDeTheoDoi =
      'Đăng nhập để xem lại các ticket đã gửi và trạng thái của chúng.';
  final chuaTaiDuocLichSu = 'Chưa tải được lịch sử ticket.';
  final chuaCoTicket = 'Bạn chưa gửi ticket nào.';
  final thongBaoKhiCapNhat =
      'Khi ticket đổi trạng thái, bạn sẽ nhận được thông báo.';
  final guiLuc = 'Gửi {time}';
  final capNhatLuc = ' · cập nhật {time}';
  final trangThai = const <String, String>{
    'OPEN': 'Chờ xem',
    'IN_REVIEW': 'Đang xem',
    'RESOLVED': 'Đã xử lý',
    'CLOSED': 'Đã đóng',
    'DEFERRED': 'Để làm sau',
  };
  final demKyTu = '{count}/4000 · ít nhất 20 ký tự';
  final daNhanKemTep =
      'Mã theo dõi của bạn: {reference}. VNLF đã nhận góp ý kèm {attachments}.';
  final chuaTaiDuocTepThu = 'Chưa tải lên được tệp. Thử lại hoặc bỏ tệp này.';
  final anhToiDa10mb = '{name}: ảnh tối đa 10MB.';
  final videoToiDa50mb = '{name}: video tối đa 50MB.';
  final moiLanGuiToiDa = 'Mỗi lần gửi tối đa 5 tệp.';
  final chiThemTepDeKhong = 'Chỉ thêm được {available} tệp nữa (tối đa 5 tệp).';
  final chuaGuiDuocNoiDung =
      'Chưa gửi được. Nội dung và tệp vẫn còn, bạn thử lại nhé.';
  final gopYHoacBaoLoi = 'Góp ý hoặc báo lỗi';
  final gopY = 'Góp ý';
  final baoLoi = 'Báo lỗi';
  final daGhiNhan = 'Đã ghi nhận';
  final giupVnlfTotHon = 'Giúp VNLF tốt hơn';
  final camOnBanDaGui = 'Cảm ơn bạn đã gửi phản hồi.';
  final tepDinhKem = '{count} tệp đính kèm';
  final thongTinTrangHienTai = 'thông tin trang hiện tại';
  final xpDangDuocXuLy =
      'XP đang được cộng theo quy tắc tính điểm, giới hạn mỗi ngày và';
  final heSoStreakHienTai = 'hệ số streak hiện tại';
  final muc100x = 'hệ số 1.00x';
  final phieuDuocLuuDuoiDang =
      'Phản hồi được lưu dưới dạng khách. Không cần đăng nhập, đội ngũ vẫn xử lý bình thường.';
  final hoanTat = 'Hoàn tất';
  final guiBang = 'Gửi bằng @{username}';
  final coTheNhanXpCo = 'Có thể nhận +{points} XP';
  final guiKhongCanDangNhap = 'Gửi không cần đăng nhập';
  final emailTuyChonChiDung = 'Email không bắt buộc, chỉ dùng khi cần hồi âm';
  final hinhAnhHoacVideo = 'Ảnh hoặc video';
  final khongBatBuoc = 'không bắt buộc';
  final chonAnhHoacVideoDinh = 'Chọn ảnh hoặc video đính kèm';
  final keoThaAnhHoacVideo = 'Kéo thả, dán (Ctrl+V) hoặc chọn ảnh, video';
  final jpgPngWebpGifToi =
      'JPG, PNG, WebP, GIF tối đa 10MB · MP4/WebM tối đa 50MB';
  final tepDinhKem2 = 'Tệp đính kèm';
  final anhDinhKem = 'Ảnh đính kèm {value}';
  final dangTai = 'Đang tải lên';
  final sanSang = 'Sẵn sàng';
  final loiTai = 'Tải lên lỗi';
  final thuLai = 'Thử lại {name}';
  final bo = 'Bỏ {name}';
  final emailLienHe = 'Email liên hệ';
  final banExampleCom = 'ban@example.com';
  final trangHienTai = 'Trang hiện tại';
  final dangXuLyTep = 'Đang xử lý tệp…';
  final guiChoVnlf = 'Gửi cho VNLF';
}

final class ViFeedViews {
  const ViFeedViews._();
  final dangLamMoi = 'Đang làm mới bảng tin…';
  final congDong = 'Cộng đồng';
  final articlePhutDoc = 'Article · {Math} phút đọc';
  final locBangTin = 'Lọc bảng tin';
  final moiNhat = 'Mới nhất';
  final article = 'Article';
  final duocChuY = 'Được chú ý';
  final dangTheoDoi = 'Đang theo dõi';
  final homNayBanMuonChia = 'Hôm nay bạn muốn chia sẻ điều gì?';
  final chuaCoBaiViet = 'Chưa có bài nào';
  final hayTheoDoiThanhVien =
      'Theo dõi vài thành viên hoặc viết bài đầu tiên của bạn.';
  final dangTaiThem = 'Đang tải thêm…';
  final cuonDeXemBaiCu = 'Cuộn để xem bài cũ hơn';
  final banDaXemHetFeed = 'Bạn đã xem hết bảng tin';
  final moHoSo = 'Mở hồ sơ {author}';
  final moBaiViet = 'Mở bài {value}';
  final moMenuBaiViet = 'Mở menu bài';
  final moBaiViet2 = 'Mở bài';
  final moBinhLuan = 'Mở bình luận';
  final gocNhinMoiMoiNgay = 'Góc nhìn mới, mỗi ngày.';
  final timBaiVietNguoiViet =
      'Tìm bài, người viết và chủ đề trong cộng đồng VNLF.';
  final timLinuxDevopsCaramos = 'Tìm Linux, DevOps, CaramOS…';
  final tuKhoaKhamPha = 'Từ khóa khám phá';
  final dangTaiGoiY = 'Đang tải gợi ý…';
  final chuaTaiDuocGoiY = 'Chưa tải được gợi ý.';
  final chuDeCongDong = 'Chủ đề cộng đồng';
  final goiYChoBan = 'Gợi ý cho bạn';
  final nguoiVietNenTheoDoi = 'Người viết nên theo dõi';
  final khamPha2 = 'Khám phá';
  final xemHoSo = 'Xem hồ sơ {name}';
}

final class ViFloatingMessages {
  const ViFloatingMessages._();
  final dongTinMoi = 'Đóng thông báo tin mới';
  final chatVoi = 'Trò chuyện với {displayName}';
  final tuyChonChatNhanh = 'Tùy chọn khung chat';
  final moHoiThoaiDayDu = 'Mở trang trò chuyện';
  final thuNhoChat = 'Thu nhỏ khung chat';
  final dongChat = 'Đóng khung chat';
  final xemHoSo = 'Xem hồ sơ';
  final timTrongCuocTroChuyen = 'Tìm trong cuộc trò chuyện';
  final thongTinVaBaoCao = 'Thông tin và báo cáo';
  final chuaGuiDuocNoiDung = 'Chưa gửi được. Nội dung vẫn còn nguyên.';
  final nhanTinNhanh = 'Nhắn tin…';
}

final class ViGifPicker {
  const ViGifPicker._();
  final timGifKlipy = 'Tìm GIF KLIPY';
  final gif = 'GIF';
  final poweredByKlipy = 'GIF từ KLIPY';
  final dongTimGif = 'Đóng tìm GIF';
  final timGifTrenKlipy = 'Tìm GIF trên KLIPY';
  final searchKlipy = 'Tìm trên KLIPY';
  final dangKetNoi = 'Đang kết nối…';
  final chuaTaiDuocCauHinh = 'Chưa tải được GIF. Thử lại sau.';
  final khoKlipyChuaDuocCau =
      'Chưa bật GIF KLIPY. Admin cần thêm KLIPY_WEB_API_KEY (dùng test key cũng được, chưa cần duyệt production).';
  final dangTimGif = 'Đang tìm GIF…';
  final khongTimThayGifThu = 'Không có GIF nào. Thử từ khóa khác nhé.';
  final xemThemGif = 'Xem thêm GIF';
  final chonGif = 'Chọn GIF {title}';
  final gifChuaTaiDuoc = 'Chưa tải được GIF';
  final sticker = 'Sticker';
  final loaiNoiDung = 'GIF hoặc sticker';
  final timStickerTrenKlipy = 'Tìm sticker trên KLIPY';
  final dangTimSticker = 'Đang tìm sticker…';
  final khongTimThaySticker = 'Không có sticker nào. Thử từ khóa khác nhé.';
  final xemThemSticker = 'Xem thêm sticker';
  final chonSticker = 'Chọn sticker {title}';
  final dungGanDay = 'Dùng gần đây';
  final stickerTuKlipy = 'Sticker từ KLIPY';
}

final class ViHub {
  const ViHub._();
  final customizeHub = 'Customize Hub';
  final moTa =
      'Thông tin hồ sơ ở trên, trang trí ở dưới. Sửa gì lưu nấy, không cần bấm Lưu.';
  final nhayToi = 'Đi tới phần';
  final dangLuu = 'Đang lưu…';
  final daLuu = 'Đã lưu';
  final chuaLuuDuoc = 'Chưa lưu được. Thử lại sau.';
  final hoSo = 'Hồ sơ';
  final hoSoMoTa =
      'Ảnh bìa, ảnh đại diện, tên, giới thiệu và liên kết. Chữ được lưu khi bạn rời ô.';
  final tenVaUsernameBatBuoc = 'Tên hiển thị và username không được để trống.';
  final ten = 'Tên';
  final tenCuaBan = 'Tên của bạn';
  final tenCuaBanMoTa =
      'Màu, icon, huy hiệu distro, hiệu ứng và bảng tên mọi người thấy cạnh tên bạn.';
  final iconMoTa =
      'Một hình nhỏ cạnh tên, chọn từ kho icon chung của cộng đồng.';
  final chonIcon = 'Chọn icon';
  final doiIcon = 'Đổi icon';
  final hieuUngTen = 'Hiệu ứng tên';
  final hieuUngTenMoTa =
      'Chạy ở trang cá nhân và thẻ hồ sơ; ở nơi khác chỉ chạy khi rê chuột.';
  final bangTen = 'Bảng tên';
  final bangTenMoTa =
      'Dải nền phía sau tên ở danh sách thành viên, tin nhắn và sidebar.';
  final avatar = 'Avatar';
  final khungAvatar = 'Khung avatar';
  final khungAvatarMoTa =
      'Khung quanh ảnh đại diện, hiện ở trang cá nhân, bảng tin, bình luận và sổ lưu bút.';
  final nen = 'Nền';
  final nenTrang = 'Nền trang cá nhân';
  final nenTrangMoTa =
      'Theme quyết định màu nhấn (nút, số liệu, tab) và màu nền. Phía sau các thẻ chỉ dùng một kiểu nền: màu của theme, hình nền của bạn hoặc một hiệu ứng động.';
  final phiaSauCacThe = 'Phía sau các thẻ';
  final nenMauTheme = 'Màu của theme';
  final nenMauThemeMoTa = 'Nền đổi theo theme bạn chọn ở trên.';
  final nenHinhNen = 'Hình nền';
  final nenHinhNenMoTa =
      'Ảnh hoặc GIF của bạn thay màu nền của theme; màu nhấn vẫn theo theme.';
  final nenHieuUng = 'Hiệu ứng động';
  final nenHieuUngMoTa =
      'Một cảnh động vẽ sẵn (cực quang, mưa phố Hà Nội…) thay màu nền của theme.';
  final chuaChonHieuUng = 'Chọn một hiệu ứng bên dưới.';
  final goHinhNenHoi = 'Gỡ hình nền?';
  final goHinhNenMoTa =
      'Mỗi lúc chỉ dùng một kiểu nền. Hình nền hiện tại sẽ bị xóa để chuyển sang kiểu khác.';
  final goVaDoi = 'Gỡ và đổi';
  final hieuUngNen = const <String, String>{
    'crt': 'Màn hình CRT có vạch quét',
    'aurora': 'Cực quang trôi chậm',
    'starry-sky': 'Bầu trời sao lấp lánh',
    'hanoi-rain': 'Mưa đêm phố Hà Nội, kiểu lo-fi',
    'night-sea': 'Biển đêm có trăng',
    'tet': 'Sắc đỏ Tết, mai rơi',
    'trungthu': 'Đêm Trung thu, đèn lồng',
    'halloween': 'Đêm Halloween, dơi bay',
    'noel': 'Đêm Noel, tuyết rơi',
  };
  final kieuMayHat = 'Kiểu máy hát';
  final kieuMayHatMoTa =
      'Đĩa than hoặc băng cát-xét quay cạnh video khi nhạc phát.';
  final mayCuaToiMoTa =
      'Khoe cấu hình máy trong một cửa sổ terminal trên trang cá nhân.';
  final danOutput = 'Dán kết quả neofetch hoặc fastfetch';
  final danOutputMoTa =
      'Mở terminal, chạy neofetch (hoặc fastfetch), bôi đen toàn bộ kết quả, copy rồi dán vào đây. Logo và thông tin hiện y như trên máy bạn.';
  final dungOutput = 'Dùng kết quả này';
  final daCapNhatMay = 'Đã cập nhật thẻ máy';
  final outputKhongDocDuoc =
      'Không đọc được nội dung này. Hãy dán nguyên kết quả của neofetch hoặc fastfetch.';
  final mauTerminal = 'Màu terminal';
  final tenMauTerminal = const <String, String>{
    'vnlf': 'VNLF',
    'ubuntu': 'Ubuntu',
    'dracula': 'Dracula',
    'gruvbox': 'Gruvbox',
    'nord': 'Nord',
    'solarized': 'Solarized',
    'matrix': 'Matrix',
    'paper': 'Giấy sáng',
  };
  final suaTungDong = 'Hoặc sửa từng dòng';
  final xemTruocMay = 'Xem trước thẻ máy';
  final soLuuButGiaiThich =
      'Sổ lưu bút là nơi bạn bè ghé trang cá nhân để lại một lời chào ngắn, tối đa 200 ký tự, mỗi người một lời mỗi ngày. Bạn nhận thông báo khi có lời mới, có thể ẩn, xóa, chặn người viết hoặc tắt hẳn sổ.';
  final boDemGiaiThich =
      'Bộ đếm cho biết đã có bao nhiêu người ghé trang của bạn; mỗi người chỉ tính một lần mỗi ngày.';
  final kieuBoDem = 'Kiểu bộ đếm';
  final hieuUngVaThuCung = 'Hiệu ứng vào nhà và thú cưng';
  final hieuUngVaoNha = 'Hiệu ứng vào nhà';
  final hieuUngVaoNhaMoTa =
      'Chạy 3 giây khi ai đó mở trang của bạn, mỗi phiên một lần. Không chạy khi người xem bật giảm chuyển động.';
  final thuCung = 'Thú cưng';
  final thuCungMoTa =
      'Một con vật nhỏ đi dạo dưới ảnh bìa; khách bấm vào để chọc nó.';
}

final class ViProfileLinks {
  const ViProfileLinks._();
  final lienKet = 'Liên kết';
  final lienKetMoTa =
      'Tối đa {max} link, hiện thành nút dưới phần giới thiệu. Facebook, Instagram, YouTube, TikTok, GitHub… có logo riêng; trang khác hiện icon link. Lưu khi bạn rời ô.';
  final linkThu = 'Link {n}';
  final goiY = 'https://github.com/ten-cua-ban';
  final themLienKet = 'Thêm liên kết';
  final xoaLienKet = 'Xóa link {n}';
  final linkChuaDung =
      'Link chưa đúng. Dùng link http:// hoặc https:// tới một trang web, tối đa {length} ký tự.';
  final daDuBon = 'Đã đủ {max} liên kết.';
  final trangWeb = 'Website';
  final nhanLienKet = '{platform}: {label}';
  final danhSach = 'Liên kết của {name}';
  final discordNhan =
      'Discord: @{username}, đã xác minh qua Discord. Bấm để sao chép username.';
  final discordXacMinh = 'Đã xác minh qua Discord';
  final daSaoChepDiscord = 'Đã sao chép username Discord';
  final chuaSaoChepDuoc = 'Chưa sao chép được. Thử lại nhé.';
  final nenTang = const <String, String>{
    'facebook': 'Facebook',
    'instagram': 'Instagram',
    'youtube': 'YouTube',
    'tiktok': 'TikTok',
    'github': 'GitHub',
    'gitlab': 'GitLab',
    'x': 'X',
    'threads': 'Threads',
    'reddit': 'Reddit',
    'telegram': 'Telegram',
    'discord': 'Discord',
    'linkedin': 'LinkedIn',
    'twitch': 'Twitch',
    'codeberg': 'Codeberg',
    'bluesky': 'Bluesky',
    'zalo': 'Zalo',
  };
}

final class ViDistroBadge {
  const ViDistroBadge._();
  final huyHieuDistro = 'Huy hiệu distro';
  final moTa =
      'Logo distro bạn dùng, hiện ngay sau tên ở mọi nơi như icon cạnh tên. Mở khi bạn đạt Level {level}.';
  final dangKhoa =
      'Đạt Level {level} để chọn huy hiệu. Bạn đang ở Level {current}.';
  final moOLevel = 'Mở ở Level {level}';
  final dangAn =
      'Huy hiệu đang ẩn vì bạn đang dưới Level {level}. Lên lại Level {level} là huy hiệu hiện lại.';
  final ten = const <String, String>{
    'caramos': 'CaramOS',
    'linux': 'Linux (Tux)',
    'arch': 'Arch Linux',
    'debian': 'Debian',
    'ubuntu': 'Ubuntu',
    'fedora': 'Fedora',
    'mint': 'Linux Mint',
    'opensuse': 'openSUSE',
    'manjaro': 'Manjaro',
    'nixos': 'NixOS',
    'gentoo': 'Gentoo',
    'alpine': 'Alpine Linux',
    'elementary': 'elementary OS',
    'popos': 'Pop!_OS',
    'zorin': 'Zorin OS',
    'kali': 'Kali Linux',
    'endeavouros': 'EndeavourOS',
    'cachyos': 'CachyOS',
    'garuda': 'Garuda Linux',
    'artix': 'Artix Linux',
    'void': 'Void Linux',
    'slackware': 'Slackware',
    'centos': 'CentOS',
    'rocky': 'Rocky Linux',
    'almalinux': 'AlmaLinux',
    'redhat': 'Red Hat',
    'kubuntu': 'Kubuntu',
    'mxlinux': 'MX Linux',
    'qubes': 'Qubes OS',
    'tails': 'Tails',
    'raspberrypi': 'Raspberry Pi OS',
    'freebsd': 'FreeBSD',
    'puppy': 'Puppy Linux',
    'crux': 'CRUX',
  };
}

final class ViWardrobe {
  const ViWardrobe._();
  final khongDung = 'Không dùng';
  final xemThu = 'Xem thử';
  final mauMon = 'Màu của món';
  final mauThu2 = 'Màu thứ hai';
  final dangVaoMua = 'Đang vào mùa';
  final theoMua = 'Theo mùa';
  final banLaKhachThu = 'Bạn là khách thứ {count}';
  final luotGheNgan = 'lượt ghé';
  final bootDong1 = '[  OK  ] Mounted /home/{username}.';
  final bootDong2 = '[  OK  ] Started {username} home.service.';
  final bootDong3 = '[  OK  ] Started profile-music.service.';
  final bootDong4 = '[  OK  ] Reached target Visitors.';
  final mon = const <String, Map<String, String>>{
    'frame': {
      'ring': 'Vòng đơn sắc',
      'ring-duo': 'Vòng hai màu',
      'tux-ears': 'Tai Tux',
      'terminal': 'Terminal >_',
      'lotus': 'Hoa sen',
      'pixel': 'Pixel 8-bit',
      'neon': 'Neon thở',
      'streak-fire': 'Lửa streak',
      'matrix': 'Mưa Matrix',
      'stars': 'Vòng sao',
      'mai': 'Hoa mai Tết',
      'lantern': 'Đèn lồng Trung thu',
      'pumpkin': 'Bí ngô Halloween',
      'snowflake': 'Bông tuyết Noel',
    },
    'nameEffect': {
      'glow': 'Phát sáng',
      'cursor': 'Con trỏ terminal',
      'shine': 'Ánh kim',
      'rainbow': 'Cầu vồng',
      'glitch': 'Glitch',
      'typing': 'Gõ chữ',
    },
    'entrance': {
      'confetti': 'Confetti',
      'snow': 'Tuyết',
      'sakura': 'Hoa đào',
      'fireflies': 'Đom đóm',
      'bubbles': 'Bong bóng',
      'matrix-rain': 'Mưa Matrix',
      'boot': 'Boot Linux',
      'meteors': 'Sao băng',
    },
    'playerSkin': {
      'classic': 'Đĩa đen cổ điển',
      'clear': 'Đĩa màu trong suốt',
      'splatter': 'Đĩa vân loang',
      'picture': 'Picture disc',
      'gold': 'Đĩa vàng',
      'cassette': 'Băng cassette',
      'cd': 'Đĩa CD',
      'wood': 'Máy hát gỗ',
    },
    'pet': {
      'tux': 'Tux',
      'cat': 'Mèo',
      'turtle': 'Rùa',
      'bug': 'Con bọ',
      'crab': 'Cua',
    },
    'nameplate': {
      'tint': 'Dải màu',
      'circuit': 'Mạch điện',
      'terminal': 'Terminal',
      'waves': 'Sóng',
      'starry': 'Sao đêm',
    },
    'specialTheme': {
      'crt': 'CRT terminal',
      'aurora': 'Aurora',
      'starry-sky': 'Bầu trời sao',
      'hanoi-rain': 'Phố Hà Nội mưa lo-fi',
      'night-sea': 'Biển đêm',
      'tet': 'Tết',
      'trungthu': 'Trung thu',
      'halloween': 'Halloween',
      'noel': 'Giáng sinh',
    },
    'counterSkin': {
      'plain': 'Chữ thường',
      'flip': 'Đồng hồ lật',
      'led': 'LED 7 đoạn',
      'odometer': 'Đồng hồ cây số',
      'web2000': 'Web 2000',
      'chalk': 'Bảng phấn',
    },
  };
}

final class ViGuestbook {
  const ViGuestbook._();
  final soLuuBut = 'Sổ lưu bút';
  final vietLoiNhan = 'Viết lời nhắn';
  final vietChoAi = 'Để lại vài lời cho {name}…';
  final guiLoiNhan = 'Gửi';
  final dangGui = 'Đang gửi…';
  final daGuiLoiNhan = 'Đã gửi lời nhắn';
  final chuaGuiDuoc = 'Chưa gửi được lời nhắn. Thử lại sau.';
  final chuaCoLoiNhan = 'Chưa có lời nhắn nào. Hãy là người đầu tiên.';
  final soCuaBan = 'Khách ghé thăm sẽ viết lời nhắn cho bạn ở đây.';
  final dangNhapDeViet = 'Đăng nhập để viết vào sổ lưu bút.';
  final dangNhap = 'Đăng nhập';
  final soLuuButDaTat = 'Chủ trang đã tắt sổ lưu bút.';
  final daVietHomNay = 'Bạn đã viết hôm nay. Hẹn bạn ngày mai.';
  final khongTheViet = 'Bạn không thể viết vào sổ lưu bút này.';
  final tuyChonLoiNhan = 'Tuỳ chọn lời nhắn của {name}';
  final an = 'Ẩn với khách';
  final hienLai = 'Hiện lại';
  final xoa = 'Xóa';
  final baoCaoLoiNhan = 'Báo cáo lời nhắn';
  final chanNguoiNay = 'Chặn người này';
  final daAn = 'Đã ẩn lời nhắn';
  final daHienLai = 'Đã hiện lại lời nhắn';
  final daXoa = 'Đã xóa lời nhắn';
  final daChan = 'Đã chặn người này.';
  final chuaThucHienDuoc = 'Chưa thực hiện được. Thử lại sau.';
  final xoaLoiNhanHoi = 'Xóa lời nhắn này?';
  final xoaLoiNhanMoTa = 'Lời nhắn sẽ biến mất khỏi sổ lưu bút.';
  final dangAn = 'Đang ẩn với khách';
  final xemThem = 'Xem thêm';
  final luotGhe = '{count} lượt ghé';
  final luotGheDangAn = '{count} lượt ghé · đang ẩn với khách';
  final daVietVaoSoLuuBut = '{actors} đã viết vào sổ lưu bút của bạn';
  final loiNhanMoi = 'Lời nhắn mới';
  final baoCaoTrangTri = 'Báo cáo trang trí';
  final daGuiBaoCao = 'Đã gửi báo cáo tới đội kiểm duyệt';
  final lyDoNhacKhongPhuHop = 'Nhạc hoặc hình không phù hợp';
  final soLuuButVaBoDem = 'Sổ lưu bút và bộ đếm khách';
  final gioiThieu =
      'Sổ lưu bút là nơi khách ghé trang để lại một lời chào ngắn cho {name}. Mỗi người viết một lời mỗi ngày.';
  final soLoiNhan = '{count} lời nhắn';
  final vietLoiChao = 'Viết lời chào';
  final moSoLuuBut = 'Mở sổ lưu bút';
  final teaserKhach = 'Ghé chơi thì để lại một lời chào cho {name} nhé.';
  final teaserChuTrangTrong =
      'Chưa ai viết vào sổ của bạn. Bạn bè ghé trang sẽ để lại lời chào ở đây.';
  final soDangTat = 'Sổ lưu bút đang tắt, khách không thấy và không viết được.';
  final batLai = 'Bật lại ở Customize Hub';
  final batSoLuuBut = 'Bật sổ lưu bút';
  final hienBoDem = 'Hiện số lượt ghé cho khách';
}

final class ViIcons {
  const ViIcons._();
  final khoIcon = 'Kho icon';
  final khoIconMoTa =
      'Icon hiện cạnh tên bạn ở mọi nơi. Cả cộng đồng dùng chung kho này: bấm một icon để dùng, hoặc tải icon của bạn lên.';
  final timIcon = 'Tìm icon theo tên hoặc thẻ';
  final sapXep = 'Sắp xếp icon';
  final phoBien = 'Phổ biến';
  final moi = 'Mới';
  final cuaToi = 'Của tôi';
  final taiIconLen = 'Tải icon lên';
  final dung = 'Dùng';
  final dungIconNay = 'Dùng {name}';
  final dangDung = 'Đang dùng';
  final boIcon = 'Bỏ icon';
  final daDungIcon = 'Đã đặt icon cạnh tên bạn';
  final daBoIcon = 'Đã bỏ icon';
  final chuaDoiDuocIcon = 'Chưa đổi được icon. Thử lại sau.';
  final taiLenBoi = 'của @{username}';
  final soNguoiDung = '{count} người dùng';
  final chuaCoIcon = 'Kho chưa có icon nào. Hãy là người đầu tiên tải lên.';
  final khongTimThayIcon = 'Không tìm thấy icon phù hợp.';
  final banChuaTaiIconNao = 'Bạn chưa tải icon nào lên.';
  final dangXuLyIcon = 'Đang xử lý';
  final tuyChonIcon = 'Tuỳ chọn cho {name}';
  final xoaIcon = 'Xóa icon';
  final xoaIconHoi = 'Xóa icon này khỏi kho?';
  final xoaIconMoTa = 'Những người đang dùng sẽ mất icon này.';
  final daXoaIcon = 'Đã xóa icon';
  final chuaXoaDuocIcon = 'Chưa xóa được icon. Thử lại sau.';
  final baoCaoIcon = 'Báo cáo icon';
  final taiIconTieuDe = 'Tải icon lên kho chung';
  final yeuCauTep =
      'PNG tĩnh, đúng 200×200 px, tối đa 256KB. Nền trong suốt được. SVG (tệp hoặc mã dán vào) tự đổi sang PNG 200×200.';
  final chonTepPng = 'Chọn tệp PNG hoặc SVG';
  final tenIcon = 'Tên icon';
  final theIcon = 'Thẻ';
  final theIconGoiY = 'Tối đa 5 thẻ, cách nhau bằng dấu phẩy';
  final anhPixel = 'Ảnh pixel: thu nhỏ không làm nhoè nét';
  final xacNhanQuyen =
      'Tôi có quyền dùng hình này và đồng ý cho mọi người trong VNLF dùng chung.';
  final taiLen = 'Tải lên';
  final dangKiemTraTep = 'Đang kiểm tra tệp…';
  final daThemVaoKho = 'Đã thêm icon vào kho';
  final xemTruocIcon = 'Xem trước icon';
  final iconCanhTen = 'Icon cạnh tên';
  final iconCanhTenMoTa =
      'Chọn một icon trong kho chung hoặc tải icon của bạn lên.';
  final chuaChonIcon = 'Chưa chọn icon';
  final taiThem = 'Xem thêm';
  final quanLyIcon = 'Quản lý icon';
  final daGuiBaoCaoIcon = 'Đã gửi báo cáo icon tới đội kiểm duyệt';
  final lyDoPhanCam = 'Hình phản cảm';
  final lyDoGiaMao = 'Giả mạo logo hoặc dấu chính thức';
  final lyDoBanQuyen = 'Vi phạm bản quyền';
  final iconCuaBan = 'Icon cạnh tên bạn';
  final loi = const <String, String>{
    'ICON_FORMAT_INVALID': 'Icon phải là tệp PNG.',
    'ICON_SIZE_INVALID': 'Icon phải đúng 200×200 px.',
    'ICON_ANIMATED': 'Icon phải là ảnh tĩnh, không nhận PNG động.',
    'ICON_TOO_LARGE': 'Icon tối đa 256KB.',
    'ICON_NAME_RESERVED':
        'Tên icon không được trùng tên vai trò như Admin, Moderator, Owner.',
    'ICON_LIMIT': 'Mỗi người có tối đa 20 icon trong kho. Xóa bớt icon cũ rồi tải icon mới.',
    'ICON_RIGHTS_REQUIRED': 'Hãy xác nhận bạn có quyền dùng hình này.',
  };
}

final class ViKlipy {
  const ViKlipy._();
  final duLieuGifTuKlipy =
      'KLIPY trả về dữ liệu GIF không đọc được. Thử lại sau.';
  final klipyDangBatQuangCao =
      'KLIPY đang bật quảng cáo. Admin cần tắt quảng cáo trong Partner Panel để dùng kho GIF.';
  final khoKlipyChuaDuocCau = 'Kho GIF KLIPY chưa được thiết lập.';
  final klipyDaHetLuotGoi =
      'KLIPY tạm hết lượt dùng (khóa thử giới hạn 100 lượt/giờ). Thử lại sau.';
  final klipyChuaChapNhanApi =
      'KLIPY chưa chấp nhận khóa API. Admin cần kiểm tra lại thiết lập.';
  final chuaTaiDuocGifTu = 'Chưa tải được GIF từ KLIPY. Thử lại sau.';
  final klipyPhanHoiQuaCham = 'KLIPY phản hồi quá chậm. Thử lại sau.';
  final khongKetNoiDuocKlipy =
      'Không kết nối được KLIPY. Kiểm tra mạng rồi thử lại.';
}

final class ViLayout {
  const ViLayout._();
  final linuxVietNam = 'Linux Việt Nam';
  final maNguonMo = 'mã nguồn mở';
  final congDongCongNghe = 'cộng đồng công nghệ';
}

final class ViLeaderboardView {
  const ViLeaderboardView._();
  final top100ThanhVienTheo = 'Top 100 thành viên nhiều XP nhất trong tuần.';
  final tuanTruoc = 'Tuần trước';
  final tuanNay = 'Tuần này';
  final tuanDaChon = 'Tuần đã chọn';
  final tuanSau = 'Tuần sau';
  final tuanBatDauThuHai =
      'Tuần tính từ thứ Hai, giờ Việt Nam. Cập nhật mỗi 5 phút.';
  final dangTaiBangXepHang = 'Đang tải bảng xếp hạng…';
  final chuaTaiDuocBangXep = 'Chưa tải được bảng xếp hạng';
  final chuaCoDiemTrongTuan = 'Tuần này chưa có ai ghi điểm';
  final chiaSeBinhLuanHoac =
      'Đăng bài, bình luận hoặc tham gia thảo luận để nhận XP.';
  final hang = 'Hạng {rank}';
  final ban = '· Bạn';
  final xp = 'XP';
  final capNhat = 'Cập nhật lúc {value}';
}

final class ViLoading {
  const ViLoading._();
  final dangTai = 'Đang tải';
}

final class ViLocalArticleView {
  const ViLocalArticleView._();
  final localArticle = 'Bản nháp cũ';
  final noiDungLocalKhongCon =
      'Bản nháp lưu trên trình duyệt không còn dùng được nữa.';
  final draftCuCanDuocNhap =
      'Hãy nhập bản nháp cũ lên từ trang Bài viết của bạn rồi sửa tiếp.';
}

final class ViManifest {
  const ViManifest._();
  final vnlfSocialCongDongLinux = 'VNLF Social — Cộng đồng Linux Việt Nam';
}

final class ViAppInstall {
  const ViAppInstall._();
  final caiApp = 'Cài app';
  final tieuDe = 'Cài VNLF Social như app';
  final loiIch =
      'Mở thẳng từ màn hình chính, toàn màn hình như app, nhận thông báo tin nhắn.';
  final bannerMoTa = 'Mở nhanh từ màn hình chính, nhận thông báo tin nhắn.';
  final dongGoiY = 'Đóng gợi ý cài app';
  final xemCachCai = 'Xem cách cài';
  final dangMoHopThoai = 'Đang mở…';
  final daCai = 'Đã cài xong. Mở VNLF Social từ màn hình chính.';
  final dangDungApp = 'Bạn đang dùng VNLF Social dạng app rồi.';
  final veBangTin = 'Về bảng tin';
  final androidThuCong =
      'Mở menu ⋮ của trình duyệt rồi chọn "Cài đặt ứng dụng" hoặc "Thêm vào màn hình chính".';
  final androidDaCai =
      'Nếu đã cài, VNLF Social nằm trên màn hình chính của bạn.';
  final iosTieuDe = 'Trên iPhone và iPad, cài trong 3 bước:';
  final iosBuoc1 =
      'Nhấn nút Chia sẻ (ô vuông có mũi tên lên). Trên iOS 26, nút này nằm trong menu ⋯ ở thanh dưới.';
  final iosBuoc2 = 'Kéo xuống, chọn "Thêm vào MH chính".';
  final iosBuoc3 =
      'Nhấn "Thêm". Mở VNLF Social từ màn hình chính là dùng như app, nhận được thông báo tin nhắn.';
  final iosTrinhDuyetKhac =
      'Không thấy mục "Thêm vào MH chính"? Mở trang này bằng Safari rồi làm lại.';
  final trongApp =
      'Bạn đang xem trong {app}. Trình duyệt của {app} không cài được app, mở trang bằng trình duyệt trước.';
  final moBangTrinhDuyet = 'Mở bằng trình duyệt';
  final trongAppThuCong =
      'Nút không mở được? Nhấn ⋯ hoặc ⋮ ở góc trên rồi chọn mở bằng trình duyệt (Safari, Chrome).';
  final mayTinh =
      'Mở trang này trên điện thoại để cài app. Trên máy tính, Chrome và Edge có nút cài ở thanh địa chỉ.';
  final tenApp = const <String, String>{
    'zalo': 'Zalo',
    'facebook': 'Facebook',
    'messenger': 'Messenger',
    'instagram': 'Instagram',
    'tiktok': 'TikTok',
    'line': 'LINE',
    'other': 'ứng dụng này',
  };
}

final class ViVideoPlayer {
  const ViVideoPlayer._();
  final nhan = const <String, String>{
    'Play': 'Phát',
    'Pause': 'Tạm dừng',
    'play': 'phát',
    'pause': 'tạm dừng',
    'Mute': 'Tắt tiếng',
    'Unmute': 'Bật tiếng',
    'mute': 'tắt tiếng',
    'unmute': 'bật tiếng',
    'Enter fullscreen mode': 'Toàn màn hình',
    'Exit fullscreen mode': 'Thoát toàn màn hình',
    'enter fullscreen mode': 'toàn màn hình',
    'exit fullscreen mode': 'thoát toàn màn hình',
    'video player': 'trình phát video',
    'audio player': 'trình phát âm thanh',
    'volume': 'âm lượng',
    'seek': 'tua',
    'playback time': 'thời gian phát',
    'media loading': 'đang tải video',
    'Network Error': 'Lỗi mạng',
    'Decode Error': 'Không đọc được video',
    'Source Not Supported': 'Không hỗ trợ định dạng này',
    'A network error caused the media download to fail.':
        'Mạng bị lỗi nên chưa tải được video.',
    'A media error caused playback to be aborted. The media could be corrupt or your browser does not support this format.':
        'Video bị lỗi hoặc trình duyệt không phát được định dạng này.',
    'An unsupported error occurred. The server or network failed, or your browser does not support this format.': 'Chưa phát được video. Máy chủ hoặc mạng gặp lỗi, hoặc trình duyệt không hỗ trợ định dạng này.',
    'hour': 'giờ',
    'hours': 'giờ',
    'minute': 'phút',
    'minutes': 'phút',
    'second': 'giây',
    'seconds': 'giây',
    '{time} remaining': 'còn {time}',
    '{currentTime} of {totalTime}': '{currentTime} trên {totalTime}',
    'video not loaded, unknown time.': 'video chưa tải, chưa rõ thời lượng.',
  };
}

final class ViMediaGallery {
  const ViMediaGallery._();
  final xemAnh = 'Xem ảnh {value} / {count}';
  final xemAnh2 = 'Xem ảnh';
  final dongAnh = 'Đóng ảnh';
  final anhTruoc = 'Ảnh trước';
  final anhTiepTheo = 'Ảnh tiếp theo';
  final videoDinhKem = 'Video đính kèm';
}

final class ViMiscViews {
  const ViMiscViews._();
  final quayLaiBangTin = 'Quay lại bảng tin';
  final luotXem = '{viewCount} lượt xem';
  final chiBanThayLuotXem =
      'Chỉ bạn thấy số lượt xem: mỗi người tính một lượt mỗi ngày.';
  final moMenuBaiViet = 'Mở menu bài';
  final xemHoSo = 'Xem hồ sơ {displayName}';
  final moBinhLuan = 'Mở bình luận';
  final traLoi = 'Trả lời @{username}…';
  final article = 'Article';
  final phutDoc = '{Math} phút đọc';
  final chiaSe = 'Chia sẻ';
  final kiemTraLaiThongTin = 'Kiểm tra lại thông tin rồi thử lại.';
  final lienKetKhongHopLe =
      'Link này đã hết hạn hoặc đã dùng rồi. Yêu cầu link mới để tiếp tục.';
  final chuaKetNoiDuocMayChu =
      'Chưa kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
  final kiemTraHopThu = 'Kiểm tra hộp thư';
  final neuEmailDaDangKy =
      'Nếu {email} đã đăng ký, link đặt lại mật khẩu đang trên đường tới. Link dùng được trong 30 phút.';
  final chuaThayEmail = 'Chưa thấy? Xem thử mục Spam hoặc Quảng cáo.';
  final guiLai = 'Gửi lại';
  final guiLaiSau = 'Gửi lại sau {seconds}s';
  final daGuiLaiEmail = 'Đã gửi lại. Xem hộp thư nhé.';
  final dungEmailKhac = 'Dùng email khác';
  final daDoiMatKhau = 'Đã đổi mật khẩu';
  final thietBiCuDaDangXuat =
      'Các thiết bị đang đăng nhập đã bị đăng xuất. Đăng nhập lại bằng mật khẩu mới.';
  final linkKhongDungDuoc = 'Link không dùng được';
  final linkThieuHoacHetHan =
      'Link đặt lại mật khẩu bị thiếu, đã hết hạn hoặc đã dùng rồi. Yêu cầu link mới để tiếp tục.';
  final dangGui = 'Đang gửi…';
  final dangLuu = 'Đang lưu…';
  final emailHoacUsernameDaDuoc = 'Email hoặc username đã có người dùng.';
  final taiKhoanKhongTonTai = 'Tài khoản không tồn tại hoặc đang bị tạm khóa.';
  final vietNam = 'VIỆT NAM';
  final linuxFamily = 'LINUX FAMILY';
  final doiGiaoDien = 'Đổi giao diện';
  final noiCongDong = 'Nơi cộng đồng';
  final cungXayDung = 'cùng xây dựng.';
  final batDauCauChuyen = 'Bắt đầu câu chuyện';
  final cuaBan = 'của bạn.';
  final taoMatKhau = 'Tạo mật khẩu';
  final moi = 'mới.';
  final datLai = 'Đặt lại';
  final matKhau = 'mật khẩu.';
  final chiaSeDieuBanBiet =
      'Chia sẻ điều bạn biết. Tìm người cùng chí hướng. Đi xa hơn cùng VNLF.';
  final taoUsernameTimCongDong =
      'Tạo username, tìm cộng đồng và chia sẻ thứ bạn đang làm.';
  final nhapMatKhauMoiToi =
      'Mật khẩu mới cần ít nhất 10 ký tự. Mọi phiên đăng nhập cũ sẽ bị đăng xuất.';
  final nhapEmailDeNhanLien =
      'Nhập email đã đăng ký, bọn mình gửi link đặt lại mật khẩu cho bạn.';
  final dangKy = 'Đăng ký';
  final username = 'Username';
  final usernameCan330Ky =
      'Username dài 3–30 ký tự, chỉ gồm chữ, số, dấu chấm hoặc gạch dưới.';
  final emailCuaBan = 'Email của bạn';
  final emailChuaDungDinhDang = 'Email chưa đúng.';
  final emailHoacUsername = 'Email hoặc username';
  final emailHoacUsernameChuaDung =
      'Nhập email, hoặc username 3–30 ký tự (chữ, số, dấu chấm, gạch dưới).';
  final matKhauToiThieu10 = 'Mật khẩu · tối thiểu 10 ký tự';
  final matKhauMoiToiThieu = 'Mật khẩu mới · tối thiểu 10 ký tự';
  final matKhau2 = 'Mật khẩu';
  final anMatKhau = 'Ẩn mật khẩu';
  final hienMatKhau = 'Hiện mật khẩu';
  final matKhauCanItNhat = 'Mật khẩu cần ít nhất 10 ký tự.';
  final nhapLaiMatKhau = 'Nhập lại mật khẩu';
  final matKhauNhapLaiChua = 'Mật khẩu nhập lại chưa khớp.';
  final vaoVnlfSocial = 'Vào VNLF Social';
  final taoTaiKhoan = 'Tạo tài khoản';
  final luuMatKhauMoi = 'Lưu mật khẩu mới';
  final guiLienKetDatLai = 'Gửi link đặt lại';
  final quenMatKhau = 'Quên mật khẩu?';
  final tiepTucVoiGoogle = 'Tiếp tục với Google';
  final hoac = 'hoặc';
  final googleLoi = 'Chưa đăng nhập được bằng Google. Thử lại nhé.';
  final googleChuaXacMinh =
      'Email của tài khoản Google này chưa được xác minh.';
  final googleBiKhoa = 'Tài khoản này đang bị tạm khóa hoặc chờ xóa.';
  final tiepTucVoiDiscord = 'Tiếp tục với Discord';
  final discordLoi = 'Chưa đăng nhập được bằng Discord. Thử lại nhé.';
  final discordChuaXacMinh =
      'Email của tài khoản Discord này chưa được xác minh. Xác minh email trên Discord rồi thử lại.';
  final discordBiKhoa = 'Tài khoản này đang bị tạm khóa hoặc chờ xóa.';
  final discordXungDot =
      'Email này thuộc một tài khoản VNLF đã liên kết Discord khác. Đăng nhập bằng email hoặc Google, rồi đổi Discord ở Cài đặt → Bảo mật.';
  final quayLaiDangNhap = 'Quay lại đăng nhập';
  final yeuCauLienKetMoi = 'Yêu cầu link mới';
  final dangKyMoKhongCan = 'Đăng ký tự do · Chưa cần xác minh email';
}

final class ViMyArticlesView {
  const ViMyArticlesView._();
  final xoaBanNhapNay = 'Xóa bản nháp này?';
  final banNhapSeBiXoa = '“{title}” sẽ bị xóa hẳn, không khôi phục được.';
  final baiSeBienMat =
      '“{title}” sẽ biến mất khỏi bảng tin và hồ sơ của bạn. Không khôi phục được.';
  final baiSeAnKhoiBangTin =
      '“{title}” sẽ ẩn khỏi bảng tin. Bạn khôi phục lại được trong mục Lưu trữ.';
  final chuaThucHienDuoc = 'Chưa thực hiện được. Thử lại sau.';
  final daNhapDraftLocalLen = 'Đã chuyển bản nháp cũ lên máy chủ';
  final nhapDraftBiGianDoan =
      'Chưa chuyển xong bản nháp. Phần còn lại vẫn nằm trong trình duyệt.';
  final daXoaDraft = 'Đã xóa bản nháp';
  final daXoaMemBaiViet = 'Đã xóa bài';
  final daLuuTruBaiViet = 'Đã lưu trữ bài';
  final yourWriting = 'Bài của bạn';
  final vietBaiMoi = 'Viết bài mới';
  final draftCuDangOTrinh = 'Còn {legacyCount} bản nháp cũ trong trình duyệt.';
  final dangNhap = 'Đang chuyển…';
  final nhapLenMayChu = 'Chuyển lên máy chủ';
  final trangThaiBaiViet = 'Trạng thái bài';
  final draft = 'Nháp ({count})';
  final daDang = 'Đã đăng ({count})';
  final luuTru = 'Lưu trữ ({count})';
  final chuaCoBaiTrongMuc = 'Mục này chưa có bài nào';
  final vietMoiHoacChuyenBai = 'Viết bài mới hoặc chuyển bài từ mục khác sang.';
  final luuTruBaiViet = 'Lưu trữ bài này?';
  final xoaNoiDungNay = 'Xóa bài này?';
  final luuTru2 = 'Lưu trữ';
  final draft2 = 'Nháp · {value}';
  final draftChuaCoNoiDung = 'Bản nháp còn trống.';
}

final class ViNotFound {
  const ViNotFound._();
  final khongTimThayTrang = 'Không tìm thấy trang.';
  final urlKhongTonTaiHoac =
      'Link không tồn tại hoặc nội dung đã được chuyển đi.';
}

final class ViNotificationCenter {
  const ViNotificationCenter._();
  final dongThongBao = 'Đóng thông báo';
  final chuaDoc = 'Chưa đọc';
  final loaiThongBao = 'Loại thông báo';
  final moiLoai = 'Tất cả';
  final luotThich = 'Lượt thích';
  final heThong = 'Hệ thống';
  final danhDauTatCaDa = 'Đánh dấu tất cả đã đọc';
  final khongTaiDuocThuLai = 'Chưa tải được. Thử lại';
  final homNay = 'Hôm nay';
  final homQua = 'Hôm qua';
  final truocDo = 'Trước đó';
  final va = ' và ';
  final vaNguoiKhac = ' và {value} người khác';
  final vuaXong = 'Vừa xong';
  final gio = '{hours} giờ';
  final ngay = '{Math} ngày';
  final khongCoThongBao = 'Chưa có thông báo nào.';
  final dangTaiThem = 'Đang tải thêm…';
  final xemTatCa = 'Xem tất cả';
}

final class ViNotificationCopy {
  const ViNotificationCopy._();
  final daThichBaiVietCua = 'đã thích bài viết của bạn';
  final daThichBinhLuanCua = 'đã thích bình luận của bạn';
  final daNhacDenBanTrong = 'đã mention bạn trong bình luận';
  final daTraLoiBinhLuan = 'đã trả lời bình luận của bạn';
  final daBinhLuanVeBai = 'đã bình luận về bài viết của bạn';
  final daTheoDoiBan = 'đã theo dõi bạn';
  final daVietVaoSoLuuBut = 'đã viết vào sổ lưu bút của bạn';
  final daCapNhatTicket = 'đã cập nhật ticket của bạn';
  final daTraLoiGopY = 'đã trả lời góp ý của bạn';
  final daNhanVeGopY = 'đã nhắn về góp ý';
  final daDuyetBoSticker = 'đã đưa bộ sticker của bạn lên chợ';
  final chuaDuyetBoSticker = 'chưa duyệt bộ sticker của bạn';
  final daGoBoStickerKhoiCho = 'đã gỡ bộ sticker của bạn khỏi chợ';
  final daDuyetDuAn = 'đã duyệt dự án của bạn';
  final chuaDuyetDuAn = 'chưa duyệt dự án của bạn';
  final daDuyetThayDoiDuAn = 'đã duyệt thay đổi dự án của bạn';
  final chuaDuyetThayDoiDuAn = 'chưa duyệt thay đổi dự án của bạn';
  final daAnDuAn = 'đã ẩn dự án của bạn';
  final daGoBaiDangCuaBan = 'đã gỡ bài đăng của bạn';
  final daGoBinhLuanCuaBan = 'đã gỡ bình luận của bạn';
  final daGoTinNhanCuaBan = 'đã gỡ tin nhắn của bạn';
  final daGoLoiNhanCuaBan = 'đã gỡ lời nhắn bạn viết trong sổ lưu bút';
  final daGoTraLoiCuaBan = 'đã gỡ câu trả lời của bạn';
  final daGoIconCuaBan = 'đã gỡ icon bạn tải lên';
  final daDatLaiTrangTri = 'đã đặt lại trang trí trang cá nhân của bạn';
  final daGoNoiDungCuaBan = 'đã gỡ nội dung của bạn';
  final lyDo = 'Lý do: {reason}';
  final repoDuAnMat = 'không còn thấy repo dự án của bạn trên GitHub';
  final coCapNhatMoi = 'có cập nhật mới';
  final binhLuanKhongConKha = 'Bình luận không còn hiển thị';
}

final class ViOpengraphImage {
  const ViOpengraphImage._();
  final vnlfSocialCongDongLinux =
      'VNLF Social — Cộng đồng Linux và mã nguồn mở Việt Nam';
  final congDongLinuxMaNguon = 'Cộng đồng Linux & mã nguồn mở Việt Nam';
}

final class ViPage {
  const ViPage._();
  final bangTinCongDongLinux = 'Bảng tin cộng đồng Linux Việt Nam';
  final baiVietThaoLuanVa =
      'Bài đăng, thảo luận và hoạt động mới nhất từ cộng đồng Vietnam Linux Family.';
}

final class ViPageAdminMembers {
  const ViPageAdminMembers._();
  final quanLyThanhVien = 'Quản lý thành viên';
}

final class ViPageAdminPoints {
  const ViPageAdminPoints._();
  final pointRules = 'Quy tắc tính điểm';
}

final class ViPageAdminReportsReportid {
  const ViPageAdminReportsReportid._();
  final chiTietBaoCaoKiem = 'Chi tiết báo cáo vi phạm';
}

final class ViPageAdminVoiceNew {
  const ViPageAdminVoiceNew._();
  final taoVoiceRoom = 'Tạo voice room';
}

final class ViPageAdminVoiceRoomid {
  const ViPageAdminVoiceRoomid._();
  final suaVoiceRoom = 'Sửa voice room {value}';
}

final class ViPageALocalArticleid {
  const ViPageALocalArticleid._();
  final baiVietLocal = 'Bài viết trên máy';
}

final class ViPageASlug {
  const ViPageASlug._();
  final baiDangCua = 'Bài đăng của {displayName}';
  final baiDangChiaSe = '{displayName}: {text}';
  final xemBaiDangCuaTrong =
      'Đọc bài đăng của {displayName} trong cộng đồng Linux Việt Nam.';
  final baiVietKyThuatVa =
      'Bài viết kỹ thuật và chia sẻ từ cộng đồng Linux, mã nguồn mở Việt Nam.';
  final linuxVietNam = 'Linux Việt Nam';
  final baiDangCuaTrenVnlf = 'Bài đăng của {displayName} trên VNLF Social.';
  final congDongLinux = 'Cộng đồng Linux';
}

final class ViPageChannelsSlug {
  const ViPageChannelsSlug._();
  final channelThaoLuanRealtimeTrong =
      'Channel thảo luận trực tiếp #{slug} trên VNLF Social.';
}

final class ViPageChannelsSlugMembers {
  const ViPageChannelsSlugMembers._();
  final thanhVien = 'Thành viên #{slug}';
}

final class ViPageChannelsSlugSettings {
  const ViPageChannelsSlugSettings._();
  final caiDat = 'Cài đặt #{slug}';
}

final class ViPageCommunityGuidelines {
  const ViPageCommunityGuidelines._();
  final nguyenTacThamGiaChia =
      'Nguyên tắc để tham gia, chia sẻ và thảo luận an toàn trong cộng đồng Vietnam Linux Family.';
  final giuVnlfTuTeHuu =
      'Cùng giữ VNLF tử tế, hữu ích và an toàn cho cả người mới học lẫn người đi làm.';
  final tonTrongThanhVien = 'Tôn trọng thành viên';
  final khongQuayRoiCongKich =
      'Không quấy rối, công kích cá nhân, kỳ thị hay tung thông tin riêng tư của người khác.';
  final chiaSeCoGiaTri = 'Chia sẻ điều có ích';
  final khongSpamLuaDaoFarm =
      'Không spam, lừa đảo, cày điểm hay đăng nội dung vi phạm bản quyền.';
  final reportDungMucDich = 'Báo cáo đúng mục đích';
  final dungReportDeBaoNoi =
      'Chỉ báo cáo nội dung thật sự có vấn đề, không dùng báo cáo để gây áp lực lên người khác.';
}

final class ViPageExplore {
  const ViPageExplore._();
  final khamPhaLinuxDevopsVa = 'Khám phá Linux, DevOps và mã nguồn mở';
  final khamPhaBaiVietKy =
      'Bài viết kỹ thuật, thành viên và chủ đề nổi bật trong cộng đồng Linux, mã nguồn mở Việt Nam.';
  final timNhungCuocThaoLuan = 'Những thảo luận đáng chú ý trên VNLF Social.';
  final khamPhaVnlfSocial = 'Khám phá VNLF Social';
}

final class ViPageForgotPassword {
  const ViPageForgotPassword._();
  final datLaiMatKhau = 'Đặt lại mật khẩu';
  final datLaiMatKhauVnlf = 'Đặt lại mật khẩu tài khoản VNLF Social.';
}

final class ViCaramosHelp {
  const ViCaramosHelp._();
  final tieuDe = 'Yêu cầu {id}';
  final metaTitle = 'Yêu cầu hỗ trợ CaramOS {id}';
  final eyebrow = 'CaramOS · VNLF';
  final guiLuc = 'Gửi lúc {time}';
  final trangThai = const <String, String>{
    'OPEN': 'Đã nhận',
    'IN_REVIEW': 'Đang xem',
    'RESOLVED': 'Đã xử lý',
    'CLOSED': 'Đã đóng',
    'DEFERRED': 'Để làm sau',
  };
  final loai = const <String, String>{
    'DRIVER_SUPPORT': 'Hỗ trợ driver',
    'OS_SUPPORT': 'Hỗ trợ OS',
    'FEEDBACK': 'Góp ý',
    'BUG': 'Báo lỗi',
  };
  final mucDo = const <String, String>{
    'critical': 'Nghiêm trọng',
    'warning': 'Cần chú ý',
    'ok': 'Ổn',
    'info': 'Thông tin',
  };
  final phanHoiTuVnlf = 'Phản hồi từ VNLF';
  final chuaCoPhanHoi =
      'Chưa có phản hồi. VNLF sẽ trả lời ngay tại trang này, bạn lưu lại link để xem sau.';
  final noiDungBanGui = 'Nội dung bạn gửi';
  final thietBi = 'Thiết bị';
  final xemHoSoPhanCung = 'Xem hồ sơ phần cứng trên linux-hardware.org';
  final heThong = 'CaramOS {caramos} · kernel {kernel}';
  final liveUsb = 'Live USB';
  final mayAo = 'Máy ảo';
  final kemAnhVaVideo = 'Kèm {images} ảnh và {videos} video.';
  final kemAnh = 'Kèm {count} ảnh.';
  final kemVideo = 'Kèm {count} video.';
  final hoiThem =
      'Muốn hỏi thêm hoặc giúp người khác? Tham gia cộng đồng VNLF.';
  final vaoVnlf = 'Vào VNLF';
  final congDong = 'Cộng đồng VNLF';
  final dangCongKhai =
      'Yêu cầu đang hiện ở trang Hỗ trợ CaramOS để cộng đồng cùng giúp.';
  final choDuyet =
      'Bạn đã cho cộng đồng xem. VNLF duyệt xong sẽ đăng lên trang Hỗ trợ CaramOS.';
  final khongChiaSe = 'Yêu cầu này chỉ VNLF xem được.';
  final xemTrangCongKhai = 'Xem trang công khai';
  final ngungChiaSe = 'Ngừng chia sẻ';
  final choCongDongXem = 'Cho cộng đồng xem';
  final lienHeKhongCongKhai = 'Thông tin liên hệ không công khai.';
  final cauTraLoiCongDong = 'Câu trả lời từ cộng đồng';
  final huuIch = '{count} hữu ích';
  final cachNayDaGiup = 'Cách này đã giúp tôi';
  final daGiupBan = 'Đã giúp bạn';
  final boChon = 'Bỏ chọn';
  final chuaLuuDuoc = 'Chưa lưu được lựa chọn. Thử lại sau ít phút.';
}

final class ViPoll {
  const ViPoll._();
  final binhChon = 'Bình chọn: {question}';
  final phanTram = '{share}%';
  final luotBinhChon = '{count} lượt bình chọn';
  final bamLaiDeBo = 'Bấm lại lựa chọn của bạn để bỏ';
  final chuaLuuDuoc = 'Chưa lưu được bình chọn. Thử lại sau ít phút.';
  final cauHoi = 'Câu hỏi';
  final cauHoiGoiY = 'Ví dụ: Bạn dùng distro nào?';
  final luaChon = 'Lựa chọn';
  final luaChonSo = 'Lựa chọn {value}';
  final boLuaChon = 'Bỏ lựa chọn {value}';
  final themLuaChon = 'Thêm lựa chọn';
  final taoBinhChon = 'Tạo bình chọn';
  final themBinhChon = 'Thêm bình chọn';
  final boBinhChon = 'Bỏ bình chọn';
  final guiBinhChon = 'Gửi bình chọn';
  final canCauHoiVaLuaChon = 'Cần câu hỏi và ít nhất 2 lựa chọn khác nhau.';
  final suaBinhChon = 'Sửa bình chọn';
  final daCoNguoiBinhChon = 'Đã có người bình chọn';
  final chiSuaKhiChuaAiBinhChon = 'Chỉ sửa được khi chưa ai bình chọn.';
}

final class ViShortcuts {
  const ViShortcuts._();
  final phimTat = 'Phím tắt';
  final chuyenNhanh = 'Chuyển nhanh';
  final timChat = 'Tìm channel hoặc tin nhắn riêng';
  final timChatGoiY = 'Tìm channel hoặc người…';
  final ketQua = 'Channel và tin nhắn riêng';
  final khongThayChat = 'Không thấy channel hay cuộc trò chuyện nào.';
  final goiYPhim = '↑ ↓ để chọn, Enter để mở, Esc để đóng';
  final chung = 'Chung';
  final moChuyenNhanh = 'Chuyển nhanh tới channel hoặc tin nhắn riêng';
  final chatTrenDuoi = 'Sang chat ở trên / ở dưới trong danh sách';
  final chatChuaDocTrenDuoi = 'Sang chat chưa đọc ở trên / ở dưới';
  final moBangPhimTat = 'Mở bảng phím tắt này';
  final khiNhanTin = 'Khi nhắn tin';
  final guiTin = 'Gửi tin nhắn';
  final xuongDong = 'Xuống dòng';
  final suaTinVuaGui = 'Sửa tin nhắn vừa gửi (khi ô nhắn đang trống)';
  final goiY = 'Mention thành viên, nhắc channel, chèn emoji theo tên (:tim:)';
  final dongGoiY = 'Đóng gợi ý, hủy trả lời hoặc đóng hộp thoại';
  final timTrongTinNhan = 'Tìm trong tin nhắn riêng đang mở';
  final batTatMic = 'Bật / tắt mic khi đang ở trong room';
  final phim = const <String, String>{
    'ctrl': 'Ctrl',
    'cmd': '⌘',
    'alt': 'Alt',
    'option': '⌥',
    'shift': 'Shift',
    'enter': 'Enter',
    'esc': 'Esc',
  };
}

final class ViCaramosSupport {
  const ViCaramosSupport._();
  final tieuDe = 'Hỗ trợ CaramOS';
  final metaTitle = '{id}: {title}';
  final moTa =
      'Người dùng CaramOS nhờ cộng đồng VNLF giúp về driver, cài đặt và lỗi hệ thống. Xem cách đã giải quyết hoặc trả lời giúp.';
  final gioiThieu =
      'Người dùng CaramOS nhờ giúp về driver, cài đặt và lỗi hệ thống. Bạn biết cách thì trả lời giúp nhé.';
  final cachNhoGiup =
      'Muốn nhờ giúp? Mở Driver Check hoặc "Góp ý & hỗ trợ" trong CaramOS rồi gửi. Thông tin liên hệ không công khai.';
  final trangChuCaramos = 'Trang chủ CaramOS';
  final locLoai = 'Lọc theo loại';
  final locTrangThai = 'Lọc theo trạng thái';
  final moiTrangThai = 'Mọi trạng thái';
  final trangThai = const <String, String>{
    'OPEN': 'Đang cần giúp',
    'IN_REVIEW': 'Đang cần giúp',
    'RESOLVED': 'Đã giải quyết',
    'CLOSED': 'Đã đóng',
    'DEFERRED': 'Để làm sau',
  };
  final trangThaiLoc = const <String, String>{
    'open': 'Đang cần giúp',
    'resolved': 'Đã giải quyết',
    'closed': 'Đã đóng',
  };
  final soTraLoi = '{count} trả lời';
  final daCoCachGiai = 'Đã có cách giải';
  final danhSach = 'Yêu cầu hỗ trợ CaramOS';
  final chuaCoYeuCau = 'Chưa có yêu cầu nào';
  final chuaCoYeuCauMoTa =
      'Yêu cầu chỉ hiện ở đây khi người gửi đồng ý và VNLF đã duyệt.';
  final chuaTaiDuoc = 'Chưa tải được danh sách.';
  final xemThem = 'Xem thêm';
  final nguoiDungCaramos = 'Người dùng CaramOS';
  final guiLuc = 'Người dùng CaramOS gửi lúc {time}';
  final anhVaVideo = 'Ảnh và video';
  final anhTuNguoiDung = 'Ảnh từ người dùng CaramOS';
  final videoTuNguoiDung = 'Video từ người dùng CaramOS';
  final cauTraLoi = '{count} câu trả lời';
  final cauTraLoiDung = 'Câu trả lời đúng';
  final chuaCoTraLoi =
      'Chưa có ai trả lời. Bạn biết cách thì giúp một tay nhé.';
  final noiDungTraLoi = 'Nội dung câu trả lời';
  final vietTraLoi =
      'Cách bạn nghĩ sẽ giúp được: driver cần cài, lệnh cần chạy…';
  final guiTraLoi = 'Gửi trả lời';
  final dangNhapDeTraLoi = 'Đăng nhập để trả lời';
  final daDongKhongTraLoi = 'Yêu cầu đã đóng, không nhận thêm câu trả lời.';
  final chuaGuiDuoc = 'Chưa gửi được câu trả lời. Thử lại sau ít phút.';
  final chuaLuuDuoc = 'Chưa lưu được thay đổi. Thử lại sau ít phút.';
  final huuIch = 'Hữu ích';
  final huuIchSo = '{count} người thấy hữu ích';
  final boHuuIch = 'Bỏ đánh dấu hữu ích';
  final danhDauHuuIch = 'Đánh dấu hữu ích';
  final chonLaDung = 'Chọn là đúng';
  final boChon = 'Bỏ chọn';
  final an = 'Ẩn';
  final hienLai = 'Hiện lại';
  final daAn = 'Đã ẩn';
  final baoCao = 'Báo cáo';
  final baoCaoTraLoi = 'Báo cáo câu trả lời';
  final daGuiBaoCao = 'Đã gửi báo cáo cho moderator.';
  final huongDanSai = 'Hướng dẫn sai hoặc nguy hiểm';
  final lacDe = 'Lạc đề';
  final suaTraLoi = 'Sửa câu trả lời';
  final xoaTraLoiHoi = 'Xóa câu trả lời?';
  final xoaTraLoiMoTa = 'Câu trả lời sẽ biến mất khỏi yêu cầu này.';
  final xoaTraLoi = 'Xóa câu trả lời';
  final daSua = ' · đã sửa';
  final moTrongHopGopY = 'Mở trong hộp góp ý';
  final quayLai = 'Mọi yêu cầu';
}

final class ViPageHelp {
  const ViPageHelp._();
  final troGiupSuDungVnlf = 'Hướng dẫn dùng VNLF Social';
  final huongDanDangBaiViet =
      'Cách đăng bài, viết Article, tham gia channel, nhắn tin riêng và vào voice room trên VNLF Social.';
  final troGiupVnlfSocial = 'Trợ giúp VNLF Social';
  final cacCauTraLoiNgan = 'Trả lời nhanh cho những việc hay gặp.';
  final taiKhoan = 'Tài khoản';
  final dangKyBangEmailUsername =
      'Đăng ký bằng email, username và mật khẩu. Hiện chưa cần xác minh email.';
  final nhanNutTaoMoiNhap =
      'Nhấn nút tạo mới, viết nội dung, thêm tiêu đề nếu cần rồi đăng.';
  final channelsVaTinNhanRieng = 'Channel và tin nhắn riêng';
  final ghiCong = 'Ghi công';
  final emojiTwemoji =
      'Emoji trên VNLF Social là bộ Twemoji của Twitter, dùng theo giấy phép CC-BY 4.0.';
  final logoSimpleIcons =
      'Logo distro và mạng xã hội (huy hiệu distro, nút liên kết trên trang cá nhân) thuộc về chủ sở hữu của chúng, chỉ dùng để nhận diện. Icon lấy từ Simple Icons, giấy phép CC0 1.0. Vài logo có giấy phép riêng: Debian (CC-BY-SA 3.0), Gentoo (CC-BY-SA 2.5), NixOS (CC-BY 4.0), Rocky Linux (CC-BY-SA 4.0), MX Linux và Garuda Linux (GPL-3.0), Fedora theo hướng dẫn thương hiệu của Fedora.';
  final channelsDanhChoThaoLuan =
      'Channel là nơi cả cộng đồng thảo luận, giống Discord. Tin nhắn riêng để trò chuyện trực tiếp, bắt đầu từ lời mời nhắn tin.';
}

final class ViPageLeaderboard {
  const ViPageLeaderboard._();
  final thanhVienDongGopNoi =
      'Những thành viên đóng góp nổi bật trong tuần ở cộng đồng Vietnam Linux Family.';
}

final class ViPageLogin {
  const ViPageLogin._();
  final dangNhapVnlfSocial = 'Đăng nhập VNLF Social.';
}

final class ViPageMessagesConversationid {
  const ViPageMessagesConversationid._();
  final cuocTroChuyenRieng = 'Cuộc trò chuyện riêng';
  final tinNhanRiengTuTren = 'Tin nhắn riêng trên VNLF Social.';
}

final class ViPageMessagesConversationidInfo {
  const ViPageMessagesConversationidInfo._();
  final thongTinCuocTroChuyen = 'Thông tin cuộc trò chuyện';
}

final class ViPagePrivacy {
  const ViPagePrivacy._();
  final chinhSachRiengTu = 'Chính sách riêng tư';
  final cachVnlfSocialThuThap =
      'VNLF Social thu thập, sử dụng và bảo vệ dữ liệu tài khoản, nội dung và hoạt động cộng đồng của bạn như thế nào.';
  final duLieuChiDuocThu =
      'Chúng tôi chỉ thu thập dữ liệu cần để vận hành tài khoản, cộng đồng và các tính năng được mô tả ở đây.';
  final duLieuTaiKhoan = 'Dữ liệu tài khoản';
  final emailUsernameProfileVaSession =
      'Email, username, hồ sơ và phiên đăng nhập được dùng để đăng nhập và bảo mật tài khoản.';
  final taiKhoanLienKet = 'Tài khoản liên kết';
  final taiKhoanLienKetMoTa =
      'Đăng nhập bằng Google hoặc Discord thì chúng tôi dùng email đã xác minh của tài khoản đó để tìm hoặc tạo tài khoản VNLF, và lưu mã tài khoản (Google lưu thêm email) để lần sau nhận ra bạn. Với Discord, chúng tôi lưu thêm username và tên hiển thị; username chỉ hiện công khai trên trang cá nhân khi bạn bật. Chúng tôi không lưu mật khẩu hay token của Google và Discord. Bỏ liên kết Discord trong Cài đặt → Bảo mật thì các thông tin Discord đó bị xóa.';
  final noiDungCongKhai = 'Nội dung công khai';
  final baiVietPublicCoThe =
      'Bài đăng công khai có thể xuất hiện trên công cụ tìm kiếm. Channel và tin nhắn riêng thì không.';
  final privateMessage = 'Tin nhắn riêng';
  final mvpChuaCoEndTo =
      'Tin nhắn riêng hiện chưa được mã hóa đầu cuối. Moderator chỉ xem bản lưu tin nhắn khi có báo cáo, và mọi lần truy cập đều được ghi lại.';
  final trangCaNhan = 'Trang cá nhân';
  final trangCaNhanCongKhai =
      'Ảnh bìa, hình nền, icon, nhạc và đồ trang trí bạn chọn cho trang cá nhân là công khai. Icon bạn tải lên kho chung thì ai cũng dùng được. Lời nhắn trong sổ lưu bút là công khai; chủ trang ẩn hoặc xóa được.';
  final boDemKhach = 'Bộ đếm khách';
  final boDemKhachMoTa =
      'Mỗi trang cá nhân đếm số người ghé thăm mỗi ngày. Chúng tôi nhận ra lượt ghé qua tài khoản của bạn, hoặc qua địa chỉ IP đã được biến đổi một chiều (không đọc ngược lại được) nếu bạn chưa đăng nhập. Không ai xem được danh sách người đã ghé. Dữ liệu theo ngày được xóa sau 90 ngày.';
  final nhacTuYoutube = 'Nhạc từ YouTube';
  final nhacTuYoutubeMoTa =
      'Trang cá nhân có nhạc dùng trình phát YouTube qua youtube-nocookie.com. Khi bạn mở trang đó, trình duyệt kết nối tới YouTube (Google) và YouTube có thể ghi nhận lượt xem theo chính sách của họ. Chọn “Chỉ phát khi bấm” hoặc “Tắt” trong Cài đặt → Hiển thị thì trình phát chỉ tải khi bạn bấm phát.';
}

final class ViPageRegister {
  const ViPageRegister._();
  final dangKy = 'Đăng ký';
  final taoTaiKhoanVnlfSocial = 'Tạo tài khoản VNLF Social.';
}

final class ViPageResetPassword {
  const ViPageResetPassword._();
  final taoMatKhauMoi = 'Tạo mật khẩu mới';
  final taoMatKhauMoiCho = 'Tạo mật khẩu mới cho VNLF Social.';
}

final class ViPageSearch {
  const ViPageSearch._();
  final timBaiVietThanhVien =
      'Tìm bài đăng, thành viên và chủ đề trên VNLF Social.';
}

final class ViPageSettingsNotifications {
  const ViPageSettingsNotifications._();
  final caiDatThongBao = 'Cài đặt thông báo';
}

final class ViPageStats {
  const ViPageStats._();
  final diemStreak = 'Điểm & streak';
}

final class ViPageTTag {
  const ViPageTTag._();
  final tieuDe = '#{name} — Linux, DevOps và mã nguồn mở';
  final baiVietHuongDanVa =
      'Bài viết, hướng dẫn và thảo luận về {name} trong cộng đồng Linux, mã nguồn mở Việt Nam.';
  final maNguonMo = 'mã nguồn mở';
  final chuDeTrenVnlfSocial = 'Chủ đề {name} trên VNLF Social';
  final chuDe = 'CHỦ ĐỀ';
  final baiVietPublicTrongCong = '{count} bài công khai trong cộng đồng.';
  final luotThich = '{displayName} · {likeCount} lượt thích';
  final xemBaiCuHon = 'Xem bài cũ hơn';
  final chuaCoBaiVoiTag =
      'Chưa có bài nào gắn #{name}. Bài đăng có hashtag này sẽ hiện ở đây.';
  final khamPhaChuDeKhac = 'Khám phá chủ đề khác';
}

final class ViPageUUsername {
  const ViPageUUsername._();
  final xemHoSoBaiViet =
      'Hồ sơ, bài đăng và hoạt động công khai của {displayName} trong cộng đồng Linux Việt Nam.';
  final trenVnlfSocial = '{displayName} trên VNLF Social';
}

final class ViPageVoiceRoomid {
  const ViPageVoiceRoomid._();
  final tieuDe = '{name} — Voice room';
  final voiceRoomRealtimeTrongCong =
      'Voice room trực tiếp trong cộng đồng VNLF.';
}

final class ViPeople {
  const ViPeople._();
  final tieuDe = 'Theo dõi của {name}';
  final nguoiTheoDoi = 'Người theo dõi';
  final dangTheoDoi = 'Đang theo dõi';
  final chuaCoNguoiTheoDoi = 'Chưa có ai theo dõi.';
  final chuaTheoDoiAi = 'Chưa theo dõi ai.';
  final chuaTaiDuoc = 'Chưa tải được danh sách.';
  final xemThem = 'Xem thêm';
  final ban = 'Bạn';
  final moDanhSach = 'Xem {label}';
  final chanNguoiNay = 'Chặn người này';
  final boChan = 'Bỏ chặn';
  final chanHoi = 'Chặn {name}?';
  final chanGiaiThich =
      'Hai bạn sẽ không thấy bài của nhau trên bảng tin, không nhắn tin, theo dõi hay mention được nhau. {name} không nhận được thông báo nào về việc này.';
  final daChan = 'Đã chặn {name}';
  final daBoChan = 'Đã bỏ chặn {name}';
  final chuaChanDuoc = 'Chưa chặn được. Thử lại sau.';
  final chuaBoChanDuoc = 'Chưa bỏ chặn được. Thử lại sau.';
  final banDaChan = 'Bạn đã chặn người này.';
  final nguoiDaChan = 'Người bạn đã chặn';
  final nguoiDaChanGiaiThich =
      'Họ không thấy bài của bạn trên bảng tin, không nhắn tin, theo dõi hay mention được bạn. Bỏ chặn bất cứ lúc nào.';
  final chuaChanAi = 'Bạn chưa chặn ai.';
}

final class ViPushSettings {
  const ViPushSettings._();
  final chromeChuaDuocCapQuyen =
      'Trình duyệt chưa cho phép thông báo. Bạn có thể bật lại trong cài đặt trình duyệt.';
  final chuaTheBatThongBao =
      'Chưa bật được thông báo đẩy. Kiểm tra kết nối rồi thử lại.';
  final dongLoiMoiThongBao = 'Đóng lời mời thông báo';
  final batThongBaoVnlf = 'Bật thông báo VNLF?';
  final nhanNgayTinNhanRieng =
      'Nhận ngay tin nhắn riêng và khi có người mention bạn trong channel.';
  final deSau = 'Để sau';
  final dangBat = 'Đang bật…';
  final batThongBao = 'Bật thông báo';
  final chuaKiemTraDuocThong = 'Chưa kiểm tra được trạng thái thông báo đẩy.';
  final daBatDmVaMention =
      'Đã bật. Tin nhắn riêng và lượt mention trong channel sẽ báo ngay khi bạn không mở tab VNLF, miễn là trình duyệt vẫn đang chạy.';
  final trinhDuyetTuChoiDang =
      'Trình duyệt từ chối đăng ký thông báo đẩy. Kiểm tra quyền thông báo rồi thử lại ở cửa sổ thường (không ẩn danh).';
  final chuaBatDuocThongBao =
      'Chưa bật được thông báo đẩy. Kiểm tra kết nối mạng rồi thử lại.';
  final thongBaoThietBiDa = 'Đã tắt thông báo đẩy.';
  final chuaTatDuocThongBao = 'Chưa tắt được thông báo đẩy. Thử lại nhé.';
  final dayLaThongBaoThu = 'Đây là thông báo thử.';
  final daYeuCauHienThi =
      'Đã gửi thông báo thử. Nếu không thấy, kiểm tra quyền thông báo của trình duyệt và hệ điều hành.';
  final chromeChuaTheHienThi =
      'Trình duyệt chưa hiện được thông báo thử. Kiểm tra quyền thông báo của trang và hệ điều hành.';
  final thongBaoTrenThietBi = 'Thông báo đẩy';
  final dmLoiMoiVaMention =
      'Tin nhắn riêng, lời mời và lượt mention trong channel sẽ báo ngay khi tab VNLF chạy nền hoặc đã đóng. Khi bạn đang mở tab VNLF, thông báo chỉ hiện trong trang. Mention trong bình luận được gộp lại cho đỡ phiền.';
  final trenDesktopChromeProfilePhai =
      'Trên máy tính, trình duyệt cần còn chạy: thu nhỏ cửa sổ thay vì đóng hết. Trên iPhone, thêm VNLF Social vào màn hình chính trước khi bật.';
  final tatThongBaoThietBi = 'Tắt thông báo đẩy';
  final batThongBaoThietBi = 'Bật thông báo đẩy';
  final guiThongBaoThu = 'Gửi thông báo thử';
  final trinhDuyetNayChuaHo = 'Trình duyệt này chưa hỗ trợ thông báo đẩy.';
  final mayChuChuaCauHinh = 'Máy chủ chưa bật thông báo đẩy.';
  final braveCanBatDichVuDay =
      'Dùng Brave? Mở brave://settings/privacy, bật "Use Google services for push messaging" rồi khởi động lại Brave trước khi bật thông báo đẩy.';
  final braveChuaBatDichVuDay =
      'Brave đang tắt dịch vụ thông báo đẩy. Mở brave://settings/privacy, bật "Use Google services for push messaging", khởi động lại Brave rồi bật lại ở đây.';
}

final class ViReactionPicker {
  const ViReactionPicker._();
  final yeuThich = 'Yêu thích';
  final haha = 'Haha';
  final ngacNhien = 'Ngạc nhiên';
  final buon = 'Buồn';
  final phanNo = 'Phẫn nộ';
  final thich = 'Thích';
  final tuyetVoi = 'Tuyệt vời';
  final chucMung = 'Chúc mừng';
  final voTay = 'Vỗ tay';
  final hoanHao = 'Hoàn hảo';
  final camOn = 'Cảm ơn';
  final suyNghi = 'Suy nghĩ';
  final yeuThichNhieu = 'Yêu quá';
  final mimCuoi = 'Mỉm cười';
  final dongY = 'Đồng ý';
  final dangXem = 'Đang xem';
  final hoanThanh = 'Xong rồi';
  final tienLen = 'Chiến thôi';
  final chonBieuCam = 'Chọn cảm xúc';
  final bieuCamNhanh = 'Cảm xúc nhanh';
  final themBieuCam = 'Thêm cảm xúc';
  final timEmoji = 'Tìm emoji';
  final timEmojiGoiY = 'Tìm theo tên, ví dụ: cười, tim, cánh cụt';
  final khongThayEmoji = 'Không thấy emoji nào.';
  final dangTaiEmoji = 'Đang tải emoji…';
  final chuaTaiDuocEmoji = 'Chưa tải được danh sách emoji.';
  final taiLai = 'Tải lại';
  final dungGanDay = 'Dùng gần đây';
  final nhomEmoji = 'Nhóm emoji';
  final nhom = const <String, String>{
    'smileys': 'Mặt cười & cảm xúc',
    'people': 'Người & cơ thể',
    'animals': 'Động vật & thiên nhiên',
    'food': 'Đồ ăn & thức uống',
    'travel': 'Du lịch & địa điểm',
    'activities': 'Hoạt động',
    'objects': 'Đồ vật',
    'symbols': 'Ký hiệu',
    'flags': 'Cờ',
  };
  final doiCamXucNhanh = 'Đổi cảm xúc nhanh';
  final chonOCanDoi = 'Chọn một ô bên trên, rồi chọn emoji để thay vào.';
  final oCamXuc = 'Ô cảm xúc {value}: {emoji}';
  final veMacDinh = 'Về mặc định';
  final luu = 'Lưu';
  final dangLuu = 'Đang lưu…';
  final chuaLuuDuoc = 'Chưa lưu được cảm xúc nhanh. Thử lại sau nhé.';
  final thuGon = 'Thu gọn';
}

final class ViRouteFeedxml {
  const ViRouteFeedxml._();
  final moTaKenh = 'Cộng đồng Linux và mã nguồn mở Việt Nam.';
}

final class ViSearchView {
  const ViSearchView._();
  final chuDeNhieuBai = 'Chủ đề nhiều bài';
  final soBai = '{count} bài';
  final chuDe = 'Chủ đề';
  final duAn = 'Dự án';
  final timThanhVienBaiViet = 'Tìm thành viên, bài viết, chủ đề, dự án';
  final tuKhoaTimKiem = 'Từ khóa tìm kiếm';
  final xoaTuKhoa = 'Xóa từ khóa';
  final loaiKetQuaTimKiem = 'Loại kết quả tìm kiếm';
  final nhapItNhat2Ky = 'Nhập ít nhất 2 ký tự';
  final banMuonTimGi = 'Bạn muốn tìm gì?';
  final timTheoTenThanhVien =
      'Tìm theo tên thành viên, nội dung bài hoặc chủ đề như Linux, CaramOS.';
  final dangTimKiem = 'Đang tìm…';
  final chuaTaiDuocKetQua = 'Chưa tải được kết quả';
  final kiemTraKetNoiVa = 'Kiểm tra kết nối rồi thử lại. Từ khóa vẫn được giữ.';
  final ketQuaCho = 'Kết quả cho';
  final chuaTimThayKetQua = 'Không tìm thấy kết quả';
  final thuTenNganHonBo =
      'Thử từ khóa ngắn hơn, gõ không dấu hoặc chọn loại kết quả khác.';
  final hienThi20ThanhVien =
      'Đang hiện 20 thành viên đầu tiên. Thêm từ khóa để lọc bớt.';
  final xemHoSo = 'Xem hồ sơ {displayName}';
  final baiVietCoAnhDinh = 'Bài có ảnh đính kèm';
  final article = 'Article';
  final hienThi20BaiMoi =
      'Đang hiện 20 bài mới nhất phù hợp. Thêm từ khóa để lọc bớt.';
}

final class ViSelect {
  const ViSelect._();
  final chon = 'Chọn';
}

final class ViSeo {
  const ViSeo._();
  final congDongLinuxMaNguon =
      'Cộng đồng Linux & Mã nguồn mở Việt Nam | VNLF Social';
  final vnlfSocialLaCongDong =
      'VNLF Social là cộng đồng Linux và mã nguồn mở Việt Nam: chia sẻ kiến thức, dự án, bài viết kỹ thuật, trò chuyện và kết nối cùng Vietnam Linux Family.';
}

final class ViSettingsViews {
  const ViSettingsViews._();
  final coChu = 'Cỡ chữ';
  final coChuMoTa =
      'Kéo để đổi cỡ chữ cả trang, đổi ngay khi kéo. Lưu trên thiết bị này.';
  final coChuPx = '{size}px';
  final coChuXemThu = 'Chữ trong bài, bình luận và tin nhắn sẽ to cỡ này.';
  final coChuMacDinh = 'Mặc định ({size}px)';
  final yeuCauXoaTaiKhoan = 'Yêu cầu xóa tài khoản?';
  final taiKhoanCo30Ngay =
      'Bạn có 30 ngày để hủy yêu cầu. Sau đó tài khoản sẽ được ẩn danh.';
  final yeuCauXoa = 'Yêu cầu xóa';
  final chuaTheGuiYeuCau = 'Chưa gửi được yêu cầu xóa tài khoản';
  final nhapMatKhauHienTai = 'Nhập mật khẩu hiện tại để đổi email';
  final chuaTheLuuThongTin = 'Chưa lưu được thông tin tài khoản';
  final thongTinTaiKhoan = 'Thông tin tài khoản';
  final nhungThongTinHienThi = 'Thông tin hiển thị trên hồ sơ của bạn.';
  final tenHienThi = 'Tên hiển thị';
  final username = 'Username';
  final email = 'Email';
  final matKhauHienTai = 'Mật khẩu hiện tại';
  final matKhauHienTaiDe = 'Mật khẩu hiện tại để đổi email';
  final giaoDien = 'Giao diện';
  final mvpHienDungTiengViet =
      'Hiện chỉ có tiếng Việt, các ngôn ngữ khác sẽ có sau.';
  final luonSang = 'Luôn dùng giao diện sáng.';
  final luonToi = 'Luôn dùng giao diện tối.';
  final tuDong = 'Tự động';
  final theoMay = 'Sáng hay tối theo cài đặt của máy.';
  final tiengViet = 'Tiếng Việt';
  final ngonNguDuyNhatTrong = 'Ngôn ngữ duy nhất hiện có';
  final giuTaiKhoanCuaBan = 'Giữ tài khoản của bạn an toàn.';
  final doiMatKhau = 'Đổi mật khẩu';
  final quanLyPasswordVaPhien = 'Quản lý mật khẩu và phiên đăng nhập';
  final yeuCauXoaTaiKhoan2 = 'Yêu cầu xóa tài khoản';
  final kiemSoatAiCoThe =
      'Chọn ai được tương tác với bạn và thông tin nào được công khai.';
  final aiCoTheGuiPrivate = 'Ai được gửi tin nhắn riêng';
  final hienThiLeaderboard = 'Hiện trên bảng xếp hạng';
  final hienThiTrangThaiOnline = 'Hiện trạng thái trực tuyến';
  final chonCacHoatDongBan = 'Chọn những hoạt động bạn muốn nhận thông báo.';
  final luotThich = 'Lượt thích';
  final theoDoiMoi = 'Theo dõi mới';
  final binhLuanTraLoiVa = 'Bình luận, trả lời và mention';
  final amBaoTinNhan = 'Âm báo tin nhắn';
  final darkModeDoiTaiTrang = 'Giao diện sáng/tối đổi ở trang Cài đặt chính.';
  final giamChuyenDong = 'Giảm chuyển động';
  final chuaTheLuuCaiDat = 'Chưa lưu được cài đặt';
  final dangBat = 'Đang bật';
  final dangTat = 'Đang tắt';
  final chonJpgPngWebpHoac =
      'Chọn ảnh JPG, PNG, WebP dưới 10MB hoặc GIF dưới 8MB.';
  final daCapNhatAnhDai = 'Đã cập nhật ảnh đại diện';
  final chuaTheLuuHoSo = 'Chưa lưu được hồ sơ';
  final anhDaiDien = 'Ảnh đại diện';
  final jpgPngWebpHoacGif =
      'JPG, PNG, WebP tối đa 10MB. GIF tối đa 8MB, giữ chuyển động trên trang cá nhân.';
  final chonAnhDaiDien = 'Chọn ảnh đại diện';
  final doiAnh = 'Đổi ảnh';
  final gioiThieu = 'Giới thiệu';
  final website = 'Website';
  final daCapNhatMatKhau =
      'Đã đổi mật khẩu. Các thiết bị khác đã bị đăng xuất.';
  final trinhDuyetTren = '{browser} trên {os}';
  final khongTheCapNhatMat = 'Chưa đổi được mật khẩu. Thử lại sau ít phút.';
  final matKhauPhienDangNhap = 'Mật khẩu & phiên đăng nhập';
  final matKhauMoiCanToi = 'Mật khẩu mới cần ít nhất 10 ký tự.';
  final matKhauMoi = 'Mật khẩu mới';
  final nhapLaiMatKhauMoi = 'Nhập lại mật khẩu mới';
  final matKhauNhapLaiChua = 'Mật khẩu nhập lại chưa khớp.';
  final dangCapNhat = 'Đang cập nhật…';
  final capNhatMatKhau = 'Đổi mật khẩu';
  final phienDangNhap = 'Phiên đăng nhập';
  final thietBiDangDangNhap = 'Các thiết bị đang đăng nhập tài khoản này.';
  final chuaTaiDuocDanhSach = 'Chưa tải được danh sách phiên đăng nhập.';
  final thietBiKhongXacDinh = 'Thiết bị không xác định';
  final hoatDong = 'Hoạt động {value}';
  final hienTai = 'Thiết bị này';
  final daDangXuatThietBi = 'Đã đăng xuất thiết bị';
  final chuaTheDangXuatThiet = 'Chưa đăng xuất được thiết bị';
  final dangXuat = 'Đăng xuất';
  final daDangXuatCacThiet = 'Đã đăng xuất các thiết bị khác';
  final chuaTheDangXuatCac = 'Chưa đăng xuất được các thiết bị khác';
  final dangXuatTatCaThiet = 'Đăng xuất tất cả thiết bị khác';
  final caiDatTaiKhoan = 'Cài đặt tài khoản';
  final taiKhoan = 'Tài khoản';
}

final class ViLinkedAccounts {
  const ViLinkedAccounts._();
  final taiKhoanLienKet = 'Tài khoản liên kết';
  final moTa =
      'Google và Discord dùng để đăng nhập. Username Discord chỉ hiện dưới phần giới thiệu khi bạn bật "Hiện trên trang cá nhân", để mọi người nhận ra bạn trên Discord.';
  final google = 'Google';
  final discord = 'Discord';
  final daLienKet = 'Đã liên kết';
  final daLienKetEmail = 'Đã liên kết · {email}';
  final chuaLienKet = 'Chưa liên kết';
  final googleCachLienKet =
      'Đăng nhập bằng Google với cùng email là tự liên kết.';
  final lienKetDiscord = 'Liên kết Discord';
  final boLienKet = 'Bỏ liên kết';
  final dangBoLienKet = 'Đang bỏ liên kết…';
  final boLienKetHoi = 'Bỏ liên kết Discord?';
  final boLienKetMoTa =
      'Bạn sẽ không đăng nhập bằng Discord này được nữa, và username Discord không còn hiện trên trang cá nhân. Nếu bạn tạo tài khoản bằng Discord, đặt mật khẩu ở "Quên mật khẩu" trước khi bỏ. Bạn liên kết lại được bất cứ lúc nào.';
  final hienTrenTrangCaNhan = 'Hiện trên trang cá nhân';
  final chuaLuuDuoc = 'Chưa lưu được. Thử lại nhé.';
  final daBoLienKet = 'Đã bỏ liên kết Discord';
  final chuaBoLienKetDuoc = 'Chưa bỏ liên kết được. Thử lại sau.';
  final chuaTaiDuoc = 'Chưa tải được tài khoản liên kết.';
  final ketQua = const <String, String>{
    'linked':
        'Đã liên kết Discord. Username của bạn giờ hiện trên trang cá nhân.',
    'taken': 'Tài khoản Discord này đã liên kết với một tài khoản VNLF khác. Bỏ liên kết ở tài khoản đó trước rồi thử lại.',
    'denied': 'Bạn đã hủy liên kết ở Discord.',
    'error': 'Chưa liên kết được Discord. Thử lại nhé.',
  };
}

final class ViSocialChrome {
  const ViSocialChrome._();
  final giaoDien = 'Giao diện';
  final tuDongTheoMay = 'Tự động theo máy';
  final phongThoaiDangMo = 'Voice room';
  final vnlfTrenDiscord = 'Discord VNLF';
  final vnlfTrenTelegram = 'Telegram VNLF';
  final vnlfTrenFacebook = 'Facebook VNLF';
  final bangTin = 'Bảng tin';
  final khamPha = 'Khám phá';
  final hoTroCaramos = 'Hỗ trợ CaramOS';
  final duAn = 'Dự án';
  final thuGonThanhBen = 'Thu gọn thanh bên';
  final moRongThanhBen = 'Mở rộng thanh bên';
  final yeuCauChuaAiTraLoi = '{count} yêu cầu chưa có ai trả lời';
  final activeDaKetNoi = 'Đã kết nối';
  final inactiveDangKetNoi = 'Đang kết nối…';
  final inactiveDangNoiLai = 'Đang kết nối lại…';
  final inactiveMatKetNoi = 'Mất kết nối';
  final moMenu = 'Mở menu';
  final moHoSo = 'Mở hồ sơ';
  final dongMenu = 'Đóng menu';
  final dungDayDuTinhNang = 'Để dùng đầy đủ tính năng';
  final dieuHuongChinh = 'Điều hướng chính';
  final coTinNhanChuaDoc = 'Có tin nhắn chưa đọc';
  final cacMangXaHoiKhac = 'VNLF trên các mạng xã hội khác';
  final ketNoiCongDong = 'Kết nối cộng đồng';
  final troGiup = 'Trợ giúp';
  final dangXuat = 'Đăng xuất';
  final moTimKiem = 'Mở tìm kiếm';
  final batAmBao = 'Bật âm báo';
  final caiDatAmBaoVa = 'Cài đặt âm báo và thông báo';
  final amBaoThongBao = 'Âm báo & thông báo';
  final chuaKetNoiRealtimeTin =
      'Đang mất kết nối. Tin mới sẽ tự đồng bộ khi kết nối lại.';
  final dieuHuongMobile = 'Điều hướng trên điện thoại';
  final taoBaiViet = 'Tạo bài đăng';
  final voiceDaKetNoi = 'Đã vào voice room';
  final dangKetNoi = 'Đang kết nối…';
  final batMicrophone = 'Bật mic';
  final tatMicrophone = 'Tắt mic';
  final roiVoiceRoom = 'Rời voice room';
  final xpCuaBan = 'XP của bạn';
  final xemDiem = 'Xem điểm';
  final xp = 'XP';
  final level = 'Level {value}';
  final capCaoNhat = 'Level cao nhất';
  final ngayStreak = 'Streak {value} ngày';
  final live = 'LIVE';
  final nguoiDangKetNoi = '{participantCount} người đang trong room';
  final thamGia = 'Tham gia';
  final bangDiemTuan = 'Xếp hạng tuần';
  final xemTatCa = 'Xem tất cả';
  final vnlfSocial2026 = 'VNLF Social · 2026';
}

final class ViSocialLayoutClient {
  const ViSocialLayoutClient._();
  final moderationReports = 'Báo cáo vi phạm';
  final thanhVienChannel = 'Thành viên channel';
  final caiDatChannel = 'Cài đặt channel';
  final diemStreak = 'Điểm & streak';
  final caiDatThongBao = 'Cài đặt thông báo';
  final diemHeSoStreak = 'Điểm & hệ số streak';
  final quanLyThanhVien = 'Quản lý thành viên';
  final quanTriCongDong = 'Quản trị cộng đồng';
  final chuDe = 'Chủ đề #{pathname}';
  final khamPhaCongDong = 'Khám phá cộng đồng';
  final bangTin = 'Bảng tin';
  final dangKiemTraPhienDang = 'Đang kiểm tra phiên đăng nhập…';
}

final class ViSocialOverlays {
  const ViSocialOverlays._();
  final chiaSe = 'Chia sẻ';
  final guiBaiVietNay = 'Chia sẻ bài này';
  final baiVietTuVnlfSocial = 'Bài từ VNLF Social';
  final email = 'Email';
  final daSaoChepLienKet = 'Đã sao chép liên kết';
  final saoChep = 'Sao chép';
  final chuaTheCapNhatBai = 'Chưa cập nhật được bài đã lưu';
  final chuaTheAnBaiViet = 'Chưa ẩn được bài';
  final tuyChonBaiViet = 'Tùy chọn bài';
  final saoChepLienKet = 'Sao chép liên kết';
  final anBaiViet = 'Ẩn bài';
  final suaBai = 'Sửa bài';
  final xoaBai = 'Xóa bài';
  final xoaBaiNay = 'Xóa bài này?';
  final baiSeBienMat =
      '“{title}” sẽ biến mất khỏi bảng tin và hồ sơ của bạn. Không khôi phục được.';
  final daXoaBai = 'Đã xóa bài';
  final chuaXoaDuocBai = 'Chưa xóa được bài. Thử lại sau.';
  final daGuiBaoCaoBai = 'Đã gửi báo cáo bài {articleSlug} tới admin';
  final chuaTheGuiBaoCao = 'Chưa gửi được báo cáo. Thử lại sau.';
  final baoCaoBaiViet = 'Báo cáo bài';
  final anToanCongDong = 'An toàn cộng đồng';
  final lyDo = 'Lý do';
  final lyDoBaoCao = 'Lý do báo cáo';
  final chonLyDo = 'Chọn lý do';
  final spamHoacQuangCao = 'Spam hoặc quảng cáo';
  final quayRoi = 'Quấy rối';
  final thongTinSaiLech = 'Thông tin sai lệch';
  final khac = 'Khác';
  final moTaThem = 'Mô tả thêm';
  final choQuanTriVienBiet = 'Kể cho admin chuyện gì đã xảy ra…';
  final guiBaoCao = 'Gửi báo cáo';
}

final class ViSocialRuntime {
  const ViSocialRuntime._();
  final nhanBinhLuan = 'Nhận bình luận';
  final baiDangNhanBinhLuan = 'Có người bình luận vào bài của bạn';
  final bayGio = 'Vừa xong';
  final phut = '{minutes} phút';
  final gio = '{hours} giờ';
  final ngay = '{Math} ngày';
  final coNguoi = 'Có người';
  final va = ' và ';
  final vaNguoiKhac = '{names} và {value} người khác';
  final noiDungCuaBan = 'nội dung của bạn';
  final daThichBaiVietCua = '{actors} đã thích bài viết của bạn';
  final daThichBinhLuanCua = '{actors} đã thích bình luận của bạn';
  final daNhacDenBanTrong = '{actors} đã mention bạn trong bình luận';
  final daTraLoiBinhLuan = '{actors} đã trả lời bình luận của bạn';
  final daBinhLuanVeBai = '{actors} đã bình luận về bài viết của bạn';
  final binhLuanMoi = '{eventCount} bình luận mới · {target}';
  final daTheoDoiBan = '{actors} đã theo dõi bạn';
  final thanhVienMoiTheoDoi = '{actorCount} thành viên mới theo dõi';
  final followerMoi = 'Người theo dõi mới';
  final banCoHoatDongMoi = 'Bạn có hoạt động mới';
  final dangBaiThuong = 'Đăng bài thường';
  final baiDangDaDuocXuat = 'Bài đăng đã lên bảng tin';
  final dangArticle = 'Đăng Article';
  final articleDaDuocXuatBan = 'Bài viết dài đã được đăng';
  final nhanLuotThich = 'Nhận lượt thích';
  final baiDangNhanLuotThich = 'Bài của bạn có lượt thích mới';
  final binhLuanMoiDuocGhi = 'Bạn vừa bình luận';
  final binhLuanNhanLuotThich = 'Bình luận của bạn có lượt thích mới';
  final thaoLuanTrongChannel = 'Trò chuyện trong channel';
  final hoatDongChatHopLe = 'Tham gia trò chuyện tích cực';
  final baoCaoHuuIch = 'Báo cáo hữu ích';
  final baoCaoDaDuocXac = 'Báo cáo của bạn đã được xác nhận';
  final gopYSanPham = 'Góp ý sản phẩm';
  final gopYDaDuocHe = 'Đã nhận góp ý của bạn';
  final baoLoiSanPham = 'Báo lỗi sản phẩm';
  final baoLoiDaDuocHe = 'Đã nhận báo lỗi của bạn';
  final duAnDuocDuyet = 'Dự án được duyệt';
  final duAnCuaBanDuocDuyet = 'Dự án của bạn đã lên trang Dự án';
  final gioiThieuDuAn = 'Giới thiệu dự án';
  final duAnBanGioiThieuDuocDuyet = 'Dự án bạn giới thiệu đã được duyệt';
  final diemHoatDong = 'Điểm hoạt động';
  final daXuLy = 'Đã xử lý';
}

final class ViStatsViews {
  const ViStatsViews._();
  final ngayLienTiep = 'Streak {value} ngày';
  final moiNgayMotLanGhe = 'Mỗi ngày ghé một lần.';
  final dangNhapMoiNgayDe =
      'Đăng nhập mỗi ngày để giữ streak. Ngày mới tính theo giờ Việt Nam.';
  final ngay = 'ngày';
  final lichHoatDong = 'Lịch hoạt động';
  final chonMotNgayDeXem = 'Chọn một ngày để xem điểm hôm đó.';
  final khoangThongKe = 'Khoảng thống kê';
  final thang = 'Tháng';
  final nam = 'Năm';
  final thangThongKe = 'Tháng thống kê';
  final thang2 = 'Tháng {value}';
  final namThongKe = 'Năm thống kê';
  final dangTaiLich = 'Đang tải lịch…';
  final chuaTaiDuocLichThu = 'Chưa tải được lịch. Thử lại';
  final tuNgay = 'Từ ngày';
  final denNgay = 'Đến ngày';
  final apDung = 'Áp dụng';
  final khoangNgayToiDa366 =
      'Chọn tối đa 366 ngày; ngày kết thúc không được trước ngày bắt đầu.';
  final gioVietNam = '{from} – {to} · Giờ Việt Nam';
  final dangTinhDiem = 'Đang tính điểm…';
  final chuaTaiDuocTongDiem = 'Chưa tải được tổng điểm.';
  final tongDiemTrongKhoang = 'Tổng điểm trong khoảng';
  final xp = '{value} XP';
  final diemNhanDuoc = 'Điểm nhận được';
  final diemDieuChinhGiam = 'Điểm bị trừ';
  final xpTichLuy = 'XP tích lũy';
  final lichDiemDanh = 'Lịch điểm danh';
  final ngayDaGheThamTrong =
      'Đã ghé {value} ngày trong kỳ · Streak dài nhất {value2} ngày';
  final lichSu = 'Lịch sử';
  final diemGanDay = 'Điểm gần đây';
  final chuaCoDiemDiemDanh =
      'Chưa có điểm. Ngày nào bạn đăng nhập vẫn được tính điểm danh.';
  final xemToanBoLichSu = 'Xem toàn bộ lịch sử';
  final xpLedger = 'Sổ XP';
  final tongQuan = 'Tổng quan';
  final locLichSuDiem = 'Lọc lịch sử điểm';
  final chuaCoDiemTrongMuc = 'Chưa có điểm trong mục này.';
  final xp2 = '{points} XP';
}

final class ViVoiceContext {
  const ViVoiceContext._();
  final vuaVaoPhong = '{label} vừa vào room';
  final moderationTuGiaoDien = 'Kiểm duyệt trong voice room';
}

final class ViVoiceView {
  const ViVoiceView._();
  final loaSo = 'Loa {number}';
  final micSo = 'Mic {number}';
  final chuaChanDuoc = 'Chưa chặn được {name}';
  final chuaBoChanDuoc = 'Chưa bỏ chặn được {name}';
  final chuaGuiDuocTinNhan = 'Chưa gửi được tin nhắn. Nội dung vẫn còn nguyên.';
  final trinhDuyetKhongChoPhep =
      'Trình duyệt không cho tự sao chép. Bạn sao chép tay nhé.';
  final chuaCoMicrophoneTrackDe = '{name} chưa bật mic nên chưa khóa mic được';
  final daServerMute = 'Đã khóa mic của {name}';
  final daBanKhoiRoom = 'Đã cấm {name} khỏi room';
  final daNgatKetNoi = 'Đã ngắt kết nối {name}';
  final chuaTheThucHienThao = 'Chưa xử lý được với {name}. Thử lại sau.';
  final daGuiReport = 'Đã báo cáo {label}';
  final chuaTheGuiReportVoice = 'Chưa gửi được báo cáo';
  final vnlfVoice = 'VNLF Voice';
  final voiceRooms = 'Voice rooms';
  final nguoiDangKetNoi = '{count} người đang trong room';
  final chuaCoAiTrongRoom = 'Chưa có ai trong room';
  final nhanRoomDeVaoNgay =
      'Nhấn vào room để vào ngay. Mic luôn tắt khi mới vào.';
  final danhSachRoom = 'Danh sách room';
  final chatTrongRoom = 'Chat trong room';
  final chat = 'Chat';
  final tuyChonVoiceRoom = 'Tùy chọn voice room';
  final daSaoChepLinkRoom = 'Đã sao chép link room';
  final saoChepLinkRoom = 'Sao chép link room';
  final batThongBao = 'Bật thông báo';
  final tatThongBao = 'Tắt thông báo';
  final daSaoChepLoiMoi = 'Đã sao chép lời mời';
  final moiNguoi = 'Mời bạn bè';
  final trinhDuyetDangChanPhat = 'Trình duyệt đang chặn tự phát âm thanh.';
  final batAmThanh = 'Bật âm thanh';
  final matKetNoiHoacDang = 'Mất kết nối mạng.';
  final dangKetNoiVao = 'Đang vào {name}…';
  final chuanBiAmThanhMicrophone =
      'Đang chuẩn bị âm thanh. Mic của bạn vẫn tắt.';
  final daBoChan = 'Đã bỏ chặn {name}';
  final daChan = 'Đã chặn {name}';
  final roomDangYenTinh = 'Room đang yên ắng';
  final vaoRoomDeBatDau = 'Vào room để bắt đầu trò chuyện.';
  final quayLaiRoom = 'Quay lại room';
  final chonMotRoom = 'Chọn một room';
  final tuyChonChat = 'Tùy chọn chat';
  final danhDauDaDoc = 'Đánh dấu đã đọc';
  final chuaCoTinNhanMo = 'Chưa có tin nhắn nào. Mở lời chào mọi người đi!';
  final tinNhanCua = 'tin nhắn của {name}';
  final tinMoi = 'Tin mới';
  final nhanTrong = 'Nhắn trong {name}';
  final report = 'Báo cáo';
  final baoCao = 'Báo cáo {label}';
  final moTaDieuModeratorCan = 'Kể cho moderator chuyện gì đã xảy ra…';
  final guiReport = 'Gửi báo cáo';
  final voiceCommunity = 'Voice';
  final chonRoomVaoNoiChuyen = 'Chọn room, vào nói chuyện.';
  final roomLuonMoChoThanh =
      'Room luôn mở cho thành viên VNLF. Mic của bạn sẽ tắt khi mới vào.';
  final vao = 'Vào {name}';
  final khongTimThayRoom = 'Không thấy room';
  final roomKhongTonTaiHoac = 'Room không tồn tại hoặc đã được lưu trữ.';
  final chonMotRoomKhacTrong = 'Chọn room khác ở danh sách bên trái.';
  final dangTaiVoiceRoom = 'Đang tải voice room…';
  final dongBoRoomVaThiet = 'Đang đồng bộ room và thiết lập âm thanh.';
  final tuyChon = 'Tùy chọn {name}';
  final xemTrangCaNhan = 'Xem trang cá nhân';
  final nhanTin = 'Nhắn tin';
  final boTatTieng = 'Bật tiếng lại';
  final tatTiengCucBo = 'Tắt tiếng (chỉ mình bạn)';
  final boChan2 = 'Bỏ chặn';
  final serverMute = 'Khóa mic';
  final ngatKetNoi = 'Ngắt kết nối';
  final banKhoiRoom = 'Cấm khỏi room';
  final ban = '{name} (Bạn)';
  final chuaKetNoi = 'Chưa kết nối';
  final batMic = 'Bật mic';
  final tatMic = 'Tắt mic';
  final batNghe = 'Bật nghe';
  final tatNghe = 'Tắt nghe';
  final thietBi = 'Thiết bị';
  final microphone = 'Mic';
  final microphoneMacDinh = 'Mic mặc định';
  final loa = 'Loa';
  final loaMacDinh = 'Loa mặc định';
  final chuaThayMicrophoneBatQuyen =
      'Chưa thấy mic. Cho phép trình duyệt dùng mic.';
  final thuMic = 'Thử mic';
  final mucAmMic = 'Mức âm của mic';
  final ngheLaiGiongMinh = 'Nghe lại giọng mình';
  final deoTaiNghe = 'Đeo tai nghe để không bị vọng tiếng.';
  final chuaMoDuocMic =
      'Chưa mở được mic. Kiểm tra quyền dùng mic của trình duyệt.';
  final xuLyAmThanh = 'Xử lý âm thanh';
  final locTiengOn = 'Lọc tiếng ồn';
  final khuTiengVong = 'Khử tiếng vọng';
  final tuCanAmLuong = 'Tự cân âm lượng';
  final xuLyAmThanhGoiY = 'Mic nhỏ hoặc mất tiếng thì tắt Lọc tiếng ồn.';
  final roiRoom = 'Rời room';
  final vaoRoom = 'Vào room';
  final dangKetNoi = 'Đang kết nối…';
  final dangKetNoiLai = 'Đang kết nối lại…';
  final loiKetNoi = 'Mất kết nối';
  final daKetNoi = 'Đã kết nối';
}

final class ViApi {
  const ViApi._();
  final activity = const ViApiActivity._();
  final admin = const ViApiAdmin._();
  final app = const ViApiApp._();
  final articles = const ViApiArticles._();
  final assets = const ViApiAssets._();
  final auth = const ViApiAuth._();
  final channels = const ViApiChannels._();
  final channelSend = const ViApiChannelSend._();
  final collections = const ViApiCollections._();
  final commentMedia = const ViApiCommentMedia._();
  final contentVotes = const ViApiContentVotes._();
  final cursor = const ViApiCursor._();
  final dm = const ViApiDm._();
  final dmSend = const ViApiDmSend._();
  final caramosHelp = const ViApiCaramosHelp._();
  final polls = const ViApiPolls._();
  final stickers = const ViApiStickers._();
  final projects = const ViApiProjects._();
  final caramosSupport = const ViApiCaramosSupport._();
  final feedback = const ViApiFeedback._();
  final gif = const ViApiGif._();
  final idempotency = const ViApiIdempotency._();
  final linkPreview = const ViApiLinkPreview._();
  final decor = const ViApiDecor._();
  final guestbook = const ViApiGuestbook._();
  final icons = const ViApiIcons._();
  final media = const ViApiMedia._();
  final messageAccess = const ViApiMessageAccess._();
  final push = const ViApiPush._();
  final rateLimit = const ViApiRateLimit._();
  final realtime = const ViApiRealtime._();
  final search = const ViApiSearch._();
  final users = const ViApiUsers._();
  final voice = const ViApiVoice._();
  final voiceChat = const ViApiVoiceChat._();
}

final class ViApiActivity {
  const ViApiActivity._();
  final khongTimThayTaiKhoan = 'Không tìm thấy tài khoản.';
  final chonKhoangNgayHopLe = 'Khoảng ngày không hợp lệ. Chọn tối đa 366 ngày.';
}

final class ViApiAdmin {
  const ViApiAdmin._();
  final lyDoMacDinh = 'Vi phạm quy định cộng đồng.';
  final cursorNotificationKhongHopLe =
      'Không tải thêm được thông báo. Tải lại trang rồi thử lại.';
  final binhLuanCuaBan = 'Bình luận của bạn';
  final binhLuanKhongConKha = 'Bình luận không còn hiển thị';
  final baiVietKhongTieuDe = 'Bài viết không tiêu đề';
  final chonNgayThuHaiCua = 'Chọn thứ Hai của tuần này hoặc một tuần trước đó.';
  final khongTimThayReport = 'Không tìm thấy báo cáo.';
  final cachXuLyKhongHopLe =
      'Cách xử lý này không dùng được cho loại báo cáo này.';
  final khongTheSuaOwnerQua = 'Không thể đổi quyền của Owner tại đây.';
  final chiOwnerDuocGanOwner = 'Chỉ Owner mới gán được quyền Owner.';
  final khongTheGanQuyenBang =
      'Bạn không thể gán quyền ngang hoặc cao hơn quyền của mình.';
  final khongTimThayBaiViet = 'Không tìm thấy bài viết.';
  final khongTheXuatBanBan = 'Không thể đăng bản nháp từ trang kiểm duyệt.';
}

final class ViApiApp {
  const ViApiApp._();
  final originKhongDuocPhep = 'Yêu cầu đến từ trang không được phép.';
  final crossSiteMutationKhongDuoc =
      'Không thể thực hiện thao tác này từ trang khác.';
  final duLieuGuiLenKhong =
      'Thông tin gửi lên không hợp lệ. Kiểm tra lại rồi thử lại.';
  final coLoiXayRa = 'Đã có lỗi xảy ra. Thử lại sau ít phút.';
}

final class ViApiArticles {
  const ViApiArticles._();
  final chiTacGiaGhim = 'Chỉ tác giả bài viết ghim được bình luận.';
  final khongTheTaoSlugDuy =
      'Chưa tạo được đường dẫn cho bài. Thử đổi tiêu đề rồi lưu lại.';
  final baiVietDangBiKiem =
      'Bài đang được kiểm duyệt nên bạn chưa khôi phục được.';
  final khongTimThayBaiViet = 'Không tìm thấy bài viết.';
  final motHoacNhieuAnhKhong = 'Có ảnh không hợp lệ hoặc chưa tải lên xong.';
  final khongTimThayBinhLuan = 'Không tìm thấy bình luận.';
  final anhBaiThuongPhaiLa = 'Ảnh trong bài đăng phải là ảnh đính kèm.';
  final draftDaDuocCapNhat =
      'Bản nháp vừa được sửa ở nơi khác. Tải lại để xem bản mới nhất.';
  final anhDinhKemBiTrung = 'Có ảnh đính kèm bị trùng.';
  final assetKhongThuocDraftNay = 'Ảnh này không thuộc bản nháp của bạn.';
  final thieuIdempotencyKey = 'Yêu cầu chưa đầy đủ. Tải lại trang rồi thử lại.';
  final baiVietCanNoiDung = 'Bài cần có chữ hoặc ảnh.';
  final baiVietCoQuaNhieu = 'Bài có quá nhiều ảnh.';
  final videoChiTrongBaiThuong =
      'Video chỉ đăng được trong bài thường, dạng tệp đính kèm.';
  final moiBaiMotVideo = 'Mỗi bài chỉ có 1 video.';
  final videoDangXuLy = 'Video vẫn đang xử lý. Đợi xong rồi đăng nhé.';
  final videoLoi = 'Video chưa xử lý được. Bỏ video đó rồi chọn video khác.';
  final baiVietMoi = 'Bài viết mới';
  final chiLuuTruDuocBai = 'Chỉ lưu trữ được bài đã đăng.';
  final chiKhoiPhucDuocBai = 'Chỉ khôi phục được bài đã đăng và đang lưu trữ.';
  final banCanDangNhapDe =
      'Đăng nhập để xem bảng tin từ những người bạn theo dõi.';
  final bangTinDaHetHan = 'Bảng tin đã cũ. Tải lại để xem bài mới.';
  final binhLuanCanNoiDung = 'Bình luận cần có chữ, ảnh, GIF hoặc sticker.';
  final mvpChiHoTroMot =
      'Chỉ trả lời được bình luận gốc, chưa hỗ trợ trả lời lồng nhau.';
  final maBinhLuanDaDuoc =
      'Bình luận này bị trùng với một bình luận khác. Tải lại rồi gửi lại.';
  final binhLuanKhongConKha = 'Bình luận không còn hiển thị.';
  final binhLuanCanCoNoi = 'Bình luận cần có chữ.';
}

final class ViApiAssets {
  const ViApiAssets._();
  final khongTimThayAsset = 'Không tìm thấy tệp.';
}

final class ViApiAuth {
  const ViApiAuth._();
  final emailHoacUsernameDaDuoc = 'Email hoặc username đã có người dùng.';
  final emailHoacMatKhauKhong = 'Email/username hoặc mật khẩu không đúng.';
  final taiKhoanDangChoXoa =
      'Tài khoản đang chờ xóa. Khôi phục tài khoản trước đã.';
  final taiKhoanHienKhongThe = 'Tài khoản này hiện không đăng nhập được.';
  final phienDangNhapDaHet =
      'Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục.';
  final khongTimThayPhienDang = 'Không tìm thấy phiên đăng nhập.';
  final matKhauHienTaiKhong = 'Mật khẩu hiện tại không đúng.';
  final neuEmailTonTaiHuong =
      'Nếu email này đã đăng ký, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.';
  final tokenDatLaiMatKhau =
      'Link đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.';
  final banCanDangNhap = 'Bạn cần đăng nhập.';
  final taiKhoanHienKhongThe2 =
      'Tài khoản của bạn hiện không làm được thao tác này.';
  final banKhongCoQuyenThuc = 'Bạn không có quyền làm việc này.';
  final banKhongTheXuLy =
      'Bạn không thể xử lý tài khoản có quyền ngang hoặc cao hơn mình.';
  final chuaLienKetDiscord = 'Bạn chưa liên kết Discord.';
}

final class ViApiChannels {
  const ViApiChannels._();
  final nhapItNhat2Ky = 'Nhập ít nhất 2 ký tự hoặc chọn người gửi.';
  final khongTimThayChannel = 'Không tìm thấy channel.';
  final banKhongCoQuyenTruy = 'Bạn không có quyền vào channel này.';
  final messageKhongThuocChannel = 'Tin nhắn không thuộc channel này.';
  final khongTimThayMessage = 'Không tìm thấy tin nhắn.';
  final tinNhanCanCoNoi = 'Tin nhắn cần có chữ.';
  final chiCoTheSuaTin = 'Chỉ sửa được tin nhắn trong 15 phút sau khi gửi.';
  final assetKhongThuocChannel = 'Ảnh không thuộc channel này.';
  final danhSachReorderPhaiChua =
      'Chưa sắp xếp được channel. Tải lại trang rồi thử lại.';
}

final class ViApiChannelSend {
  const ViApiChannelSend._();
  final khongCoQuyenGuiTin = 'Bạn không có quyền gửi tin nhắn ở đây.';
  final idTinNhanDaDuoc =
      'Tin nhắn bị trùng với một tin khác. Tải lại rồi gửi lại.';
  final tinNhanCanNoiDung = 'Tin nhắn cần có chữ hoặc ảnh.';
  final anhChuaSanSang = 'Ảnh chưa tải lên xong.';
  final tinTraLoiKhongThuoc = 'Tin bạn trả lời không thuộc channel này.';
  final channelDangBatSlowMode =
      'Channel đang bật slow mode. Chờ một chút rồi gửi tiếp.';
}

final class ViApiCollections {
  const ViApiCollections._();
  final khongTimThayChuDe = 'Không tìm thấy chủ đề.';
}

final class ViApiCommentMedia {
  const ViApiCommentMedia._();
  final khongTimThayAnhBinh = 'Không tìm thấy ảnh bình luận.';
  final baiVietKhongConKha = 'Bài không còn hiển thị.';
  final toiDa10AnhKhong = 'Tối đa 10 ảnh và không được trùng nhau.';
  final anhKhongHopLeHoac = 'Ảnh không hợp lệ hoặc chưa tải lên xong.';
  final gif = 'GIF';
  final sticker = 'Sticker';
}

final class ViApiContentVotes {
  const ViApiContentVotes._();
  final noiDungKhongConKha = 'Bài hoặc bình luận này không còn hiển thị.';
  final khongTheBinhChonNoi =
      'Bạn không thể bình chọn bài của người bạn đã chặn.';
}

final class ViApiCursor {
  const ViApiCursor._();
  final cursorKhongHopLe = 'Không tải thêm được. Tải lại trang rồi thử lại.';
}

final class ViApiDm {
  const ViApiDm._();
  final nguoiDungDaChan = 'Người bạn đã chặn';
  final messageKhongThuocConversation =
      'Tin nhắn không thuộc cuộc trò chuyện này.';
  final khongTimThayHoiThoai = 'Không tìm thấy cuộc trò chuyện.';
  final khongTheNhanTinCho = 'Bạn không thể nhắn tin cho chính mình.';
  final khongTheTaoYeuCau = 'Chưa gửi được lời mời nhắn tin. Thử lại sau.';
  final yeuCauNhanTinKhong = 'Lời mời nhắn tin này đã được xử lý.';
  final assetKhongThuocDm = 'Tệp không thuộc cuộc trò chuyện này.';
  final khongTimThayMessage = 'Không tìm thấy tin nhắn.';
}

final class ViApiDmSend {
  const ViApiDmSend._();
  final banKhongCoQuyenTruy = 'Bạn không có quyền xem cuộc trò chuyện này.';
  final khongTimThayThanhVien = 'Không tìm thấy người trong cuộc trò chuyện.';
  final attachmentChuaSanSangHoac =
      'Tệp đính kèm chưa tải lên xong hoặc không phải của bạn.';
  final clientmessageidDaDuocDungCho =
      'Tin nhắn bị trùng với một cuộc trò chuyện khác. Tải lại rồi gửi lại.';
  final conversationChuaDuocChapNhan =
      'Người nhận chưa chấp nhận lời mời nhắn tin.';
  final khongTimThayHoiThoai = 'Không tìm thấy cuộc trò chuyện.';
  final hayChoNguoiNhanPhan = 'Chờ người nhận trả lời lời mời nhắn tin đã nhé.';
  final hoiThoaiDaBiKhoa = 'Cuộc trò chuyện đã bị khóa.';
  final tinNhanCanNoiDung = 'Tin nhắn cần có chữ hoặc tệp đính kèm.';
  final messageReplyKhongThuocConversation =
      'Tin bạn trả lời không thuộc cuộc trò chuyện này.';
}

final class ViApiCaramosHelp {
  const ViApiCaramosHelp._();
  final duLieuKhongHopLe = 'Dữ liệu gửi lên không phải JSON hợp lệ.';
  final phienBanChuaHoTro = 'VNLF chưa hỗ trợ phiên bản yêu cầu này.';
  final noiDungTu10Den5000 = 'Nội dung cần từ 10 đến 5000 ký tự.';
  final lienHeToiDa200 = 'Thông tin liên hệ tối đa 200 ký tự.';
  final linkProbeKhongHopLe =
      'Link hồ sơ phần cứng phải là link https của linux-hardware.org.';
  final baoCaoKhongHopLe = 'Báo cáo Driver Check không hợp lệ hoặc quá lớn.';
  final thieuThongTinHeThong = 'Thiếu thông tin hệ thống hoặc ứng dụng gửi.';
  final loaiYeuCauKhongHopLe = 'Loại yêu cầu không hợp lệ.';
  final yeuCauQuaLon = 'Yêu cầu quá lớn, tối đa 128 KB.';
  final guiQuaNhieu = 'Bạn vừa gửi nhiều yêu cầu, thử lại sau ít phút.';
  final mayChuDangBan = 'Máy chủ VNLF đang bận, thử lại sau.';
  final khongTimThayYeuCau = 'Không tìm thấy yêu cầu hỗ trợ này.';
  final maTaiLenKhongHopLe = 'Mã tải lên (upload_id) không hợp lệ.';
  final danhSachTepKhongHopLe =
      'Danh sách ảnh và video không hợp lệ, tối đa 5 tệp.';
  final kichThuocTepKhongHopLe = 'Kích thước tệp không hợp lệ.';
  final videoToiDa60Giay = 'Video tối đa 60 giây.';
  final toiDa5Tep = 'Mỗi yêu cầu chỉ kèm tối đa 5 ảnh hoặc video.';
  final maTaiLenCuaMayKhac =
      'Mã tải lên này đang được dùng từ một địa chỉ khác.';
  final khongTimThayTep = 'Không tìm thấy tệp này.';
  final tepChuaSanSang =
      'Có ảnh hoặc video chưa tải lên xong hoặc không thuộc yêu cầu này.';
  final guiNhieuTep = 'Hôm nay bạn đã gửi nhiều ảnh và video, thử lại sau.';
  final chiaSeKhongHopLe = 'Lựa chọn chia sẻ với cộng đồng không hợp lệ.';
  final cauTraLoiKhongHopLe = 'Không tìm thấy câu trả lời này trong yêu cầu.';
}

final class ViApiPolls {
  const ViApiPolls._();
  final binhChonKhongHopLe =
      'Bình chọn cần câu hỏi và 2 đến 6 lựa chọn khác nhau.';
  final khongTimThayBinhChon = 'Không tìm thấy bình chọn này.';
  final luaChonKhongHopLe = 'Lựa chọn này không thuộc bình chọn.';
  final daDangKhongSua =
      'Bình chọn của bài đã đăng sửa ngay trên bài, khi chưa ai bình chọn.';
  final daCoNguoiBinhChon = 'Đã có người bình chọn nên không sửa được nữa.';
}

final class ViApiStickers {
  const ViApiStickers._();
  final khongTimThayBo = 'Không tìm thấy bộ sticker.';
  final tenBoKhongHopLe = 'Đặt tên cho bộ sticker nhé.';
  final quaNhieuBo = 'Mỗi người tạo tối đa 20 bộ sticker.';
  final khayDay =
      'Bạn đã thêm tối đa 100 bộ sticker. Bỏ bớt bộ cũ rồi thêm lại nhé.';
  final boDaBiAn = 'Bộ sticker này đã bị ẩn nên không thêm sticker được.';
  final dinhDangKhongDuoc =
      'Chỉ nhận ảnh PNG, JPG, WebP, GIF hoặc video WebM, MP4.';
  final tepQuaLon = 'Tệp tối đa 10MB.';
  final boDaDay = 'Mỗi bộ có tối đa 120 sticker.';
  final khongTimThaySticker = 'Không tìm thấy sticker.';
  final emojiKhongHopLe = 'Chọn một emoji cho sticker.';
  final stickerKhongConDung = 'Sticker này không còn dùng được.';
  final sticker = 'Sticker';
  final boDangBiAn = 'Bộ sticker này đang bị ẩn nên chưa gửi lên chợ được.';
  final boChuaCoSticker = 'Thêm ít nhất 1 sticker rồi gửi lên chợ nhé.';
  final trangThaiDuyetDaDoi = 'Bộ này vừa đổi trạng thái. Tải lại để xem.';
  final canGhiChu = 'Ghi lý do để người tạo biết cần sửa gì.';
  final boDangAnKhongDuyet = 'Bộ này đang bị ẩn. Bỏ ẩn trước khi duyệt.';
  final daLuuToiDa = 'Bạn đã lưu tối đa 200 sticker. Bỏ bớt rồi lưu tiếp nhé.';
}

final class ViApiProjects {
  const ViApiProjects._();
  final khongTimThay = 'Không tìm thấy dự án.';
  final linkRepoKhongHopLe =
      'Link chưa đúng. Dán link repo GitHub, ví dụ https://github.com/VN-Linux-Family/CaramOS.';
  final khongThayRepo =
      'Không thấy repo này trên GitHub. Kiểm tra lại link, hoặc repo đang để private.';
  final repoDaCo = 'Repo này đã có trên VNLF: {name}.';
  final githubBan = 'GitHub đang giới hạn số lần hỏi. Thử lại sau {wait}.';
  final githubLoi = 'Chưa lấy được thông tin từ GitHub. Thử lại sau ít phút.';
  final canTen = 'Đặt tên cho dự án nhé.';
  final canMoTaNgan = 'Viết một câu mô tả ngắn cho dự án nhé.';
  final gioiThieuNgan = 'Phần giới thiệu cần ít nhất {count} ký tự.';
  final linkKhongHopLe =
      'Link "{url}" chưa đúng. Link cần bắt đầu bằng https://.';
  final canRepoHoacLink =
      'Dự án không có repo thì cần ít nhất một link, ví dụ website hoặc trang tải về.';
  final anhKhongHopLe = 'Có ảnh chưa tải xong hoặc không còn. Tải lại ảnh nhé.';
  final daDuyetKhongDoiRepo =
      'Dự án đã duyệt thì không đổi repo được. Nhắn moderator nếu cần.';
  final dangBiAnKhongSua =
      'Dự án đang bị ẩn nên chưa sửa được. Nhắn moderator nếu cần.';
  final hetLuotGui = 'Mỗi ngày gửi được {limit} dự án. Thử lại sau {wait}.';
  final trangThaiDaDoi = 'Dự án vừa được người khác xử lý. Tải lại trang nhé.';
  final canGhiChu = 'Ghi lý do để người đăng biết cần sửa gì.';
  final khongCoThayDoi = 'Dự án không có thay đổi nào đang chờ duyệt.';
  final dangAnKhongDuyet = 'Dự án đang bị ẩn. Bỏ ẩn trước rồi mới duyệt.';
  final khongTimThayThanhVien = 'Không tìm thấy thành viên @{username}.';
  final lamMoiQuaNhanh = 'Vừa làm mới rồi. Thử lại sau {wait}.';
  final khongTuDanhGia = 'Bạn không tự đánh giá dự án của mình được.';
  final tenTrang = 'VNLF Social · Dự án';
  final baiGioiThieu = 'Giới thiệu dự án {name}: {tagline}';
}

final class ViApiCaramosSupport {
  const ViApiCaramosSupport._();
  final khongTimThay = 'Không tìm thấy yêu cầu hỗ trợ này.';
  final chiDangYeuCauCaramos = 'Chỉ đăng được yêu cầu gửi từ CaramOS.';
  final chuaChoCongKhai = 'Người gửi chưa cho phép công khai yêu cầu này.';
  final tepKhongThuocYeuCau = 'Có tệp không thuộc yêu cầu này.';
  final tieuDeNoiDungTrong =
      'Tiêu đề và nội dung công khai không được để trống.';
  final yeuCauDaDong = 'Yêu cầu đã đóng, không nhận thêm câu trả lời.';
  final traLoiCanNoiDung = 'Câu trả lời cần có nội dung.';
  final khongTimThayTraLoi = 'Không tìm thấy câu trả lời này.';
  final khongTuDanhDau =
      'Bạn không đánh dấu hữu ích được câu trả lời của chính mình.';
}

final class ViApiFeedback {
  const ViApiFeedback._();
  final chiGopYWebDeLamSau =
      'Chỉ góp ý từ VNLF Social mới để làm sau được. Yêu cầu CaramOS thì đóng hoặc đánh dấu đã xử lý.';
  final chiNhanAnhHoacVideo =
      'Chỉ nhận ảnh JPG, PNG, WebP, GIF hoặc video MP4, WebM.';
  final videoToiDa50mb = 'Video tối đa 50MB.';
  final anhToiDa10mb = 'Ảnh tối đa 10MB.';
  final gopYNayDaDuoc = 'Góp ý này đã được gửi rồi.';
  final moiGopYHoacBao = 'Mỗi góp ý hoặc báo lỗi chỉ đính kèm tối đa 5 tệp.';
  final khongTimThayTepGop = 'Không tìm thấy tệp đính kèm.';
  final tepChuaUploadHoanTat = 'Tệp chưa tải lên xong.';
  final tepUploadKhongKhopMetadata =
      'Tệp tải lên không khớp với thông tin đã khai báo. Thử tải lại.';
  final motHoacNhieuTepChua =
      'Có tệp chưa tải lên xong hoặc không thuộc góp ý này.';
  final khongTimThayGopY = 'Không tìm thấy góp ý hoặc báo lỗi.';
  final tinNhanTrong = 'Tin nhắn chưa có nội dung.';
  final khachKhongNhanDuocTin =
      'Người gửi là khách nên không nhận được tin nhắn.';
}

final class ViApiGif {
  const ViApiGif._();
  final lienKetGifKhongThuoc = 'Link GIF không đến từ nguồn GIF đã chọn.';
}

final class ViApiIdempotency {
  const ViApiIdempotency._();
  final idempotencyKeyKhongHopLe =
      'Yêu cầu không hợp lệ. Tải lại trang rồi thử lại.';
  final khongTheGiuIdempotencyKey =
      'Chưa xử lý được yêu cầu. Thử lại sau ít phút.';
  final idempotencyKeyDaDuocDung =
      'Yêu cầu bị trùng với một thao tác khác. Tải lại trang rồi thử lại.';
  final requestCungIdempotencyKeyDang =
      'Yêu cầu này đang được xử lý. Chờ một chút.';
}

final class ViApiLinkPreview {
  const ViApiLinkPreview._();
  final chiHoTroLienKet = 'Chỉ hỗ trợ link HTTP/HTTPS công khai.';
  final khongTaiDuocAnhXem = 'Không tải được ảnh xem trước.';
  final baiDangTieuDe = '{name}: {text}';
  final baiDangCua = 'Bài đăng của {name}';
}

final class ViApiDecor {
  const ViApiDecor._();
  final dinhDangAnhBiaKhongDuoc =
      'Ảnh bìa nhận JPG, PNG, WebP, GIF hoặc video MP4, MOV, WebM.';
  final dinhDangHinhNenKhongDuoc =
      'Hình nền nhận JPG, PNG, WebP, GIF hoặc video MP4, MOV, WebM.';
  final avatarDongChiNhanGif = 'Ảnh đại diện động chỉ nhận GIF.';
  final anhTinhQuaLon = 'Ảnh tối đa 10MB.';
  final gifVideoQuaLon = 'GIF hoặc video tối đa 15MB.';
  final gifAvatarQuaLon = 'GIF ảnh đại diện tối đa 8MB.';
  final vungCatKhongHopLe = 'Vùng cắt không hợp lệ. Hãy chọn lại vùng ảnh.';
  final trangTriDangBiKhoa =
      'Trang trí của bạn đang bị khóa tới {date} do vi phạm quy định.';
  final themeKhongHopLe = 'Theme không hợp lệ.';
  final monKhongHopLe = 'Món trang trí không có trong tủ đồ.';
  final linkYoutubeKhongHopLe =
      'Link YouTube không hợp lệ. Dán link video, ví dụ youtube.com/watch?v=… hoặc youtu.be/…';
  final khongTimThayVideo =
      'Không tìm thấy video này trên YouTube, hoặc video không công khai.';
  final videoKhongChoNhung =
      'Video này không cho phát ngoài YouTube. Hãy chọn video khác.';
  final khongKiemTraDuocVideo =
      'Chưa kiểm tra được video với YouTube. Thử lại sau ít phút.';
  final linkKhongHopLe =
      'Link thứ {n} chưa đúng. Dùng link http:// hoặc https:// tới một trang web, tối đa {length} ký tự.';
  final huyHieuKhongHopLe = 'Huy hiệu distro này không có trong danh sách.';
  final huyHieuChuaMo = 'Huy hiệu distro mở khi bạn đạt Level {level}.';
}

final class ViApiGuestbook {
  const ViApiGuestbook._();
  final canDangNhap = 'Đăng nhập để viết vào sổ lưu bút.';
  final soLuuButDaTat = 'Chủ trang đã tắt sổ lưu bút.';
  final khongVietVaoSoCuaMinh = 'Sổ lưu bút là để khách ghé thăm viết cho bạn.';
  final khongTheViet = 'Bạn không thể viết vào sổ lưu bút này.';
  final moiNgayMotLoi =
      'Mỗi ngày bạn chỉ viết được một lời vào sổ lưu bút của mỗi người. Hẹn bạn ngày mai.';
  final loiNhanTrong = 'Lời nhắn không được để trống.';
  final khongTimThayLoiNhan = 'Không tìm thấy lời nhắn.';
}

final class ViApiIcons {
  const ViApiIcons._();
  final tepPhaiLaPng = 'Icon phải là tệp PNG.';
  final kichThuocSai = 'Icon phải đúng 200×200 px.';
  final pngDong = 'Icon phải là ảnh tĩnh, không nhận PNG động.';
  final quaLon = 'Icon tối đa 256KB.';
  final tenTrungVaiTro =
      'Tên icon không được trùng tên vai trò như Admin, Moderator, Owner.';
  final quaNhieuIcon =
      'Mỗi người có tối đa 20 icon trong kho. Xóa bớt icon cũ rồi tải icon mới.';
  final canXacNhanQuyen = 'Hãy xác nhận bạn có quyền dùng hình này.';
  final khongTimThayIcon = 'Không tìm thấy icon.';
  final iconDaBiGo = 'Icon này đã bị gỡ khỏi kho.';
  final tenKhongHopLe = 'Tên icon không được để trống.';
}

final class ViApiMedia {
  const ViApiMedia._();
  final dinhDangAnhKhongDuoc = 'Định dạng ảnh không được hỗ trợ.';
  final khongTimThayAsset = 'Không tìm thấy tệp.';
  final fileChuaDuocUploadHoan = 'Tệp chưa tải lên xong.';
  final fileUploadKhongKhopMetadata =
      'Tệp tải lên không khớp với thông tin đã khai báo. Thử tải lại.';
  final dinhDangVideoKhongDuoc = 'Chỉ nhận video MP4, MOV hoặc WebM.';
  final videoQuaLon = 'Video phải nhỏ hơn 200MB.';
}

final class ViApiMessageAccess {
  const ViApiMessageAccess._();
  final khongCoQuyenTruyCap = 'Bạn không có quyền vào channel này.';
  final khongCoQuyenThayDoi =
      'Bạn không có quyền thay đổi cuộc trò chuyện này.';
  final hoiThoaiDaBiKhoa = 'Cuộc trò chuyện đã bị khóa.';
}

final class ViApiPush {
  const ViApiPush._();
  final thongBaoThietBiChua = 'Thông báo đẩy chưa được thiết lập.';
  final pushEndpointKhongHopLe =
      'Thiết bị này chưa đăng ký nhận thông báo được. Thử bật lại thông báo.';
  final khoaDangKyThongBao =
      'Đăng ký thông báo không hợp lệ. Thử bật lại thông báo.';
  final daDatGioiHan10 =
      'Bạn đã bật thông báo trên đủ 10 thiết bị. Tắt bớt ở thiết bị khác để thêm máy này.';
}

final class ViApiRateLimit {
  const ViApiRateLimit._();
  final banThaoTacQuaNhanh = 'Bạn thao tác hơi nhanh. Thử lại sau ít giây.';
  final dichVuTamThoiChua = 'Dịch vụ tạm thời gián đoạn. Thử lại sau ít phút.';
  final banDaDungHetDung =
      'Bạn đã dùng hết dung lượng tải lên hôm nay. Mai thử lại nhé.';
  final hetLuotTaiLen =
      'Bạn đã tải lên {limit} lần trong 24 giờ qua, mức tối đa. Thử lại sau {wait} nhé.';
  final khoangGio = 'khoảng {count} giờ';
  final khoangPhut = 'khoảng {count} phút';
  final itGiay = 'ít giây';
}

final class ViApiRealtime {
  const ViApiRealtime._();
  final banCanDangNhap = 'Bạn cần đăng nhập.';
  final khongCoQuyenTruyCap = 'Bạn không có quyền vào channel này.';
  final khongCoQuyenTruyCap2 = 'Bạn không có quyền xem cuộc trò chuyện này.';
  final messageKhongThuocConversation =
      'Tin nhắn không thuộc cuộc trò chuyện này.';
  final khongTheXuLyRealtime =
      'Chưa cập nhật trực tiếp được. Tải lại trang để thử lại.';
}

final class ViApiSearch {
  const ViApiSearch._();
  final nhapItNhat2Ky = 'Nhập ít nhất 2 ký tự để tìm kiếm.';
}

final class ViApiUsers {
  const ViApiUsers._();
  final usernameDaDuocSuDung = 'Username này đã có người dùng.';
  final matKhauHienTaiKhong = 'Mật khẩu hiện tại không đúng.';
  final emailDaDuocSuDung = 'Email này đã có người dùng.';
  final assetAvatarKhongHopLe = 'Ảnh đại diện không hợp lệ. Thử chọn ảnh khác.';
  final khongTheFollowChinhMinh = 'Bạn không thể tự theo dõi mình.';
  final khongTheFollowUserNay = 'Không theo dõi được thành viên này.';
  final khongTheBlockChinhMinh = 'Bạn không thể tự chặn mình.';
  final banCanDangNhapBang = 'Đăng nhập lại để khôi phục tài khoản.';
  final camXucNhanhKhongHopLe = 'Cảm xúc nhanh cần đúng 6 emoji khác nhau.';
}

final class ViApiVoice {
  const ViApiVoice._();
  final voiceRoomDaDong = 'Voice room đã đóng.';
  final banKhongCoQuyenVao = 'Bạn không có quyền vào voice room này.';
  final banKhongTheThamGia = 'Bạn không thể tham gia voice room này.';
  final voiceRoomDaDuNguoi = 'Voice room đã đủ người.';
  final canTracksidDeMuteServer = 'Chưa xác định được mic cần khóa. Thử lại.';
  final danhSachReorderPhaiChua =
      'Chưa sắp xếp được voice room. Tải lại trang rồi thử lại.';
}

final class ViApiVoiceChat {
  const ViApiVoiceChat._();
  final daHetThoiGianSua = 'Đã quá thời gian sửa tin nhắn.';
  final tinNhanCanCoNoi = 'Tin nhắn cần có chữ.';
  final khongTimThayAnh = 'Không tìm thấy ảnh.';
  final banKhongTheTroChuyen = 'Bạn không thể nhắn tin trong room này.';
  final idTinNhanDaDuoc =
      'Tin nhắn bị trùng với một tin khác. Tải lại rồi gửi lại.';
  final tinNhanCanNoiDung = 'Tin nhắn cần có chữ hoặc ảnh.';
  final anhChuaSanSangHoac = 'Ảnh chưa tải lên xong hoặc không thuộc room này.';
  final tinTraLoiKhongThuoc = 'Tin bạn trả lời không thuộc room này.';
}

final class ViEmail {
  const ViEmail._();
  final thuongHieu = 'VNLF Social';
  final khauHieu = 'Cộng đồng Linux Việt Nam';
  final nutKhongBamDuoc = 'Nút không bấm được? Chép link này vào trình duyệt:';
  final emailTuDong = 'Đây là email tự động, bạn không cần trả lời.';
  final datLaiMatKhau = const ViEmailDatLaiMatKhau._();
  final thietLapOwner = const ViEmailThietLapOwner._();
}

final class ViEmailDatLaiMatKhau {
  const ViEmailDatLaiMatKhau._();
  final tieuDe = 'Đặt lại mật khẩu VNLF Social';
  final xemTruoc = 'Link đặt lại mật khẩu của bạn, dùng được trong 30 phút.';
  final dauDe = 'Đặt lại mật khẩu';
  final moDau =
      'Bạn vừa yêu cầu đặt lại mật khẩu cho tài khoản VNLF Social. Bấm nút bên dưới để tạo mật khẩu mới.';
  final nut = 'Đặt lại mật khẩu';
  final hieuLuc = 'Link dùng được một lần, trong 30 phút.';
  final ghiChu =
      'Không phải bạn yêu cầu? Cứ bỏ qua email này, mật khẩu của bạn vẫn giữ nguyên.';
}

final class ViEmailThietLapOwner {
  const ViEmailThietLapOwner._();
  final tieuDe = 'Thiết lập tài khoản Owner VNLF Social';
  final xemTruoc = 'Đặt mật khẩu để bắt đầu quản trị VNLF Social.';
  final dauDe = 'Thiết lập tài khoản Owner';
  final moDau =
      'VNLF Social đã cài xong và tài khoản Owner của bạn đã sẵn sàng. Bấm nút bên dưới để đặt mật khẩu và đăng nhập lần đầu.';
  final nut = 'Đặt mật khẩu';
  final hieuLuc = 'Link dùng được một lần, trong 24 giờ.';
  final ghiChu =
      'Link hết hạn? Mở trang đăng nhập, chọn Quên mật khẩu để nhận link mới.';
}

final class ViWorker {
  const ViWorker._();
  final index = const ViWorkerIndex._();
  final push = const ViWorkerPush._();
}

final class ViWorkerIndex {
  const ViWorkerIndex._();
  final nguoiDungDaXoa = 'Người dùng đã xóa';
}

final class ViWorkerPush {
  const ViWorkerPush._();
  final coNguoiDaNhacDen = 'Có người mention bạn trong bình luận.';
  final coNguoiDaTraLoi = 'Có người trả lời bình luận của bạn.';
  final banCoTinNhanRieng = 'Bạn có tin nhắn riêng chưa đọc.';
  final banCoLoiMoiNhan = 'Bạn có lời mời nhắn tin mới.';
  final banDuocNhacDenTrong = 'Có người mention bạn trong channel.';
  final taiKhoanHoacBaoMat =
      'Tài khoản hoặc cài đặt bảo mật của bạn vừa thay đổi.';
}
// END GENERATED

/// Câu chữ của ứng dụng native chưa có khóa tương ứng trên web: thông báo hệ
/// thống, chạy nền, lưu phiên, và các màn chưa port xong theo từng phần bên
/// dưới. Đặt khóa theo cách của web. Khi một màn chuyển sang câu chữ của web
/// (`vi.<phần của web>`), xóa khóa tương ứng ở đây.
final class ViApp {
  const ViApp._();

  final tieuDeUngDung = 'Vietnam Linux Family';

  // Thông báo hệ thống.
  final tinNhanMoi = 'Tin nhắn mới';
  final banCoTinNhanMoi = 'Bạn có tin nhắn mới';
  final kenhChat = 'Kênh chat';
  final coTinNhanMoiTrongKenh = 'Có tin nhắn mới trong kênh';
  final banCoHoatDongMoi = 'Bạn có hoạt động mới trên Vietnam Linux Family.';

  // Thông báo khi chạy nền trên Android.
  final thongBaoKhiChayNen = 'Thông báo khi chạy nền';
  final giuKetNoiKhiChayNen =
      'Giữ kết nối khi ứng dụng chạy nền để báo tin nhắn và hoạt động mới. '
      'Đóng hẳn ứng dụng thì sẽ không nhận được thông báo.';
  final chuaDuocPhepGuiThongBao =
      'Ứng dụng chưa được phép gửi thông báo. Hãy cho phép trong cài đặt hệ '
      'thống rồi bật lại.';

  // Đăng nhập.
  final chuaLuuDuocPhien =
      'Máy chủ đã nhận đăng nhập nhưng thiết bị chưa lưu được phiên. Thử lại; '
      'nếu vẫn lỗi, hãy gửi góp ý cho VNLF.';

  // Câu chữ theo từng phần của ứng dụng.
  final activity = const ViAppActivity._();
  final auth = const ViAppAuth._();
  final channels = const ViAppChannels._();
  final common = const ViAppCommon._();
  final communication = const ViAppCommunication._();
  final composer = const ViAppComposer._();
  final core = const ViAppCore._();
  final designSystem = const ViAppDesignSystem._();
  final directMessages = const ViAppDirectMessages._();
  final discover = const ViAppDiscover._();
  final feed = const ViAppFeed._();
  final feedback = const ViAppFeedback._();
  final leaderboard = const ViAppLeaderboard._();
  final moderation = const ViAppModeration._();
  final notifications = const ViAppNotifications._();
  final polls = const ViAppPolls._();
  final profile = const ViAppProfile._();
  final projects = const ViAppProjects._();
  final realtime = const ViAppRealtime._();
  final search = const ViAppSearch._();
  final settings = const ViAppSettings._();
  final shared = const ViAppShared._();
  final shell = const ViAppShell._();
  final thread = const ViAppThread._();
  final updates = const ViAppUpdates._();
  final voice = const ViAppVoice._();
}

final class ViAppActivity {
  const ViAppActivity._();
  final dangNhapDeXem = 'Đăng nhập để xem hoạt động';
  final chuaDiemDanh = 'chưa điểm danh';
  final daDiemDanhNgay = 'đã điểm danh, ngày thứ {streakDay}';
  final chuaDenNgay = 'chưa đến ngày';
  final dieuChinh = 'Điều chỉnh';
  final diemNhan = 'Điểm nhận';
  final tongDiem = 'Tổng điểm';
  final diemTrongThang = 'Điểm trong tháng';
  final daDiemDanhNgayThu = 'Đã điểm danh, ngày thứ {streakDay}';
  final chuaDenNgay2 = 'Chưa đến ngày';
  final coDiem = 'Có điểm';
  final vuotNgangDeXem = 'Vuốt ngang để xem đủ 7 ngày.';
  final ngayVaChuoiDiem = 'Ngày và chuỗi điểm danh theo giờ Việt Nam (UTC+07).';
  final thangSau = 'Tháng sau';
  final thangTruoc = 'Tháng trước';
  final thang = 'Tháng {month}, {year}';
  final chuoiNgay = 'Chuỗi {streak} ngày';
  final chuoiDaiNhatNgay = 'Chuỗi dài nhất: {longest} ngày';
  final diemDanhMoiNgay = 'Điểm danh mỗi ngày';
  final chuaCoHoatDong = 'Chưa có hoạt động.';
  final khongTaiDuocHoat = 'Không tải được hoạt động trong tháng này.';
  final dangTaiHoatDong = 'Đang tải hoạt động…';
  final daXacNhanDiem = 'Đã xác nhận điểm danh.';
  final diemDanhHomNay = 'Điểm danh hôm nay';
  final dangDiemDanh = 'Đang điểm danh…';
  final lamMoiHoatDong = 'Làm mới hoạt động';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được điểm danh. Hãy làm mới hoạt động trước khi thử lại.';
  final daXacNhanDiemDanh =
      'Đã xác nhận điểm danh. Hãy làm mới hoạt động để cập nhật lịch.';
  final thuLaiLuuTru = 'Thử lại lưu trữ';
  final khongTheLuuTrang = 'Không thể lưu trạng thái điểm danh. Hãy thử lại.';
  final banDaDiemDanh = 'Bạn đã điểm danh {currentStreak} ngày liên tiếp.';
  final diemDanhHangNgay = 'Điểm danh hàng ngày';
}

final class ViAppAuth {
  const ViAppAuth._();
  final emailHoacTenNguoi = 'Email hoặc Tên người dùng';
  final congDongLinuxMa = 'Cộng đồng Linux & Mã nguồn mở Việt Nam';
  final vuiLongNhapDay =
      'Vui lòng nhập đầy đủ email/tên người dùng và mật khẩu.';
  final chaoMungTroLai = 'Chào mừng trở lại, {displayName}!';
  final vuiLongDienDay = 'Vui lòng điền đầy đủ tất cả các trường.';
  final matKhauXacNhan = 'Mật khẩu xác nhận không trùng khớp.';
  final taoTaiKhoanThanh = 'Tạo tài khoản thành công! Chào mừng {displayName}.';
}

final class ViAppChannels {
  const ViAppChannels._();
  final banChuaCoQuyen = 'Bạn chưa có quyền truy cập nội dung này.';
  final kenhHoacTinNhan = 'Kênh hoặc tin nhắn không còn tồn tại.';
  final khongDocDuocDu = 'Không đọc được dữ liệu từ máy chủ. Hãy thử làm mới.';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được thao tác. Nội dung được giữ lại; hãy làm mới trước khi gửi lại.';
  final khongTaiDuocTin =
      'Không tải được tin nhắn. Kiểm tra kết nối rồi thử lại.';
  final dangNhapDeXem = 'Đăng nhập để xem kênh cộng đồng';
  final kenhVaLichSu = 'Kênh và lịch sử trò chuyện chỉ dành cho thành viên.';
  final chonMotKenhHoac = 'Chọn một kênh hoặc cuộc trò chuyện';
  final khongMoDuocKenh = 'Không mở được kênh này';
  final danhSachTroChuyen = 'Danh sách trò chuyện';
  final chuaCoTinNhan = 'Chưa có tin nhắn';
  final kenhDaLuuTru = 'Kênh đã lưu trữ. Chỉ có thể xem tin nhắn.';
  final banChuaCoQuyenGui = 'Bạn chưa có quyền gửi tin nhắn trong kênh này.';
  final tinNhanSeBi = 'Tin nhắn sẽ bị xóa khỏi kênh.';
  final tepDangDuocXu = 'Tệp đang được xử lý';
  final khongXuLyDuoc = 'Không xử lý được tệp';
  final tinNhanCoGif = 'Tin nhắn có GIF / nhãn dán';
}

final class ViAppCommon {
  const ViAppCommon._();
  final daChon = 'Đã chọn';
  final vuiLongNhap20 = 'Vui lòng nhập 20–4000 ký tự.';
  final gopYCuaToi = 'Góp ý của tôi';
  final daGhiNhanPhan = 'Đã ghi nhận phản hồi!';
  final toi = 'Tối';
  final sang = 'Sáng';
  final hoatDong = 'Hoạt động';
  final moVnlfSocial = 'Mở VNLF Social';
  final phanDoi = 'Phản đối';
  final ungHo = 'Ủng hộ';
  final khongMoDuocLien = 'Không mở được liên kết';
  final videoDangDuocXu = 'Video đang được xử lý';
  final tatAmThanh = 'Tắt âm thanh';
  final tenNguoiDung = 'Tên người dùng';
  final quayLai = 'Quay lại';
  final phienDangNhapDa = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  final banThaoTacQua = 'Bạn thao tác quá nhanh. Vui lòng chờ rồi thử lại.';
  final mayChuDangGioi = 'Máy chủ đang giới hạn yêu cầu. Vui lòng thử lại sau.';
  final khongTaiDuocAnh = 'Không tải được ảnh. Thử lại';
  final lamMoiTinNhan = 'Làm mới tin nhắn';
  final mayChuDaXac =
      'Máy chủ đã xác nhận thao tác, nhưng chưa tải lại được lịch sử. Hãy làm mới; không cần gửi lại.';
  final taiTinNhanCu = 'Tải tin nhắn cũ hơn';
  final chinhSuaTinNhan = 'Chỉnh sửa tin nhắn';
  final thaoTacTinNhan = 'Thao tác tin nhắn';
  final chinhSua = 'Chỉnh sửa';
  final lamMoi = 'Làm mới';
  final luuBaiViet = 'Lưu bài viết';
  final chuaCoDuAn = 'Chưa có dự án';
  final chuDePhoBien = 'Chủ đề phổ biến';
  final ngay = '{inDays} ngày';
  final gio = '{inHours} giờ';
  final phut = '{inMinutes} phút';
  final vuaXong = 'Vừa xong';
  final vuiLongThuLai = 'Vui lòng thử lại.';
  final trangWeb = 'Trang web';
  final xoaAnh = 'Xóa ảnh';
  final ban = 'Bạn';
}

final class ViAppCommunication {
  const ViAppCommunication._();
  final chuaCoCuocTro = 'Chưa có cuộc trò chuyện phù hợp';
  final daXuLyYeu = 'Đã xử lý yêu cầu';
  final tuChoiYeuCau = 'Từ chối yêu cầu';
  final chapNhanYeuCau = 'Chấp nhận yêu cầu';
  final lamMoiHopThu = 'Làm mới hộp thư';
  final troChuyenMoi = 'Trò chuyện mới';
  final khongCoKenhPhu = 'Không có kênh phù hợp';
  final khongTaiDuocKenh = 'Không tải được kênh. Thử lại';
  final khongLuuDuocLua = 'Không lưu được lựa chọn hiển thị.';
  final kenhCongDong = 'Kênh cộng đồng';
  final timKenhHoacNguoi = 'Tìm kênh hoặc người';
  final dangNhapDeTro = 'Đăng nhập để trò chuyện';
}

final class ViAppComposer {
  const ViAppComposer._();
  final chuaCoBanNhap = 'Chưa có bản nháp trên máy chủ';
  final taiLaiBanNhap = 'Tải lại bản nháp';
  final banNhapChuaCo = 'Bản nháp chưa có tiêu đề';
  final toanChieuRong = 'Toàn chiều rộng';
  final binhThuong = 'Bình thường';
  final chuThich = 'Chú thích';
  final vanBanThayThe = 'Văn bản thay thế';
  final tuyChinhAnh = 'Tùy chỉnh ảnh';
  final noiDungNayDuoc = 'Nội dung này được giữ nguyên khi lưu.';
  final goLienKet = 'Gỡ liên kết';
  final nhapLienKetWeb = 'Nhập liên kết web hoặc email hợp lệ.';
  final chuaLuuDuocBan =
      'Chưa lưu được. Bản nháp vẫn được giữ; vui lòng thử lại.';
  final banNhapDaThay =
      'Bản nháp đã thay đổi trên thiết bị khác. Chọn phiên bản trước khi lưu.';
  final mayChuDangGioi =
      'Máy chủ đang giới hạn yêu cầu. Bản nháp được giữ; vui lòng thử lại sau.';
  final khongLuuDuocBan =
      'Không lưu được bản khôi phục trên thiết bị. Nội dung vẫn còn trong trình soạn thảo.';
  final vietNoiDungHoac = 'Viết nội dung hoặc thêm ảnh, video trước khi đăng.';
  final nhapCauHoiVa =
      'Nhập câu hỏi và ít nhất hai lựa chọn khác nhau trước khi đăng.';
  final khongTheThayHoac = 'Không thể thay hoặc gỡ bình chọn của bài đã đăng.';
  final binhChonChiDung = 'Bình chọn chỉ dùng trong bài đăng thường.';
  final motSoAnhCan =
      'Một số ảnh cần được tải lên trước khi đổi định dạng. Bài viết vẫn được giữ.';
  final kiemTraDoDai = 'Kiểm tra độ dài tiêu đề, mô tả và văn bản ảnh bìa.';
  final dungToiDa3 = 'Dùng tối đa 3 thẻ, mỗi thẻ không quá 40 ký tự.';
  final toiDa20Tep = 'Tối đa 20 tệp đính kèm và một video.';
  final videoChiDuocDung = 'Video chỉ được dùng trong bài đăng thường.';
  final videoKhongDuocDai = 'Video không được dài quá 30 giây.';
  final choVideoXuLy = 'Chờ video xử lý xong hoặc gỡ tệp lỗi trước khi đăng.';
  final chuyenAnhTrongBai =
      'Chuyển ảnh trong bài thành tệp đính kèm trước khi đổi sang bài thường.';
  final dungToiDa21 = 'Dùng tối đa 21 ảnh kể cả ảnh bìa.';
  final anhToiDa10 = 'Ảnh tối đa 10 MiB, video tối đa 200 MiB.';
  final chonDinhDangAnh =
      'Chọn định dạng ảnh được hỗ trợ hoặc video cho bài thường.';
  final kiemTraLanDang =
      'Kiểm tra lần đăng đang chờ xác nhận trước khi sửa tiếp.';
  final theToiDa3 = 'Thẻ (tối đa 3, cách nhau bằng dấu phẩy)';
  final moTaNgan = 'Mô tả ngắn';
  final vanBanThayTheAnh = 'Văn bản thay thế ảnh bìa';
  final goAnhBia = 'Gỡ ảnh bìa';
  final nhapCauHoiVa2 =
      'Nhập câu hỏi và 2–6 lựa chọn khác nhau. Nội dung chưa hoàn tất được giữ trên thiết bị.';
  final binhChonDaDang = 'Bình chọn đã đăng, không thể thay hoặc gỡ.';
  final boLuaChon = 'Bỏ lựa chọn';
  final binhChon = 'Bình chọn';
  final chuyen = 'Chuyển';
  final tieuDeMoTa =
      'Tiêu đề, mô tả, thẻ và ảnh bìa sẽ được gỡ. Ảnh trong nội dung chuyển thành tệp đính kèm.';
  final chuyenSangBaiThuong = 'Chuyển sang bài thường?';
  final binhChonChiDungTrong =
      'Bình chọn chỉ dùng trong bài thường. Chuyển sang Article sẽ gỡ bình chọn của bản nháp.';
  final chuyenSangArticle = 'Chuyển sang Article?';
  final goVideoTruocKhi = 'Gỡ video trước khi chuyển sang Article.';
  final khongMoDuocTep = 'Không mở được tệp đã chọn. Bản nháp vẫn được giữ.';
  final vietBaiDaiArticle = 'Viết bài dài · Article';
  final chuaLuuThayDoi = 'Chưa lưu thay đổi';
  final taiBanTrenMay = 'Tải bản trên máy chủ';
  final luuBanDangSua = 'Lưu bản đang sửa lên phiên bản mới nhất';
  final mayChuChuaXac =
      'Máy chủ chưa xác nhận lần đăng trước. Bấm kiểm tra để xác nhận cùng lần đăng đó.';
  final kiemTraLanDang2 = 'Kiểm tra lần đăng';
  final banNhap = 'Bản nháp';
  final dangNhapDeViet = 'Đăng nhập để viết bài';
  final khoiMa = 'Khối mã';
  final danhSachDanhSo = 'Danh sách đánh số';
  final maTrongDong = 'Mã trong dòng';
  final gachNgang = 'Gạch ngang';
  final kiemTraTrangThai = 'Kiểm tra trạng thái';
  final xuLyVideoThat = 'Xử lý video thất bại';
  final tieuDeArticle = 'Tiêu đề Article';
  final tuDong = 'Tự động';
  final khongMau = 'Không màu';
  final vanBanThuong = 'Văn bản thường';
  final tieuDe1 = 'Tiêu đề 1';
  final tieuDe2 = 'Tiêu đề 2';
  final tieuDe3 = 'Tiêu đề 3';
  final tieuDe4 = 'Tiêu đề 4';
  final tieuDe5 = 'Tiêu đề 5';
  final tieuDe6 = 'Tiêu đề 6';
  final danLienKet = 'Dán liên kết';
  final mo = 'Mở';
}

final class ViAppCore {
  const ViAppCore._();
  final thoat = 'Thoát';
}

final class ViAppDesignSystem {
  const ViAppDesignSystem._();
  final anhBaiViet = 'Ảnh bài viết';
  final anhSau = 'Ảnh sau';
  final tuyChon = 'Tùy chọn';
  final anhKhongConTrong = 'Ảnh không còn trong bộ';
  final khongPhatDuocVideo = 'Không phát được video. Bấm để thử lại.';
  final phatVideo = 'Phát video';
  final videoKhongKhaDung = 'Video không khả dụng';
  final thuLaiVideo = 'Thử lại video';
  final phongToVideo = 'Phóng to video';
  final batAmThanh = 'Bật âm thanh';
  final tamDung = 'Tạm dừng';
}

final class ViAppDirectMessages {
  const ViAppDirectMessages._();
  final khongMoDuocAnh = 'Không mở được ảnh đã chọn. Vui lòng thử lại.';
  final moiTinNhanCo = 'Mỗi tin nhắn có tối đa bốn ảnh.';
  final banDaChanNguoi =
      'Bạn đã chặn người dùng này. Bỏ chặn để có thể gửi lại yêu cầu trò chuyện.';
  final muonNhanTinCho =
      '{displayName} muốn nhắn tin cho bạn. Chấp nhận để bắt đầu trò chuyện hoặc từ chối yêu cầu này.';
  final chapNhan = 'Chấp nhận';
  final tuChoi = 'Từ chối';
  final cuocTroChuyenNay =
      'Cuộc trò chuyện này cần gửi lại yêu cầu nhắn tin trước khi tiếp tục.';
  final guiYeuCauNhan = 'Gửi yêu cầu nhắn tin';
  final dangChoNguoiNhan =
      'Đang chờ người nhận chấp nhận yêu cầu nhắn tin của bạn.';
  final hienKhongTheGui =
      'Hiện không thể gửi tin nhắn trong cuộc trò chuyện này.';
  final banCoTheGui =
      'Bạn có thể gửi tin nhắn mở đầu cho yêu cầu trò chuyện này.';
  final nhapTinNhan = 'Nhập tin nhắn...';
  final banKhongTheThuc =
      'Bạn không thể thực hiện thao tác này trong trạng thái cuộc trò chuyện hiện tại.';
  final khongTimThayCuoc = 'Không tìm thấy cuộc trò chuyện hoặc tin nhắn.';
  final khongDocDuocDu =
      'Không đọc được dữ liệu tin nhắn từ máy chủ. Hãy thử làm mới.';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được thao tác do lỗi mạng. Nội dung nháp được giữ lại để bạn thử lại.';
  final khongTaiDuocTin =
      'Không tải được tin nhắn trực tiếp. Kiểm tra kết nối rồi thử lại.';
  final chuaXacNhanDuocThao =
      'Chưa xác nhận được thao tác. Nội dung được giữ lại; hãy làm mới hoặc thử lại.';
  final khongTaiDuocTinNhan = 'Không tải được tin nhắn trực tiếp.';
  final banKhongTheNhan = 'Bạn không thể nhắn tin trực tiếp cho chính mình.';
  final khongTheGuiTin =
      'Không thể gửi tin nhắn vì một trong hai bên đã chặn liên lạc.';
  final canGuiYeuCau =
      'Cần gửi yêu cầu nhắn tin mới trước khi tiếp tục trò chuyện.';
  final yeuCauNhanTin = 'Yêu cầu nhắn tin này đã được xử lý trước đó.';
  final chiCoTheChinh =
      'Chỉ có thể chỉnh sửa tin nhắn trong vòng 15 phút sau khi gửi.';
  final tepDinhKemChua =
      'Tệp đính kèm chưa tải lên hoàn tất. Vui lòng thử lại.';
  final dinhDangAnhDinh = 'Định dạng ảnh đính kèm không được hỗ trợ.';
  final anhDinhKemVuot = 'Ảnh đính kèm vượt quá giới hạn 10 MB.';
  final tepAnhDinhKem = 'Tệp ảnh đính kèm không hợp lệ hoặc bị hỏng.';
  final khongTaiDuocAnh = 'Không tải được ảnh riêng tư. Thử lại';
  final diToiTinNhan = 'Đi tới tin nhắn';
  final baoCaoCuocTro = 'Báo cáo cuộc trò chuyện';
  final chiTietBoSung = 'Chi tiết bổ sung (tùy chọn)';
  final tinNhanRacSpam = 'Tin nhắn rác (Spam)';
  final quayRoiHoacXuc = 'Quấy rối hoặc xúc phạm';
  final luaDaoHoacGia = 'Lừa đảo hoặc giả mạo';
  final lyDoKhac = 'Lý do khác';
  final nhapTuKhoaToi = 'Nhập từ khóa (tối thiểu 2 ký tự)...';
  final tim = 'Tìm';
  final nhapTuKhoaDe = 'Nhập từ khóa để tìm tin nhắn trong cuộc trò chuyện.';
  final khongTimThayTin = 'Không tìm thấy tin nhắn phù hợp.';
  final anhDaChiaSe = 'Ảnh đã chia sẻ trong cuộc trò chuyện';
  final chuaCoAnhNao =
      'Chưa có ảnh nào được chia sẻ trong cuộc trò chuyện này.';
  final taiThemAnhCu = 'Tải thêm ảnh cũ hơn';
  final tinNhanChuaDoc = 'Tin nhắn chưa đọc';
  final gifNhanDan = '[GIF / Nhãn dán]';
  final anhDinhKem = '[Ảnh đính kèm]';
  final tepDinhKemDang = 'Tệp đính kèm đang được xử lý';
  final khongXuLyDuoc = 'Không xử lý được tệp đính kèm';
  final nhanDanTuBo = 'Nhãn dán từ bộ đã ngừng phát hành';
  final tinNhanCoNhan = 'Tin nhắn có nhãn dán';
  final tinNhanCoGif = 'Tin nhắn có GIF';
  final dangNhapDeXem = 'Đăng nhập để xem tin nhắn trực tiếp';
  final tinNhanRiengTu =
      'Tin nhắn riêng tư và yêu cầu kết nối chỉ dành cho thành viên đã đăng nhập.';
  final chonMotCuocTro = 'Chọn một cuộc trò chuyện';
  final danhSachCuocTro = 'Danh sách cuộc trò chuyện';
  final khongMoDuocCuoc = 'Không mở được cuộc trò chuyện';
  final dangXemNguCanh = 'Đang xem ngữ cảnh quanh tin nhắn đã chọn.';
  final veTinNhanMoi = 'Về tin nhắn mới nhất';
  final daGuiBaoCao = 'Đã gửi báo cáo cuộc trò chuyện (#{statusNotice}).';
  final chuaCoTinNhan = 'Chưa có tin nhắn trong cuộc trò chuyện này.';
  final chanNguoiDung = 'Chặn người dùng?';
  final banVaSeKhong =
      'Bạn và {displayName} sẽ không thể nhắn tin cho nhau cho tới khi bỏ chặn.';
  final xoaCuocTroChuyen = 'Xóa cuộc trò chuyện?';
  final cuocTroChuyenSe = 'Cuộc trò chuyện sẽ được ẩn khỏi hộp thư của bạn.';
  final tinNhanNaySe = 'Tin nhắn này sẽ bị xóa khỏi cuộc trò chuyện.';
  final anhDaChiaSe2 = 'Ảnh đã chia sẻ';
  final danhDauDaDoc = 'Đánh dấu đã đọc';
  final boChanNguoiDung = 'Bỏ chặn người dùng';
  final chanNguoiDung2 = 'Chặn người dùng';
  final xoaCuocTroChuyen2 = 'Xóa cuộc trò chuyện';
  final batDauCuocTro = 'Bắt đầu cuộc trò chuyện';
  final timThanhVien = 'Tìm thành viên';
  final tenHoacTenNguoi = 'Tên hoặc tên người dùng';
  final nhapItNhat2 = 'Nhập ít nhất 2 ký tự để tìm thành viên.';
  final khongTaiDuocThanh = 'Không tải được thành viên. Thử lại';
  final khongTimThayThanh = 'Không tìm thấy thành viên';
}

final class ViAppDiscover {
  const ViAppDiscover._();
  final hayThuTuKhoa = 'Hãy thử từ khóa hoặc chủ đề khác.';
  final khongCoKetQua = 'Không có kết quả';
  final chuaCoThanhVien = 'Chưa có thành viên';
  final thanhVienTichCuc = 'Thành viên tích cực';
  final duAnCongDong = 'Dự án cộng đồng';
  final baiVietNoiBat = 'Bài viết nổi bật';
  final timBaiViet = 'Tìm bài viết';
}

final class ViAppFeed {
  const ViAppFeed._();
  final dangTaiBaiViet = 'Đang tải bài viết';
}

final class ViAppFeedback {
  const ViAppFeedback._();
  final trangThaiNhan = 'Trạng thái: {label}';
  final anhVaVideo = 'Ảnh và video';
  final khongTheKhoiPhuc =
      'Không thể khôi phục bản nháp. Hãy kiểm tra tài khoản và bộ nhớ bảo mật.';
  final daGuiThanhCong =
      'Đã gửi thành công, nhưng chưa dọn được bản nháp trên thiết bị.';
  final tepKhongHopLe = 'Tệp không hợp lệ hoặc vượt quá giới hạn kích thước.';
  final mayChuTuChoi =
      'Máy chủ từ chối yêu cầu. Hãy kiểm tra nội dung và thử lại.';
  final thaoTacChuaDuoc =
      'Thao tác chưa được xác nhận. Bản nháp được giữ; kiểm tra trạng thái bên dưới.';
  final batDauBanNhap = 'Bắt đầu bản nháp mới?';
  final mayChuCoThe =
      'Máy chủ có thể đã tạo một tệp không xác định. Không thể xóa tệp đó. Nội dung sẽ được giữ và bản nháp mới dùng mã khác.';
  final batDauLai = 'Bắt đầu lại';
  final taiKhoanDaThay = 'Tài khoản đã thay đổi';
  final khongTheLuuThay =
      'Không thể lưu thay đổi của tài khoản trước vào bộ nhớ bảo mật.';
  final dongVaDangNhap = 'Đóng và đăng nhập lại để tiếp tục.';
  final thuLuuLai = 'Thử lưu lại';
  final taiKhoanDaThayDoi =
      'Tài khoản đã thay đổi. Đóng và đăng nhập lại để tiếp tục.';
  final moTa204000 = 'Mô tả (20–4000 ký tự)';
  final toiDa5Tep =
      'Tối đa 5 tệp. Ảnh tối đa 10 MiB; video MP4/WebM tối đa 50 MiB.';
  final chuaXacNhanHay = 'Chưa xác nhận; hãy xóa tệp này.';
  final xoaTep = 'Xóa tệp';
  final khongXacNhanDuoc =
      'Không xác nhận được yêu cầu tải lên. Một vị trí có thể đã được dùng; hãy xóa các tệp đã biết trước khi bắt đầu lại.';
  final batDauBanNhapMoi = 'Bắt đầu bản nháp mới';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được kết quả gửi. Chỉ có thể gửi lại nội dung không thay đổi.';
  final themTep = 'Thêm tệp';
  final khongLuuDuocBan =
      'Không lưu được bản nháp vào bộ nhớ bảo mật. Không thể tiếp tục gửi; sao chép nội dung trước khi đóng.';
  final dangNhapDeXem = 'Đăng nhập để xem lịch sử góp ý của bạn.';
  final banChuaGuiGop = 'Bạn chưa gửi góp ý nào.';
  final cuocTroChuyen = 'Cuộc trò chuyện';
  final dangNhapDeXemCuoc = 'Đăng nhập để xem cuộc trò chuyện này.';
  final chuaCoTinNhan = 'Chưa có tin nhắn. Đội VNLF sẽ trả lời tại đây.';
  final vietTinNhanCho = 'Viết tin nhắn cho Đội VNLF…';
  final guiTinNhan = 'Gửi tin nhắn';
  final dangMo = 'Đang mở';
  final dangXemXet = 'Đang xem xét';
  final daGiaiQuyet = 'Đã giải quyết';
  final daDong = 'Đã đóng';
  final deLamSau = 'Để làm sau';
  final phienDangNhapDa = 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.';
  final khongTimThayGop = 'Không tìm thấy góp ý này.';
  final phanHoiTuMay =
      'Phản hồi từ máy chủ không hợp lệ. Hãy làm mới để thử lại.';
  final chuaXacNhanDuocTin =
      'Chưa xác nhận được tin nhắn. Bản nháp được giữ lại để bạn thử lại.';
  final khongTaiDuocDu = 'Không tải được dữ liệu. Hãy thử lại sau.';
}

final class ViAppLeaderboard {
  const ViAppLeaderboard._();
  final dongGopCuaCong = 'Đóng góp của cộng đồng sẽ xuất hiện tại đây.';
  final chuaCoXepHang = 'Chưa có xếp hạng';
  final khongTaiDuocBang = 'Không tải được bảng xếp hạng';
  final hoatDongCuaToi = 'Hoạt động của tôi';
  final xepHangCongDong = 'Xếp hạng cộng đồng mẫu';
  final tuanBatDauTu = 'Tuần bắt đầu từ thứ Hai, theo giờ Việt Nam (UTC+07).';
  final bangXepHang = 'Bảng xếp hạng';
}

final class ViAppModeration {
  const ViAppModeration._();
  final hoanTat = 'Hoàn tất';
  final chiTietKhongBat = 'Chi tiết (không bắt buộc)';
  final doiNguKiemDuyet = 'Đội ngũ kiểm duyệt sẽ xem xét báo cáo của bạn.';
  final baoCaoNoiDung = 'Báo cáo nội dung';
  final daNhanBaoCao = 'Đã nhận báo cáo';
  final khongGuiDuocBao =
      'Không gửi được báo cáo. Bản nháp vẫn được giữ; vui lòng thử lại.';
  final vuiLongNhapLy = 'Vui lòng nhập lý do.';
  final taiKhoanDaThay = 'Tài khoản đã thay đổi. Hãy đóng và mở lại báo cáo.';
}

final class ViAppNotifications {
  const ViAppNotifications._();
  final khongMoDuocThong = 'Không mở được thông báo';
  final tinNhanThongBao = 'Tin nhắn & Thông báo VNLF';
  final thongBaoTinNhan =
      'Thông báo tin nhắn và hoạt động mới từ Vietnam Linux Family';
  final daThichBaiViet = 'Đã thích bài viết của bạn';
  final daThichBinhLuan = 'Đã thích bình luận của bạn';
  final daBinhLuanBai = 'Đã bình luận bài viết của bạn';
  final daTraLoiBinh = 'Đã trả lời bình luận của bạn';
  final daTheoDoiBan = 'Đã theo dõi bạn';
  final daVietVaoSo = 'Đã viết vào sổ lưu bút của bạn';
  final capNhatCongDong = 'Cập nhật cộng đồng';
  final taiThem = 'Tải thêm';
  final chuaCoThongBao = 'Chưa có thông báo';
  final khongThucHienDuoc = 'Không thực hiện được yêu cầu. Vui lòng thử lại.';
  final danhDauDaDoc = 'Đánh dấu đã đọc tất cả';
  final moiLoai = 'Mọi loại';
  final dangNhapDeXem = 'Đăng nhập để xem thông báo';
}

final class ViAppPolls {
  const ViAppPolls._();
  final bamLaiDeBo = ' · Bấm lại để bỏ';
  final luotBinhChon = 'lượt bình chọn';
  final binhChonDaCo = 'Bình chọn đã có phiếu và không thể sửa.';
  final chiSuaDuocKhi = 'Chỉ sửa được khi chưa có ai bình chọn.';
  final canCauHoiVa =
      'Cần câu hỏi và từ hai đến sáu lựa chọn khác nhau, trong giới hạn độ dài.';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được thay đổi. Lựa chọn trước được giữ lại; hãy tải lại hoặc thử lại.';
  final vuiLongChoRoi = 'Vui lòng chờ rồi thử lại.';
  final binhChonNayKhong = 'Bình chọn này không còn khả dụng.';
  final dangNhapLaiDe = 'Đăng nhập lại để lưu lựa chọn.';
}

final class ViAppProfile {
  const ViAppProfile._();
  final dangHienThi50 = 'Đang hiển thị 50 bình luận công khai đầu tiên.';
  final vi = 'vi';
  final dangHienThi50Bai = 'Đang hiển thị 50 bài viết công khai đầu tiên.';
  final chuaCoBaiViet = 'Chưa có bài viết công khai';
  final an = 'Ẩn';
  final dangAn = 'Đang ẩn';
  final chuaCoLoiNhan = 'Chưa có lời nhắn';
  final banNhapDaGiu = 'Bản nháp đã giữ';
  final hienKhongTheViet = 'Hiện không thể viết lời nhắn.';
  final dayLaSoLuu = 'Đây là sổ lưu bút của bạn.';
  final banKhongTheViet = 'Bạn không thể viết vào sổ này.';
  final banDaVietHom = 'Bạn đã viết hôm nay (giờ Việt Nam).';
  final soLuuButDa = 'Sổ lưu bút đã tắt.';
  final dangNhapDeViet = 'Đăng nhập để viết lời nhắn.';
  final guiLoiNhan = 'Gửi lời nhắn';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được thao tác. Vui lòng kiểm tra lại trước khi thử lại.';
  final daXacNhanThao =
      'Đã xác nhận thao tác, nhưng không tải lại được sổ lưu bút.';
  final xoaLoiNhan = 'Xóa lời nhắn?';
  final khongTaiDuocLoi = 'Không tải được lời nhắn tiếp theo.';
  final hoSoMau = 'Hồ sơ mẫu';
  final chuaCapNhatDuoc = 'Chưa cập nhật được theo dõi. Thử lại sau.';
  final chuaXacNhanDuocKet =
      'Chưa xác nhận được kết quả. Hãy tải lại hồ sơ để kiểm tra.';
  final thaoTacQuaNhanh = 'Thao tác quá nhanh. Thử lại sau.';
  final phienDangNhapDa = 'Phiên đăng nhập đã hết. Hãy đăng nhập lại.';
  final khongTimThayThanh = 'Không tìm thấy thành viên này.';
  final khongThucHienDuoc = 'Không thực hiện được với thành viên này.';
  final daBoTheoDoi = 'Đã bỏ theo dõi {name}';
  final dangTheoDoi = 'Đang theo dõi {name}';
  final theoDoi = 'Theo dõi {name}';
  final dangTheoDoiCham = 'Đang theo dõi {name}. Chạm để bỏ theo dõi';
  final tuyChonHoSo = 'Tùy chọn hồ sơ';
  final boChan = 'Bỏ chặn {name}';
  final dangNhapDeTheo = 'Đăng nhập để theo dõi {name}';
  final hoSoNayHien = 'Hồ sơ này hiện không có sẵn.';
  final khongTimThayHo = 'Không tìm thấy hồ sơ';
}

final class ViAppProjects {
  const ViAppProjects._();
  final soFork = 'Fork {forks}';
  final daCoTrenVnlf = 'Đã có trên VNLF: {name}';
  final lienKetKhac = 'Liên kết khác';
  final khoMaNguon = 'Kho mã nguồn';
  final troChuyen = 'Trò chuyện';
  final taiXuong = 'Tải xuống';
  final taiLieu = 'Tài liệu';
  final hocTap = 'Học tập';
  final troChoi = 'Trò chơi';
  final heThong = 'Hệ thống';
  final tiengViet = 'Tiếng Việt';
  final tienIch = 'Tiện ích';
  final tuyBien = 'Tùy biến';
  final thuVien = 'Thư viện';
  final congCu = 'Công cụ';
  final ungDung = 'Ứng dụng';
  final nguoiDongGop = 'Người đóng góp';
  final nguoiDuyTri = 'Người duy trì';
  final tacGia = 'Tác giả';
  final doiTac = 'Đối tác';
  final daBiAn = 'Đã bị ẩn';
  final daBiTuChoi = 'Đã bị từ chối';
  final dangChoDuyet = 'Đang chờ duyệt';
  final giayPhep = 'Giấy phép';
  final moBaiThaoLuan = 'Mở bài thảo luận';
  final chuaCoGioiThieu = 'Chưa có giới thiệu';
  final anhChup = 'Ảnh chụp';
  final nguoiDongGop2 = 'người đóng góp';
  final khoMaNguonKhong = 'Kho mã nguồn không còn khả dụng';
  final thayDoiDangCho = 'Thay đổi đang chờ duyệt';
  final trangThaiDuyet = 'Trạng thái duyệt';
  final khongTaiDuocDu = 'Không tải được dự án';
  final khongTimThayDu = 'Không tìm thấy dự án';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được đánh giá. Hãy làm mới trước khi thử lại.';
  final danhGia = 'đánh giá';
  final moKhoMaNguon = 'Mở kho mã nguồn (GitHub)';
  final sao = 'Sao';
  final thuBoLocKhac = 'Thử bộ lọc khác.';
  final khongCoDuAn = 'Không có dự án phù hợp';
  final tatCaNgonNgu = 'Tất cả ngôn ngữ';
  final nhapTenDuAn = 'Nhập tên dự án (tối đa 80 ký tự).';
  final nhapMoTaNgan = 'Nhập mô tả ngắn (tối đa 160 ký tự).';
  final gioiThieuCanTu = 'Giới thiệu cần từ 30 đến 10.000 ký tự.';
  final chonVaiTroCua = 'Chọn vai trò của bạn.';
  final nhapLienKetGithub =
      'Nhập liên kết GitHub hợp lệ hoặc chọn không có kho mã.';
  final kiemTraCacLien =
      'Kiểm tra các liên kết (tối đa 8 liên kết HTTP hoặc HTTPS).';
  final themItNhatMot = 'Thêm ít nhất một liên kết khi không có kho mã.';
  final toiDa200Ky = 'Tối đa 200 ký tự.';
  final logoKhongHopLe = 'Logo không hợp lệ.';
  final anhChupManHinh = 'Ảnh chụp màn hình không hợp lệ (tối đa 6 ảnh).';
  final khongTheTaiLogo = 'Không thể tải logo ({statusCode}).';
  final taiLogoKhongThanh = 'Tải logo không thành công.';
  final toiDa6Anh = 'Tối đa 6 ảnh chụp màn hình.';
  final khongTheTaiAnh = 'Không thể tải ảnh ({statusCode}).';
  final taiAnhKhongThanh = 'Tải ảnh không thành công.';
  final mayChuTuChoi =
      'Máy chủ từ chối yêu cầu ({statusCode}). Dữ liệu vẫn được giữ lại.';
  final khongTimThayKho = 'Không tìm thấy kho mã công khai này.';
  final khongTheXemKho =
      'Không thể xem kho mã lúc này. Bạn vẫn có thể gửi để máy chủ kiểm tra.';
  final khoMaNayDa = 'Kho mã này đã có trên VNLF.';
  final dangNhapDeGui = 'Đăng nhập để gửi dự án.';
  final taiKhoanDaThay =
      'Tài khoản đã thay đổi. Quay lại tài khoản ban đầu để xem bản nhập.';
  final duAnSeDuoc =
      'Dự án sẽ được kiểm duyệt trước khi hiển thị với cộng đồng.';
  final buoc3 = 'Bước {step} / 3';
  final chuaXacDinhDuoc =
      'Chưa xác định được kết quả gửi. Dữ liệu vẫn còn ở đây. Hãy kiểm tra danh sách dự án của bạn trước khi thử lại để tránh gửi trùng.';
  final daGuiDuAn = 'Đã gửi dự án và đang chờ duyệt.';
  final duAnKhongCo = 'Dự án không có kho mã công khai';
  final lienKetKhoMa = 'Liên kết kho mã GitHub';
  final dangKiemTra = 'Đang kiểm tra…';
  final xemKhoMa = 'Xem kho mã';
  final logoDuAn = 'Logo dự án';
  final dinhDangPngJpg = 'Định dạng PNG, JPG, WebP, GIF (tối đa 10 MB)';
  final logoDaTaiLen = 'Logo đã tải lên';
  final xoaLogo = 'Xóa logo';
  final taiLenLogo = 'Tải lên logo';
  final toiDa6AnhChup =
      'Tối đa 6 ảnh chụp màn hình minh họa ứng dụng (tối đa 10 MB mỗi ảnh)';
  final themAnhChupMan = 'Thêm ảnh chụp màn hình';
  final dangTaiAnhLen = 'Đang tải ảnh lên…';
  final loaiLienKet = 'Loại liên kết';
  final xoaLienKet = 'Xóa liên kết';
  final themLienKet = 'Thêm liên kết';
  final banCanGiupGi = 'Bạn cần giúp gì?';
  final xemTruoc = 'Xem trước';
  final anhChupManHinhAnh = 'Ảnh chụp màn hình: {mediaAssets} ảnh';
  final dangBaiGioiThieu = 'Đăng bài giới thiệu khi được duyệt';
  final duAnMoiSe = 'Dự án mới sẽ ở trạng thái chờ duyệt.';
}

final class ViAppRealtime {
  const ViAppRealtime._();
  final dangKetNoiDe = 'Đang kết nối để cập nhật tin nhắn.';
  final dangKetNoiLai = 'Đang kết nối lại để cập nhật tin nhắn.';
  final tinNhanMoiChua = 'Tin nhắn mới chưa thể cập nhật lúc này.';
}

final class ViAppSearch {
  const ViAppSearch._();
  final thuTuKhoaKhac = 'Thử từ khóa khác hoặc đổi phạm vi tìm kiếm.';
  final dangHienThiCac =
      'Đang hiển thị các kết quả đầu tiên. Nhập từ khóa cụ thể hơn để tìm thêm.';
  final ketQua = '{count}{capped} kết quả';
  final taiLaiChuDe = 'Tải lại chủ đề';
  final nhapItNhat2 = 'Nhập ít nhất 2 ký tự.';
  final timBaiVietDu = 'Tìm bài viết, dự án, thành viên và chủ đề.';
  final timKiemCongDong = 'Tìm kiếm cộng đồng mẫu';
  final xoaTimKiem = 'Xóa tìm kiếm';
  final timTrongCongDong = 'Tìm trong cộng đồng';
}

final class ViAppSettings {
  const ViAppSettings._();
  final chuaTaiDuocDanh = 'Chưa tải được danh sách người đã chặn.';
  final chuaTheXacNhan =
      'Chưa thể xác nhận kết quả. Hãy làm mới trước khi thử lại.';
  final daXacNhanBo = 'Đã xác nhận bỏ chặn, nhưng chưa tải lại được danh sách.';
  final daBoChan = 'Đã bỏ chặn {confirmedName}.';
  final nhungNguoiBanDa = 'Những người bạn đã chặn.';
  final nguoiDaChan = 'Người đã chặn';
  final daLuuCaiDat = 'Đã lưu cài đặt.';
  final khongTheTaiLai = 'Không thể tải lại cài đặt.';
  final taiLai = 'Tải lại';
  final chuaXacDinhDuoc =
      'Chưa xác định được cài đặt đã lưu hay chưa. Hãy tải lại để kiểm tra.';
  final amBaoTinNhan = 'Âm báo tin nhắn trên trang web';
  final binhLuanTraLoi = 'Bình luận, trả lời và tin nhắn';
  final hienThiTrangThai = 'Hiển thị trạng thái trực tuyến';
  final hienThiTrenBang = 'Hiển thị trên bảng xếp hạng';
  final moiNguoiCoThe = 'Mọi người có thể gửi tin nhắn riêng';
  final khongTheTaiCai = 'Không thể tải cài đặt.';
  final khongTheTruyCap = 'Không thể truy cập bộ nhớ.';
  final phanHoiMayChu =
      'Phản hồi máy chủ không hợp lệ. Thay đổi có thể chưa được lưu.';
  final khongKetNoiDuoc =
      'Không kết nối được máy chủ. Thay đổi có thể chưa được lưu.';
  final quaNhieuYeuCau = 'Quá nhiều yêu cầu. Vui lòng chờ một lát.';
  final yeuCauBiTu = 'Yêu cầu bị từ chối.';
  final mayChuGapSu = 'Máy chủ gặp sự cố. Thay đổi có thể chưa được lưu.';
  final mayChuKhongChap = 'Máy chủ không chấp nhận các giá trị này.';
  final khongTimThayHo = 'Không tìm thấy hồ sơ.';
  final phienDangNhapDa =
      'Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.';
  final tenNguoiDungNay =
      'Tên người dùng này đã được sử dụng hoặc đang được giữ chỗ.';
  final chiGomChuCai = 'Chỉ gồm chữ cái, chữ số, dấu chấm và gạch dưới.';
  final quaDai = 'Quá dài.';
  final toiThieu3Ky = 'Tối thiểu 3 ký tự.';
  final khongDuocDeTrong = 'Không được để trống.';
  final kiemTraDuLieu = 'Kiểm tra dữ liệu trên máy chủ';
  final daLuuHoSo = 'Đã lưu hồ sơ.';
  final tenCuDuocGiu = 'Tên cũ được giữ chỗ cho bạn trong 90 ngày.';
  final banSeCanDang =
      'Bạn sẽ cần đăng nhập lại trên các thiết bị bị ảnh hưởng.';
  final dangXuatThietBi = 'Đăng xuất thiết bị này?';
  final dangXuatCacPhien = 'Đăng xuất các phiên khác?';
  final dangXuatCacPhienKhac = 'Đăng xuất các phiên khác';
  final hienTai = 'Hiện tại';
  final khongRoLanHoat = 'Không rõ lần hoạt động cuối';
  final daXacNhanDang =
      'Đã xác nhận đăng xuất, nhưng chưa tải lại được danh sách phiên.';
  final thietBiDangDang = 'Thiết bị đang đăng nhập vào tài khoản';
  final daDangXuatTren =
      'Đã đăng xuất trên thiết bị. Không thể xác nhận đăng xuất với máy chủ.';
  final daDangXuatTai =
      'Đã đăng xuất tại đây nhưng không thể xóa phiên đã lưu. Vui lòng thử lại trước khi đóng ứng dụng.';
  final tuDongMoThu = 'Tự động mở thu nhỏ khi khởi động máy tính';
  final khoiDongCungHe = 'Khởi động cùng hệ thống';
  final tiepTucChayNgam = 'Tiếp tục chạy ngầm để nhận thông báo tức thì';
  final thuNhoVaoKhay = 'Thu nhỏ vào khay hệ thống khi đóng';
  final mayTinhKhayHe = 'Máy tính & Khay hệ thống';
  final mayChu = 'Máy chủ: {apiBaseUrlProvider}';
  final cheDoMayChu = 'Chế độ máy chủ (Thử nghiệm)';
  final khongTheLuuGiao =
      'Không thể lưu giao diện. Vui lòng chọn lại để thử lại.';
  final khongTheTruyCapBo =
      'Không thể truy cập bộ nhớ phiên đăng nhập an toàn trên thiết bị này.';
  final chuaDangNhapTai = 'Chưa đăng nhập tài khoản';
  final khach = 'Khách';
  final giaoDienDuocLuu = 'Giao diện được lưu trên thiết bị.';
  final khongTheLuuHoac = 'Không thể lưu hoặc tải cỡ chữ.';
}

final class ViAppShared {
  const ViAppShared._();
  final khongTaiDuocNoi = 'Không tải được nội dung';
  final khongLuuDuocThay = 'Không lưu được thay đổi. Vui lòng thử lại.';
  final vuiLongDangNhap = 'Vui lòng đăng nhập để lưu thay đổi.';
  final khongTheSaoChep = 'Không thể sao chép liên kết';
  final baiVietChuaCo = 'Bài viết chưa có liên kết công khai';
}

final class ViAppShell {
  const ViAppShell._();
  final khongGuiDuocGop =
      'Không gửi được góp ý. Bản nháp vẫn được giữ; vui lòng thử lại.';
  final chuaXacNhanDuoc =
      'Chưa xác nhận được kết quả. Hãy gửi lại góp ý không thay đổi để kiểm tra.';
  final emailHoacLienHe = 'Email hoặc liên hệ (không bắt buộc)';
  final cacBuocDeTai = 'Các bước để tái hiện lỗi (20–4000 ký tự)...';
  final hayChoChungMinh =
      'Hãy cho chúng mình biết điều gì cần cải thiện (20–4000 ký tự)...';
  final moTaChiTiet = 'Mô tả chi tiết lỗi gặp phải';
  final moTaYKien = 'Mô tả ý kiến hoặc đề xuất';
  final guiVoiTaiKhoan = 'Gửi với tài khoản @{username} · Nhận thưởng điểm XP';
  final baoCaoLoiSu = 'Báo cáo lỗi & sự cố';
  final dongGopYKien = 'Đóng góp ý kiến & đề xuất';
  final camOnBanDa =
      'Cảm ơn bạn đã đóng góp giúp VNLF ngày càng hoàn thiện hơn.';
  final dieuHuong = 'Điều hướng';
  final taiKhoanCaNhan = 'Tài khoản cá nhân';
}

final class ViAppThread {
  const ViAppThread._();
  final camOnBanDa = 'Cảm ơn bạn đã chia sẻ cùng cộng đồng!';
  final nhacDenThanhVien = 'Nhắc đến thành viên';
  final khongTaiDuocGoi = 'Không tải được gợi ý thành viên.';
  final suaBaiViet = 'Sửa bài viết';
  final menuBaiViet = 'Menu bài viết';
  final chuaLuuDuocThay =
      'Chưa lưu được thay đổi. Bản nháp vẫn được giữ; vui lòng thử lại.';
  final xoaBinhLuanNay = 'Xóa bình luận này? Các câu trả lời vẫn được giữ.';
  final binhLuanKhongCon =
      'Bình luận không còn nội dung hay ảnh. Xóa bình luận này?';
  final chuaLuuDuocThayDoi = 'Chưa lưu được thay đổi. Vui lòng thử lại.';
  final khongTaiDuocBinh = 'Không tải được bình luận';
  final themBinhLuan = 'Thêm bình luận';
  final khongGuiDuocBinh =
      'Không gửi được bình luận. Bản nháp vẫn được giữ; vui lòng thử lại.';
  final dangNhapLaiDe =
      'Đăng nhập lại để gửi bình luận. Bản nháp vẫn được giữ.';
  final binhLuanTruocCo =
      'Bình luận trước có thể đã được gửi. Hãy thử lại nguyên nội dung để xác nhận.';
  final thuXacNhanLai = 'Thử xác nhận lại';
  final xacNhanThatBai = 'Xác nhận thất bại.';
  final taiLenThatBai = 'Tải lên thất bại; xóa và chọn lại.';
  final sanSang = 'Sẵn sàng';
  final dangXacNhan = 'Đang xác nhận';
  final dangTaiLen = 'Đang tải lên';
  final dangChuanBi = 'Đang chuẩn bị';
  final khongMoDuocAnh = 'Không mở được ảnh đã chọn.';
  final moiBinhLuanCo = 'Mỗi bình luận có tối đa 10 ảnh.';
  final themAnh = 'Thêm ảnh';
  final anhDuocTaiLen =
      'Ảnh được tải lên và công khai ngay khi chọn, có thể giữ siêu dữ liệu và vẫn lưu trên máy chủ sau khi xóa khỏi bản nháp.';
  final vietBinhLuan = 'Viết bình luận';
  final anhDaTaiLen = '{attachmentIds} ảnh đã tải lên trước đó';
  final daHieu = 'Đã hiểu';
  final binhLuanDaDuoc = 'Bình luận đã được gửi thành công.';
  final khongKhoiPhucDuoc =
      'Không khôi phục được bình luận đang chờ. Chức năng gửi đã bị khóa.';
  final khongTimThayNoi = 'Không tìm thấy nội dung này nữa, có thể đã bị xóa.';
  final khongTimThayBai = 'Không tìm thấy bài viết';
  final xemTrangCaNhan = 'Xem trang cá nhân';
}

final class ViAppUpdates {
  const ViAppUpdates._();
  final xem = 'Xem';
  final daCoVnlfSocial = 'Đã có VNLF Social {version}.';
  final taiBanCapNhat = 'Tải bản cập nhật';
  final xemBanPhatHanh = 'Xem bản phát hành';
  final kiemTraCapNhat = 'Kiểm tra cập nhật';
  final banPhatHanhChua = 'Bản phát hành chưa có tệp cho nền tảng này.';
  final phienBanDangDung = 'Phiên bản đang dùng';
  final capNhatUngDung = 'Cập nhật ứng dụng';
  final kiemTraPhienBan = 'Kiểm tra phiên bản ổn định mới.';
  final chuaCoBanPhat = 'Chưa có bản phát hành công khai để kiểm tra.';
  final banDangDungPhien = 'Bạn đang dùng phiên bản ổn định mới nhất.';
  final daCoPhienBan = 'Đã có phiên bản {version}.';
  final khongKiemTraDuoc =
      'Không kiểm tra được bản cập nhật. Kiểm tra kết nối rồi thử lại.';
  final dangKiemTraCap = 'Đang kiểm tra cập nhật…';
  final khongMoDuocTrang = 'Không mở được trang tải bản cập nhật.';
}

final class ViAppVoice {
  const ViAppVoice._();
  final chiaSeManHinh = 'Chia sẻ màn hình';
  final dungChiaSe = 'Dừng chia sẻ';
  final dangNhapDeTham = 'Đăng nhập để tham gia';
  final thamGiaPhong = 'Tham gia phòng';
  final roiPhong = 'Rời phòng';
  final micDangBatNoi = 'Mic đang bật (nói để phát biểu)';
  final micDangTat = 'Mic đang tắt';
  final daTatAmThanh = 'Đã tắt âm thanh và mic';
  final dangChiaSeMan = 'Đang chia sẻ màn hình';
  final nguoiThamGia = '{inRoom} người tham gia';
  final dangNhapDeThamGia = 'Đăng nhập để tham gia Voice';
  final khongTheKetNoi =
      'Không thể kết nối hoặc hoàn tất rời phòng. Kiểm tra mạng rồi thử lại.';
  final phongHienKhongKha = 'Phòng hiện không khả dụng.';
  final amThanhGapLoi =
      'Âm thanh gặp lỗi. Kiểm tra thiết bị âm thanh rồi kết nối lại.';
  final phienDangNhapKhong =
      'Phiên đăng nhập không có quyền vào phòng. Hãy đăng nhập lại hoặc chọn phòng khác.';
  final chuaDuocCapQuyen =
      'Chưa được cấp quyền mic. Hãy cho phép sử dụng mic trong cài đặt hệ thống.';
  final roiPhongHienTai = 'Rời phòng hiện tại';
  final huyKetNoi = 'Hủy kết nối';
  final daKetNoiMic = 'Đã kết nối · Mic đang bật';
  final daKetNoiMicDang = 'Đã kết nối · Mic đang tắt';
  final ketNoiDeXem = 'Kết nối để xem thành viên trong phòng.';
  final chuaCoKenhThoai = 'Chưa có kênh thoại nào khả dụng.';
  final khongTaiDuocDanh = 'Không tải được danh sách kênh thoại.';
  final dangNghe = 'đang nghe';
  final daTatMic = 'đã tắt mic';
  final dangNoi = 'đang nói';
}
