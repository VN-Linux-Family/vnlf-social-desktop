# Kiểm toán UX/UI VNLF Flutter — 08/11/2026

Phạm vi: mã nguồn và giao diện native trong worktree
`luank3/vnlf-production-audit`, bắt đầu tại `82e3d14`. Đối chiếu với
`DESIGN_REFERENCE.md`, các ảnh website đã lưu và hợp đồng đã ghi trong
`API_NOTES.md`. Không đọc tài khoản thật, không tạo nội dung trên máy chủ,
không thêm dependency, không thay đổi endpoint.

**Kết luận:** đã phát hiện và sửa các lỗi truy cập, responsive và tương tác có
bằng chứng tái hiện. Chưa đủ cơ sở chứng nhận toàn bộ ứng dụng đạt parity website,
60/120fps hoặc sẵn sàng phát hành. Các giới hạn dưới đây là phần còn phải nghiệm
thu, không được suy diễn từ việc analyzer/test xanh.

## Phương pháp và mức bằng chứng

- Đọc design tokens, shell, các presentation và luồng trạng thái liên quan đến
  mọi nhóm tính năng trong yêu cầu; dùng suite hiện có để kiểm tra lỗi, retry,
  loading, khôi phục bản nháp và đổi tài khoản.
- Kiểm tra bổ sung trên các tuyến thực của `MainApp` ở 320, 839, 840, 900, 1180,
  1181 và 1440px, chữ 200%, font Be Vietnam Pro thật được nạp trong widget tests.
- Kiểm tra riêng bàn phím ảo: 390×700, inset dưới 300px, chữ 200%; Search,
  Channels, DirectMessages và Composer.
- Các panel phiên đăng nhập, người bị chặn, riêng tư và `LiveVoiceScreen` được
  kiểm tra riêng ở 320/900/1440px, theme tối, chữ 200%. Voice có roster giả lập
  gồm trạng thái đang nói và tắt mic; không mở kết nối LiveKit hoặc microphone.
- Capture bằng renderer của ứng dụng Linux ARM64 release trong Xvfb, dùng các
  widget route thật và dữ liệu tổng hợp. Transport nằm hoàn toàn trong bộ nhớ;
  `HttpOverrides` chặn mạng. Harness không khởi tạo tray, thông báo hay tự điểm
  danh của ứng dụng. Vì vậy ảnh không chứng minh các tích hợp nền này.
- Ảnh chỉ là viewport đầu tiên của từng màn hình. Phần dưới, dialog, editor và
  trạng thái lỗi được kiểm tra thêm bằng source/widget tests; không coi ảnh đầu
  trang là đã kiểm chứng mọi tổ hợp dữ liệu hoặc mọi nhánh tương tác.

## Ba nhóm phát hiện chính

### 1. Khả năng đọc và thao tác — đã sửa

| Chi tiết | Bằng chứng trước sửa | Sửa chữa và kiểm chứng |
| --- | --- | --- |
| Chữ trên nền accent theme tối | `onPrimary` trắng trên mint chỉ **1,86:1**; `onPrimaryContainer` chỉ **1,21:1**; Voice còn ghi đè trắng trên đỏ tối chỉ **2,43:1** | Dùng foreground tối cho primary/secondary/error; brand sáng cho primary container. Tương phản tương ứng **10,42:1 / 9,31:1 / 7,97:1 / 8,26:1**. Bỏ ghi đè trắng riêng ở auth và Voice, gồm chữ/spinner. Tests kiểm tra cả hai theme, năm cặp màu semantic và nút auth/join/leave thực ≥4,5:1. |
| Typography Material còn rơi về mặc định | Các slot `titleLarge`, `titleSmall`, `bodyLarge` chưa khai báo; AppBar/input có thể dùng cỡ 22/16px | Khai báo rõ 18/14/13px và line-height theo hệ VNLF; bổ sung headline nhỏ/label trung bình. Dùng bốn font bundled 400/500/600/700, bỏ yêu cầu weight 800 không có asset tương ứng. |
| Nút chuẩn chưa thống nhất | Filled/Outlined/TextButton dùng shape Material mặc định; input không có border theme chung | Theme chung radius 10px, min target 48px, border màu `line`. Các override theo loại nội dung vẫn được giữ. |
| Vote và hành động bài viết quá nhỏ | Vùng vote rộng khoảng 25px, capsule cao 26–30px | Target vote/comment/share/bookmark tối thiểu 48px; thêm enabled/toggled semantics, khóa bookmark khi đang chờ. Footer dùng đủ chiều rộng card trên điện thoại để bốn hành động cùng hàng ở 390px; màn hẹp/chữ lớn tiếp tục wrap. Kiểm tra cả kích thước, geometry và semantics. |
| Điều hướng và theme | Header có target 24–36px; bộ chọn theme dùng GestureDetector không nhận Tab/Enter | Header, rail profile, social links, sidebar và theme picker có target 48px; theme dùng InkWell hỗ trợ bàn phím. Test bàn phím đã tái hiện lỗi trước sửa. |
| Code block | Thanh cuộn là hình vẽ tĩnh; nút copy chồng lên dòng đầu | Scrollbar thật gắn ScrollController, thumb kéo được; copy có hàng riêng và target 48px. Test geometry không cho nút che code. |

