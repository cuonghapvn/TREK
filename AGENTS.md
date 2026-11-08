# TREK (fork) — hướng dẫn cho AI

Fork của **[liketrek/TREK](https://github.com/liketrek/TREK)** (trước là `mauriceboe/TREK`): app tự host lập kế hoạch chuyến đi, cộng tác thời gian thực. Bản này chạy cho nhà dùng tại `trip.cuongn.com`. **Không đổi hành vi upstream**: code trong `client/`, `server/`, `shared/`, `plugin-sdk/`, `wiki/` là của upstream; mình chỉ thêm cấu hình deploy Railway (commit `3df0b6f0`) và các file theo Quy chuẩn repo v1 của Holdings. Mọi sửa đổi khác phải giữ được khả năng merge upstream (xem mục 6).

`CLAUDE.md` giờ chỉ chứa `@AGENTS.md`. Hướng dẫn kỹ thuật gốc của upstream (bản `CLAUDE.md` cũ) được giữ **nguyên văn** ở mục 7 cuối file; các `CLAUDE.md` trong `client/`, `server/`, `shared/`, `plugin-sdk/` vẫn là của upstream, không sửa.

## Tổng quan

- Công ty: tech — Lumen Technologies (Cuong Holdings). Manifest: `company.json` (`id: trek`; GitHub của mình đặt tên `TREK`, registry gợi ý đổi `fork-trek` khi tiện — chưa quyết).
- Production: `https://trip.cuongn.com` — Railway project `trek`, service `trek-app`, build từ `Dockerfile` gốc theo `railway.json` (healthcheck `/api/health`, volume `/app/storage` → `/app/data` + `/app/uploads`, start `scripts/railway-start.sh`). Hướng dẫn: `docs/RAILWAY.md`. Giả định Railway nối GitHub và auto-deploy nhánh `main` (chưa xác nhận trong Railway) → **mọi push `main` coi là deploy production**.
- Stack (upstream): npm-workspaces monorepo — `shared/` Zod schema + i18n, `server/` NestJS + SQLite (`better-sqlite3`) + WebSocket + MCP, `client/` React 19 + Vite + Zustand + Tailwind PWA, `plugin-sdk/` publish npm riêng. Node 24 trong Dockerfile; máy này có node 20, chưa `npm ci`.
- Bản upstream đang chạy: 4.3.3 (`package.json`), sync gần nhất 8/10/2026.

## Cấu trúc

```text
client/ server/ shared/ plugin-sdk/   mã upstream — KHÔNG sửa (xem mục 7 để hiểu kiến trúc)
wiki/                       tài liệu người dùng của upstream (được copy vào image)
Dockerfile                  build production (upstream + 2 dòng của mình: copy scripts/railway-start.sh)
.dockerignore               upstream + 2 dòng của mình (cho phép scripts/railway-start.sh)
railway.json                Railway: builder DOCKERFILE, startCommand, healthcheck /api/health   (của mình)
scripts/railway-start.sh    map volume /app/storage → data/uploads rồi chạy entrypoint           (của mình)
docs/RAILWAY.md             hướng dẫn deploy Railway, biến môi trường bắt buộc                   (của mình)
docs/ROADMAP.md             lộ trình và trạng thái fork                                          (quy chuẩn)
tools/health.py             health --json: git, production, môi trường build                     (quy chuẩn)
tools/check.sh              test offline: JSON, cú pháp JS/sh                                    (quy chuẩn)
company.json                manifest cho HQ                                                      (quy chuẩn)
logs/                       log/báo cáo của agent, không đưa vào git                             (quy chuẩn)
.github/workflows/          CI của upstream (test, docker, sonar…) — chạy trên repo upstream; ở fork chỉ tham khảo
```

Nguồn chính khi mâu thuẫn: code và README của upstream thắng tài liệu; `company.json` thắng mọi mô tả về lệnh/deploy của fork.

## Lệnh

Chạy từ gốc repo. Khớp `commands` trong `company.json`.

- `sh tools/check.sh` — **test** (offline, ~3 giây, không cần `npm ci`): cú pháp JSON của mọi `*.json` git theo dõi (trừ `*-lock.json`, `tsconfig*.json`), `node --check` mọi `*.js/*.cjs/*.mjs`, `sh -n` các `*.sh`. Mã thoát 0 = qua. Không chạy vitest/typecheck.
- `python3 tools/health.py --json` — **health**: git (nhánh, chưa push/pull, file chưa commit, phiên bản), production `trip.cuongn.com` (`/` HEAD, `/api/health` GET mong `{"status":"ok"}`, timeout 5 giây), môi trường build (node, `node_modules`, Dockerfile/railway.json). Có `bad` → mã thoát 1. Không `--json` → bảng. `HQ_SITE` đổi URL khi thử.
- `python3 tools/health.py --only git` — **status**: phần git, không cần mạng.
- Bộ test đầy đủ của upstream (cần `npm ci`, > 2 phút, không phải lệnh `test` của HQ): `npm test`, `npm run lint`, `npm run typecheck --workspace=server|client|shared`, `npm run build` — chi tiết mục 7 "Commands".
- Cập nhật upstream: mục 6. Deploy: push `main` (cần anh duyệt) → Railway build.

## An toàn

**Được tự làm**
- Sửa file của fork: `company.json`, `AGENTS.md`, `docs/ROADMAP.md`, `tools/`, `docs/RAILWAY.md`, `railway.json`, `scripts/railway-start.sh`.
- Chạy lệnh đọc: `sh tools/check.sh`, `python3 tools/health.py`, `git log/status/diff/fetch`.
- Đọc code upstream để trả lời câu hỏi, khoanh vùng lỗi.

**Không được làm**
- Không commit, không push (phiên điều hành commit; push `main` = deploy, cần anh duyệt).
- **Không sửa mã upstream** (`client/`, `server/`, `shared/`, `plugin-sdk/`, `wiki/`, `Dockerfile` ngoài 2 dòng Railway) trừ khi anh giao rõ; sửa thì giữ diff tối thiểu để merge upstream không xung đột. Lỗi của upstream → mở issue/PR ở upstream (quy ước PR của họ: mục 7 "Conventions"), không vá riêng trong fork.
- Không rebase/force-push `main`: lịch sử sync bằng merge commit (`Merge branch 'liketrek:main'`), rebase làm mất khả năng "Sync fork".
- Không đọc/in bí mật: `~/.config/trek/`, `.env*`, `ENCRYPTION_KEY`, biến Railway, DB SQLite/uploads production.
- Không `npm install` thêm dependency, không đổi `package-lock.json`, không chạy `docker build`/`docker compose` trừ khi được giao.
- Không vượt CAPTCHA/đăng nhập/chặn truy cập khi kiểm production; chỉ HEAD/GET `/` và `/api/health`.

**Cần anh duyệt**
- Push `main` (deploy production), kể cả sau khi sync upstream.
- Đổi biến môi trường / volume / domain trên Railway, redeploy, rollback.
- Sync upstream có xung đột trong `Dockerfile`/`.dockerignore`/`scripts/railway-start.sh`; nâng phiên bản lớn (major) của upstream có bước migrate.
- Đổi tên repo (`fork-trek`), đổi remote, xoá dữ liệu production.

## Phòng ban

Agent dùng chung của Holdings (cài qua `holdings ./hq install`); repo này không có agent riêng (`.claude/` bị gitignore của upstream). Agent không gọi được agent khác; việc nhiều phòng do phiên điều hành gọi lần lượt.

| Việc | Giao cho | Ghi chú |
|---|---|---|
| Sync upstream, kiểm diff, cấu hình Railway (đề xuất) | `devops` | chỉ đọc; đề xuất lệnh chính xác, anh duyệt rồi phiên điều hành chạy |
| Hiểu/khoanh vùng lỗi trong code upstream, vá được giao rõ | `web-dev` | giữ diff tối thiểu, theo quy ước mục 7 |
| `tools/health.py`, `tools/check.sh` | `tools-dev` | Python 3.9 stdlib, POSIX sh |
| Chạy test/health, kiểm production | `qa-tester` | `sh tools/check.sh`, `python3 tools/health.py` |
| Thẩm định diff trước khi commit | `reviewer` | trả lời thêm: diff có đụng mã upstream không |
| Chi phí token | `tai-chinh` | `hq cost --by repo` (dòng trek) |

## 6. Fork và cập nhật upstream

- Upstream: `https://github.com/liketrek/TREK` (nhánh `main`; upstream nhận PR vào `dev`). Remote hiện có trên máy: chỉ `origin` = `https://github.com/cuonghapvn/trek.git` (GitHub hiển thị `TREK`), chưa có remote `upstream` (`git remote -v`).
- Cách đã dùng tới nay: nút **Sync fork** trên GitHub → tạo merge commit `Merge branch 'liketrek:main' into main` → `git pull` về máy. Lịch sử: 2/7, 15/7 (còn `mauriceboe`), 21/7, 13/8, 8/10/2026.
- Cách bằng CLI (cùng kết quả, cần anh duyệt vì kết thúc bằng push = deploy):
  1. `git remote add upstream https://github.com/liketrek/TREK.git` (một lần).
  2. `git fetch upstream && git merge upstream/main` (merge, không rebase).
  3. Xung đột chỉ có thể ở file mình đã đụng: `Dockerfile` (2 dòng `COPY scripts/railway-start.sh` + `chmod`), `.dockerignore` (2 dòng `!scripts/`, `!scripts/railway-start.sh`), và file quy chuẩn. Giữ phần upstream, thêm lại phần của mình.
  4. Đọc release notes upstream (GitHub Releases, `wiki/Updating`) xem có biến môi trường/migrate mới; `sh tools/check.sh`; rồi xin duyệt push `main`.
- Diff của fork so với upstream = `git log --author=Cuong --no-merges` (hiện chỉ `3df0b6f0`) + file quy chuẩn đợt 5. Giữ danh sách này ngắn.

## 7. Hướng dẫn kỹ thuật của upstream

Nằm trong `CLAUDE.md` ngay dưới dòng `@AGENTS.md` (nguyên văn `CLAUDE.md` của liketrek, cập nhật theo mỗi lần gộp upstream; không chép vào đây để khỏi lệch). Khi gộp upstream mà `CLAUDE.md` xung đột: lấy bản upstream rồi thêm lại dòng `@AGENTS.md` đầu file.
