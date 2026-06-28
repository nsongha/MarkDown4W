# Những bước bạn phải tự làm (cần đăng nhập tài khoản Apple)

Tất cả phần *code hoá được* đã làm xong (xem `appstore/README.md`). Dưới đây là
những việc bắt buộc phải thao tác bằng tài khoản Apple của bạn — không thể tự
động bằng code vì cần đăng nhập/duyệt từ phía Apple.

Thứ tự khuyến nghị: **1 → 2 → 3 → 4 → 5**.

---

## 1. Privacy Policy — ✅ ĐÃ XONG
Đã đăng lên songha.net (Next.js page, merge qua PR #2):

**https://songha.net/markdown4w/privacy**

→ Dán đúng URL này vào App Store Connect ở bước 4 (mục App Privacy).
(Nguồn: `app/(frontend)/markdown4w/privacy/page.tsx` trong repo songha.net.)

## 2. Tạo App Store Connect API Key (1 lần, để tự động hoá upload)
Giúp các lệnh fastlane / script chạy không cần nhập mật khẩu + mã 2FA.

1. Vào https://appstoreconnect.apple.com → **Users and Access → Integrations →
   App Store Connect API**.
2. Bấm **+** tạo key, Access = **App Manager**. Tải file `AuthKey_XXXX.p8`.
   ⚠️ Apple chỉ cho tải **một lần** — lưu kỹ.
3. Ghi lại **Key ID** (10 ký tự) và **Issuer ID** (dạng UUID, ở đầu trang).
4. Lưu file key vào (chọn 1 trong 2, hoặc cả hai):
   - Cho fastlane: bất kỳ đâu, rồi trỏ `ASC_KEY_PATH` tới nó.
     Gợi ý: `appstore/AuthKey.p8` (đã được `.gitignore` chặn, an toàn).
   - Cho `xcrun altool` (script archive): `~/.appstoreconnect/private_keys/AuthKey_<KeyID>.p8`
5. Đặt biến môi trường (thêm vào `~/.zshrc` cho tiện):
   ```sh
   export ASC_KEY_ID="XXXXXXXXXX"
   export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   export ASC_KEY_PATH="$HOME/MkDn/appstore/AuthKey.p8"   # đường dẫn thật tới .p8
   ```

## 3. Tạo app record trên App Store Connect
**Cách A — tự động (khuyên dùng):** cài fastlane rồi chạy `produce`:
```sh
brew install fastlane          # hoặc: gem install fastlane
cd ~/MkDn                      # thư mục repo thật của bạn
fastlane produce \
  --username nguyensongha2@gmail.com \
  --app_identifier net.songha.MarkDown4W \
  --app_name "MarkDown4W" \
  --platforms macos \
  --language en-US
```
Lệnh này đăng ký Bundle ID (nếu chưa có) **và** tạo app record. Có thể hỏi
mật khẩu Apple ID + mã 2FA lần đầu.

**Cách B — thủ công:** làm theo mục 1–2 trong [`CHECKLIST.md`](CHECKLIST.md)
(Register Bundle ID + New App trên web).

## 4. Đặt giá Free + dán Privacy Policy URL
Trên App Store Connect, trong app vừa tạo:
- **Pricing and Availability** → Price = **Free**.
- **App Privacy** → "Data Collection: **No**" và dán URL ở bước 1.
- (App Information) chọn Category nếu fastlane chưa set: Productivity.

> Phần text/screenshots/category KHÔNG cần làm tay — bước 5 sẽ tự đẩy lên.

## 5. Đẩy mọi thứ lên & nộp duyệt
Sau khi bước 2–4 xong, từ thư mục repo thật:

**Đẩy thử metadata + ảnh trước (an toàn, không đụng binary):**
```sh
fastlane mac metadata
```
Kiểm tra trên App Store Connect xem mô tả + 5 ảnh đã đúng chưa.

**Build + upload + nộp duyệt (đầy đủ):**
```sh
fastlane mac release
```
Lần đầu chạy, Xcode/fastlane sẽ tự tạo **Apple Distribution certificate** +
**Mac App Store provisioning profile** (cần đăng nhập Apple trong Xcode:
*Xcode → Settings → Accounts*).

**Hoặc không dùng fastlane** — chỉ cần Xcode:
```sh
scripts/archive-appstore.sh --upload     # build + export .pkg + upload
```
rồi vào App Store Connect chọn build → **Submit for Review**.

**Hoặc hoàn toàn bằng GUI Xcode:** Product → Archive → Distribute App →
App Store Connect → Upload (xem [`CHECKLIST.md`](CHECKLIST.md) mục 6–7).

---

### Sau khi nộp
Apple duyệt ~1–3 ngày. Nếu bị từ chối, lý do nằm ở **Resolution Center** trong
App Store Connect — gửi cho mình, mình giúp xử lý.