Tương phản ở đây là các cặp màu semantic đã đo, **không phải** chứng nhận AA cho
mọi pixel, tên gradient tùy biến, badge, hình ảnh hoặc mọi trạng thái disabled.

### 2. Responsive và chữ lớn — đã sửa các lỗi tái hiện

| Chi tiết | Bằng chứng trước sửa | Kết quả |
| --- | --- | --- |
| Mốc 840px không thống nhất | Shell dùng `<=840`; Search/Profile/Settings dùng `<840` | Toàn bộ quyết định layout dùng `VnlfViewportSize.fromWidth`. Native: mobile <840, tablet [840,1181), desktop ≥1181. Có test 839,9 và 1180,9 để tránh khoảng trống khi resize phân số. |
| Sidebar desktop tràn | Tràn **137px** theo chiều dọc ở chữ 200% | Chuyển sang slivers cuộn được; utility/theme vẫn ở đáy khi đủ chỗ. Loại bỏ chevron giả có semantics nút nhưng không có hành động. |
| Form giới thiệu dự án | Hai dropdown tràn phải **25/32px** ở 320px, chữ 200% | `isExpanded`, item height tự thích nghi; giữ nội dung nhãn và validation. |
| Thanh chọn tháng | Row tràn phải **62px** ở 320px, chữ 200% | Tiêu đề và cụm điều hướng được wrap; tháng co giãn/xuống dòng được. |
| Ô ngày quá nhỏ | Ô ngày rộng **28,57px** ở 320px | Cell tối thiểu 48px, chiều cao theo text scaler; lịch cuộn ngang khi hẹp, có hướng dẫn xem đủ 7 ngày. Đây là lựa chọn giữ target đọc/chạm, không ép bảy cột nhỏ lại. |
| Search khi mở bàn phím | Tràn dưới **29px** ở 390×700 với inset 300px/chữ 200% | Filter scope cuộn ngang; bottom navigation ẩn khi bàn phím mở để nhường chỗ cho nội dung. |

Các mốc đã chạy là mẫu kiểm chứng, không phải bảo đảm toán học cho mọi kích
thước, locale, tỷ lệ chữ phi tuyến và dữ liệu dài bất kỳ. Layout desktop vẫn
giữ sidebar 252px, rail 72px và cột phụ 304px. Màu, radii 6/10/14/full và bóng đổ
theo reference; không thêm gradient, glow hay trang trí mới.

Khoảng cách footer và các cụm mới dùng 8/16px. **Chưa chứng nhận mọi spacing là
bội số 8:** reference hiện có 12px, 14px, padding header 17px và micro-spacing
2/4/6px. Giữ những giá trị có nguồn đối chiếu thay vì tự tuyên bố đã đạt một grid
8pt tuyệt đối. Muốn chuẩn hóa tuyệt đối cần quyết định cập nhật visual contract
và một lượt so sánh website riêng.

### 3. Tương tác và tính trung thực — đã sửa lỗi, còn cổng nghiệm thu

- Khám phá và danh sách bài trong Hồ sơ có vote/bookmark nhưng callback còn null.
  Đã nối vào cùng `PostInteractions` như Feed, dùng chung pending, rollback và
  lỗi xác nhận; bổ sung nhãn hành động và mở hồ sơ tác giả. Thao tác live giữ
  nguyên auth guard và chính sách không tự retry. Tests mới dùng repository giả.
- Lỗi hành động trong Feed ở locale English vẫn lấy chuỗi Việt mặc định. Đã
  truyền locale vào mapping lỗi.
- Thread desktop chỉ giữ một điều khiển quay lại theo loại bài. Chi tiết dự án
  không dựng tiêu đề “Thông tin” khi không có kho mã hoặc liên kết; dòng người
  đăng không thêm dấu phân cách khi thiếu nhãn quan hệ.
- Dialog chèn liên kết chỉ kiểm tra prefix: `http://` được chấp nhận, còn chuỗi
  khác có thể không có phản hồi. Đã có validator URL và thông báo lỗi Việt/Anh;
  dialog tự sở hữu/dispose controller sau khi đóng để tránh lỗi lifecycle.
- Không thêm podium, streak badge hoặc hiệu ứng avatar suy đoán khi visual/data
  contract chưa đủ. Những phần chưa có nằm trong ma trận bên dưới, không được
  thay bằng dữ liệu thành công giả trên production.

