# PDF Bench

Trình sửa PDF chạy hoàn toàn trong trình duyệt: sửa chữ có sẵn, thêm chữ (có tiếng Việt), che trắng,
tô sáng, vẽ, chèn ảnh, xoay/sắp xếp/xoá trang và lưu lại thành PDF. File của người dùng không rời khỏi máy họ.

## Chạy trên máy
    cd public
    python3 -m http.server 8080
Mở http://localhost:8080. Không mở trực tiếp bằng `file://` vì Web Worker của pdf.js cần chạy qua http.

## Deploy lên Cloudflare (tự động khi có code mới)
1. Cloudflare Dashboard → **Workers & Pages** → **Create** → **Import a repository** → chọn repo này.
2. Tên Worker: `pdf-bench` (phải trùng `name` trong `wrangler.jsonc`).
   Build command: để trống. Deploy command: `npx wrangler deploy` (mặc định).
3. Bật **non-production branch builds** để mỗi pull request có link xem trước.
4. **Settings → Domains & Routes → Add custom domain** để gắn tên miền riêng, ví dụ `pdf.tevo.vn`.

Từ đó: merge vào `main` = cập nhật bản chính thức; mở pull request = có link preview để duyệt.

## Cấu trúc
    public/            thư mục được deploy
      index.html       giao diện + toàn bộ logic
      js/              pdf.js, pdf-lib, fontkit, phông nhúng
      _headers         header bảo mật, CSP, cache
      licenses/        giấy phép mã nguồn mở (giữ nguyên khi phát hành)
    tools/             script dựng lại phông
    wrangler.jsonc     cấu hình Cloudflare
    CLAUDE.md          hướng dẫn cho Claude Code khi làm việc trong repo
