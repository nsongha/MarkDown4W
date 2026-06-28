# Mac App Store — Checklist phát hành (MarkDown4W, miễn phí)

> Trạng thái: app đã sandbox + hardened runtime + có đủ icon. Đã cấu hình
> `DEVELOPMENT_TEAM = RCVQDZ42VU`, `LSApplicationCategoryType = Productivity`,
> version **1.0.0**. Screenshots + metadata + automation đã chuẩn bị xong.
> Còn lại chủ yếu là thủ tục trên Apple Developer Portal + App Store Connect.
>
> 👉 Muốn đi nhanh nhất: đọc [`MANUAL_STEPS.md`](MANUAL_STEPS.md). File này là
> bản tham chiếu chi tiết (gồm cả cách làm tay bằng GUI Xcode).

Ký hiệu: ✅ đã xong · ⬜ cần bạn làm · 🤖 Claude đã/có thể làm hộ

---

## 0. Yêu cầu bắt buộc
- ✅ Apple Developer Program (99 USD/năm) — bạn đã có.
- ✅ Team ID: `RCVQDZ42VU`
- ✅ Xcode 26.3, xcodegen 2.45.4 đã cài.

## 1. Định danh trên Developer Portal (developer.apple.com → Certificates, IDs & Profiles)
- ⬜ **Register App ID / Bundle ID**: `net.songha.MarkDown4W`
  - Platform: macOS · Capabilities: App Sandbox (mặc định đủ, app chỉ đọc file user chọn).
  - *Nếu dùng Automatic signing trong Xcode, bước này Xcode thường tự tạo khi Archive.*
- ⬜ Không cần tạo cert/profile thủ công nếu để **Automatic signing** (khuyến nghị).
  Xcode sẽ tự tạo "Apple Distribution" cert + "Mac App Store" provisioning profile.

## 2. Tạo app record trên App Store Connect (appstoreconnect.apple.com)
- ⬜ My Apps → **+ → New App**
  - Platform: **macOS**
  - Name: **MarkDown4W** (xem `listing.md` nếu muốn tên dễ tìm hơn)
  - Primary language: English (U.S.) — có thể thêm Tiếng Việt sau
  - Bundle ID: chọn `net.songha.MarkDown4W`
  - SKU: ví dụ `MARKDOWN4W-001` (chuỗi tự do, không hiển thị)
  - User Access: Full
- ⬜ **Pricing and Availability** → Price: **Free** · chọn quốc gia (để mặc định: tất cả)

## 3. Khai báo App Privacy (bắt buộc)
- ⬜ App Privacy → **Data Collection: No, we do not collect data**
  - App render hoàn toàn offline, không có analytics, không network với nội dung file.
- ✅ **Privacy Policy URL**: đã đăng → **https://songha.net/markdown4w/privacy**
  (chỉ cần dán URL này vào App Store Connect).

## 4. Nội dung trang App Store (lấy từ `listing.md`)
- ⬜ Subtitle (≤30 ký tự)
- ⬜ Promotional text (≤170 ký tự, sửa được bất cứ lúc nào)
- ⬜ Description (≤4000 ký tự)
- ⬜ Keywords (≤100 ký tự, phân cách bằng dấu phẩy)
- ⬜ Support URL (ví dụ trang GitHub repo hoặc songha.net)
- ⬜ Marketing URL (tùy chọn)
- ⬜ Category: Primary = **Productivity** (Secondary tùy chọn: Developer Tools)
- ⬜ **Age Rating**: trả lời bảng câu hỏi → kết quả **4+** (không có nội dung nhạy cảm)
- ⬜ Copyright: `© 2026 SongHa`

## 5. Screenshots (bắt buộc cho macOS)
- 🤖 **Đã tạo sẵn 5 ảnh 2560×1600** trong `appstore/screenshots/en-US/`
  (overview, bảng+task list, code, math/dark, mermaid/dark). Render từ chính
  bộ renderer của app nên giống hệt app thật.
- 🤖 Tạo lại bất cứ lúc nào: `node appstore/screenshots/generate.mjs`
- 🤖 `fastlane mac metadata` sẽ tự upload các ảnh này (không cần chụp tay).
- ✅ App icon 1024×1024 đã có sẵn trong asset catalog (icon_512x512@2x.png).

## 6. Build & upload
- ⬜ Trong Xcode: chọn scheme **MarkDown4W**, destination **My Mac**.
- ✅ Version đã đặt `1.0.0` trong `project.yml`. Lưu ý: mỗi lần upload lại phải
  tăng `CURRENT_PROJECT_VERSION` (build number).
- ⬜ **Product → Archive** (cần chọn cấu hình Release; Archive mặc định là Release).
- ⬜ Trong **Organizer**: chọn archive → **Distribute App → App Store Connect → Upload**.
  Để Xcode quản lý signing tự động.
- ⬜ Chờ build xử lý xong trên App Store Connect (vài phút–1 giờ).

## 7. Submit for review
- ⬜ Trong app record → chọn build vừa upload.
- ⬜ Điền "App Review Information" (tên, email, phone liên hệ; app không cần login).
- ⬜ Notes for review: ghi rõ "View-only Markdown viewer, fully offline, no account".
- ⬜ **Add for Review → Submit**.
- ⬜ Apple duyệt thường 1–3 ngày. Nếu bị từ chối, xem lý do trong Resolution Center.

## 8. Sau khi được duyệt
- ⬜ Chọn "Automatically release" hoặc "Manually release".
- ⬜ App lên store (mất thêm vài giờ để hiển thị toàn cầu).

---

## Ghi chú kỹ thuật / rủi ro có thể gặp khi review
- **WKWebView + JS bundled**: hoàn toàn hợp lệ; JS chạy offline từ bundle, không tải
  remote code → không vi phạm guideline 2.5.2.
- **Entitlements**: chỉ `app-sandbox` + `files.user-selected.read-only` → tối thiểu,
  an toàn cho review.
- **Bản quyền thư viện JS**: đã liệt kê ở `THIRD_PARTY.md` (đều là giấy phép permissive).
- **Tên app trùng**: "MarkDown4W" nên kiểm tra App Store xem có app trùng tên gây nhầm
  lẫn không (hiếm). Nếu cần, dùng tên hiển thị khác trong `listing.md`.