## Ma trận toàn bộ nhóm tính năng

| Nhóm | Đã kiểm tra / kết quả trong phạm vi hiện có | Chưa đạt hoặc chưa kiểm chứng |
| --- | --- | --- |
| Design System | Palette sáng/tối; Be Vietnam Pro và dấu `ặ ữ ờ ẫ ệ`; hierarchy 18/16/14/13/12/11; radii, shadow tokens; Material slots; target/focus/semantic của controls được sửa | Không có chứng nhận AA toàn ứng dụng; tùy biến gradient/nameplate cần kiểm tra theo từng màu. Grid 8pt tuyệt đối còn ngoại lệ reference. Native screen reader chưa nghiệm thu. |
| Feed / PostCard / Shimmer | Feed tabs, bài và tác giả, vote/downvote/bookmark, pending/rollback/lỗi, chép liên kết, skeleton loading/empty/error; reduce-motion có tests hiện hữu. Sửa target và tương tác dùng chung | Share hiện chép liên kết, chưa có native share sheet. Chưa đo fling dài, rebuild, memory với feed production nhiều media; chưa đối chiếu hoàn chỉnh spacing/grouping desktop với website hiện tại. |
| Thread / comment / Markdown | Route bài dài, reading layout, rich document, code copy/cuộn; cây root/reply, vote/edit/delete/pin, media và mention có suite hồi quy. Tests typography/margin/media hiện hữu | Native fixed comment dock, caption/quote spacing và fidelity nâng cao còn cần đối chiếu. Code block hiện là monospace, chưa có syntax highlighting theo ngôn ngữ. Contract comment chỉ cung cấp tối đa 100 dòng cũ nhất, không có cursor để app tự thêm. |
| Composer | Route thật, toolbar/undo/redo/format, rich editor, ảnh/video, preview, draft recovery, giới hạn poll và version conflict có tests. Validator link đã sửa; capture có nội dung và poll tổng hợp | Chưa nghiệm thu file picker/paste/IME/upload trên thiết bị thật; không thực hiện publish live. Ảnh render không chứng minh toàn bộ toolbar/editor shortcuts. |
| Channels / DM | Directory và list/detail responsive, bubble/author, reaction, unread, biên lai đã xem; send/edit/delete, rollback và account isolation trong suite. Ảnh chat dùng lịch sử tổng hợp | Realtime delivery chưa kiểm chứng lại; probe trước đó có HTTP 403. Emoji trên Linux host còn mất glyph. Private media và âm báo cần nghiệm thu thiết bị. |
| Voice | `LiveVoiceScreen` và tiles thật với boundary RTC giả, trạng thái speaking/muted, controls join/leave/mic/deafen; tests lifecycle và account boundary hiện hữu | Không kết nối phòng thật hoặc microphone. Không xác nhận chất lượng âm thanh, quyền mic, Bluetooth, reconnect hay speaking indicator từ LiveKit thật. Voice text chat còn thiếu theo parity audit hiện hữu. |
| Projects | List, search/sort/facets/chips, preview/detail, rating 1–5, pending/error và submission form; sửa dropdown nhỏ/chữ lớn | Chưa gửi/rate live hoặc xác nhận upload/form mọi bước trên thiết bị. Cần so sánh đầy đủ detail/submission với website. |
| Leaderboard | Top rows, archive theo tuần Việt Nam, chuyển tuần, loading/empty/error và link Activity | Hiện là ranked list; chưa có podium top 3 hoặc streak badge trong màn này. Hợp đồng tuần không cung cấp đủ dữ liệu để tự dựng streak. Tiêu chí podium/streak chưa hoàn thành. |
| Search / Discover | Debounce/stale response, scopes, tag filters, clear/empty/error; filter cuộn ngang và bàn phím; tương tác bài ở Discover đã sửa | Chưa xác nhận parity mọi scope trên website live. Discover lọc tập đã tải; không coi đây là tìm kiếm toàn bộ máy chủ. |
| Profile | Header/cover/avatar frame được hỗ trợ, distro artwork, stats null-safe, tabs posts/comments/projects/guestbook; bài có hành động dùng chung; guestbook actions/failure có tests | Full wardrobe/name effects/machine-card/music/cover và hiệu ứng frame chưa đầy đủ. Không có screenshot website đăng nhập tương ứng để chứng nhận parity. Các danh sách công khai bị giới hạn phải giữ thông báo truncation. |
| Activity | Streak, tháng/ngày theo giờ Việt Nam, calendar, legend, totals, manual/automatic check-in, uncertainty có tests; calendar nhỏ đã sửa | Heatmap hiện ở dạng lịch tháng; chưa đối chiếu đầy đủ trạng thái/mức màu với website. Automatic/live celebration và timezone/keyboard/screen reader trên thiết bị cần nghiệm thu; không thực hiện check-in thật. |
| Feedback | History/ticket thread, status/count/time, compose, disabled send, validation; attachment/recovery/uncertain outcome có suite. Ảnh dùng ticket giả | Preview ảnh đính kèm và guest attachment còn thiếu; chưa chạy upload/conversation live; hard termination trong debounce còn có giới hạn đã ghi ở API notes. |
| Settings | Theme/local font size 12–18, locale, updater, account panel; kiểm tra riêng privacy/session/blocked panels với chữ lớn và theme tối | Chưa revoke/unblock/save preferences hoặc cập nhật binary live. Text scaler là phép phối hợp với OS, chưa đối chiếu mọi mức trên Android. Keyring, autostart/tray và cập nhật thực tế không nằm trong capture harness. |

