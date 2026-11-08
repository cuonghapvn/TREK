# TREK (fork) — lộ trình và trạng thái

Repo này là fork của [liketrek/TREK](https://github.com/liketrek/TREK) (trước đây `mauriceboe/TREK`), chạy cho nhà dùng ở `trip.cuongn.com`. Lộ trình sản phẩm (tính năng, sửa lỗi) do upstream quyết — fork không có backlog tính năng riêng; việc của mình là giữ bản chạy, cập nhật theo upstream và giữ khả năng merge. Tóm từ `git log`, `docs/RAILWAY.md`, `CHANGELOG`/`wiki/` của upstream (không bịa thêm).

| # | Việc | Trạng thái | Ghi chú |
|---|---|---|---|
| 1 | Deploy Railway (project `trek`, service `trek-app`, volume `/app/storage`) | Xong 29/6/2026 | commit `3df0b6f0`: `railway.json`, `scripts/railway-start.sh`, `docs/RAILWAY.md`, +2 dòng `Dockerfile`, +2 dòng `.dockerignore` |
| 2 | Domain `trip.cuongn.com` + healthcheck `/api/health` | Đang chạy | kiểm 8/11/2026: `/` 200, `/api/health` `{"status":"ok"}` |
| 3 | Đồng bộ upstream (GitHub "Sync fork" → merge commit `Merge branch 'liketrek:main'`) | Định kỳ, thủ công | lần gần nhất 8/10/2026 → bản 4.3.3; chưa có lịch cố định |
| 4 | Quy chuẩn repo v1 (company.json, AGENTS.md, health/test, ROADMAP, logs/) | Đợt 5, 8/11/2026 | không sửa mã upstream; CLAUDE.md cũ chuyển nguyên văn vào AGENTS.md |
| 5 | Đổi tên repo theo quy chuẩn (`fork-trek`) | Chưa quyết | registry ghi "gợi ý đổi khi tiện"; cần anh duyệt, kéo theo đổi tên thư mục, remote, Railway |
| 6 | Tính năng riêng cho fork | Không có | giữ fork sạch để merge upstream không xung đột |

## Trạng thái hiện tại (8/11/2026)

- Bản upstream đang chạy: 4.3.3 (`package.json`). `main` của fork = `main` upstream tại thời điểm sync + 1 commit cấu hình Railway.
- Sau mỗi lần sync upstream cần push `main` → Railway build lại (push = deploy production, cần anh duyệt). Trước khi push: `sh tools/check.sh`, đọc release notes upstream (`wiki/`, GitHub Releases) xem có bước migrate/biến môi trường mới không (`docs/RAILWAY.md` liệt kê biến bắt buộc).
- Việc nên làm tiếp (đề xuất, chưa duyệt): a) thêm remote `upstream` trên máy để sync bằng CLI thay vì nút GitHub; b) đặt nhịp sync (vd. mỗi tháng) và ghi vào bảng trên.