## Hiệu năng, responsive và accessibility còn phải nghiệm thu

Nợ bảo trì nguồn vẫn còn: Activity, submission, feedback và PostCard chứa các
file presentation lớn. Dialog liên kết đã được tách riêng trong lượt này;
phân rã những khối UI còn lại là hạng mục tiếp theo, không phải một tiêu chí đã
đạt chỉ vì analyzer sạch.

1. Chạy profile trên Android tầm trung: cold start <2s, frame timings khi cuộn
   feed dài, chat dài, rich editor, media và chuyển màn; kiểm tra 60/120Hz theo
   thiết bị, GPU/raster/CPU và memory bằng DevTools. Lượt này không có số đo để
   chứng nhận các ngưỡng đó.
2. Kiểm tra TalkBack/Orca thực, thứ tự focus toàn ứng dụng, hover, thông báo live
   region, text scale OS phi tuyến kết hợp cỡ chữ 18, landscape và cửa sổ thấp.
   GTK headless có cảnh báo ATK; semantics tests không thay thế screen reader.
3. Hoàn thiện các khác biệt tính năng đã nêu: podium/streak có dữ liệu xác nhận,
   syntax highlighting, wardrobe/decor,
   attachment previews và fixed comment dock. Không dựng endpoint hoặc dữ liệu
   chưa được xác nhận.
4. Bổ sung ảnh website cùng tài khoản, theme, viewport và cùng loại nội dung cho
   từng màn; rà soát pixel/spacing sau đó. Reference hiện có là ảnh lịch sử,
   không phải capture mới ngày 08/11. Be Vietnam Pro có OFL bundled; logo, social
   icons/distro artwork vẫn theo cổng kiểm tra quyền sử dụng của dự án.

## Kiểm chứng và ảnh

Kết quả cuối: dependency resolution, formatting và analyzer đều exit 0;
**toàn bộ 816 Flutter tests qua** với concurrency 1. Linux ARM64 release capture
được build/chạy thành công, **132 PNG** ở 390/900/1440×1000, sáng/tối, **0 lỗi
Flutter**, exit 0. Có 31 tests mới; test Search cũ được cập nhật thao tác cuộn
chip. Đã kiểm tra lại nút auth/Voice tối, footer điện thoại, panel tài khoản và
hai trường hợp chi tiết vừa sửa trên ảnh thật.

Kết quả lệnh cuối cùng và danh mục ảnh được ghi tại
[visual audit](visual-audit/2026-11-08/README.md). Các kiểm tra bổ sung có thể chạy
lại bằng `flutter test --concurrency=1 test/ux_audit_test.dart`.

Harness tái lập: `tool/ux_audit_capture.dart`, `tool/ux_audit_fixtures.dart`,
`tool/ux_audit_surfaces.dart`. Chúng chỉ phục vụ kiểm toán, không thay entrypoint
`lib/main.dart`, không là binary phát hành và không được dùng làm bằng chứng
thành công của server/RTC thật.

Các đường dẫn trọng tâm để review bản vá:

- [Theme](../lib/src/design_system/tokens/vnlf_theme.dart),
  [typography](../lib/src/design_system/tokens/vnlf_typography.dart),
  [breakpoints](../lib/src/design_system/tokens/vnlf_dimensions.dart).
- [PostCard](../lib/src/design_system/components/vnlf_post_card.dart),
  [vote/footer](../lib/src/design_system/components/vnlf_vote_capsule.dart),
  [code block](../lib/src/design_system/components/vnlf_code_block.dart).
- [Sidebar](../lib/src/design_system/components/shell/vnlf_sidebar.dart),
  [theme picker](../lib/src/design_system/components/shell/vnlf_theme_segment_picker.dart),
  [link dialog](../lib/src/features/composer/presentation/composer_link_dialog.dart).
- [Regression matrix](../test/ux_audit_test.dart) và
  [kiểm tra contrast nút thật](../test/ux_accent_contrast_test.dart),
  [kiểm tra nội dung chi tiết](../test/ux_detail_content_test.dart),
  [capture harness](../tool/ux_audit_capture.dart).
