# TREK (fork) — hướng dẫn cho AI

Fork của **[liketrek/TREK](https://github.com/liketrek/TREK)** (trước là `mauriceboe/TREK`): app tự host lập kế hoạch chuyến đi, cộng tác thời gian thực. Bản này chạy cho nhà dùng tại `trip.cuongn.com`. **Không đổi hành vi upstream**: code trong `client/`, `server/`, `shared/`, `plugin-sdk/`, `wiki/` là của upstream; mình chỉ thêm cấu hình deploy Railway (commit `3df0b6f0`) và các file theo Quy chuẩn repo v1 của Holdings. Mọi sửa đổi khác phải giữ được khả năng merge upstream (xem mục 6).

`CLAUDE.md` giờ chỉ chứa `@AGENTS.md`. Hướng dẫn kỹ thuật gốc của upstream (bản `CLAUDE.md` cũ) được giữ **nguyên văn** ở mục 7 cuối file; các `CLAUDE.md` trong `client/`, `server/`, `shared/`, `plugin-sdk/` vẫn là của upstream, không sửa.

## Tổng quan

- Công ty: tech — Lumen Technologies (Cuong Holdings). Manifest: `company.json` (`id: trek`; GitHub của mình đặt tên `TREK`, registry gợi ý đổi `fork-trek` khi tiện — chưa quyết).
- Production: `https://trip.cuongn.com` — Railway project `trek`, service `trek-app`, build từ `Dockerfile` gốc theo `railway.json` (healthcheck `/api/health`, volume `/app/storage` → `/app/data` + `/app/uploads`, start `scripts/railway-start.sh`). Hướng dẫn: `docs/RAILWAY.md`. Giả định Railway nối GitHub và auto-deploy nhánh `main` (chưa xác nhận trong Railway) → **mọi push `main` coi là deploy production**.
- Stack (upstream): npm-workspaces monorepo — `shared/` Zod schema + i18n, `server/` NestJS + SQLite (`better-sqlite3`) + WebSocket + MCP, `client/` React 19 + Vite + Zustand + Tailwind PWA, `plugin-sdk/` publish npm riêng. Node 24 trong Dockerfile; máy này có node 20, chưa `npm ci`.
- Bản upstream đang chạy: 5.1.1 (`package.json`), gộp 9/11/2026.

## Cấu trúc

```text
client/ server/ shared/ plugin-sdk/   mã upstream — KHÔNG sửa (xem mục 7 để hiểu kiến trúc)
wiki/                       tài liệu người dùng của upstream (được copy vào image)
Dockerfile                  build production (upstream + 2 dòng của mình: copy scripts/railway-start.sh)
.dockerignore               upstream + 2 dòng của mình (cho phép scripts/railway-start.sh)
railway.json                Railway: builder DOCKERFILE, startCommand, healthcheck /api/health   (của mình)
scripts/railway-start.sh    map volume /app/storage → data/uploads rồi chạy entrypoint           (của mình)
docs/RAILWAY.md             hướng dẫn deploy Railway, biến môi trường bắt buộc                   (của mình)
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
- Sửa file của fork: `company.json`, `AGENTS.md`, `tools/`, `docs/RAILWAY.md`, `railway.json`, `scripts/railway-start.sh`.
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

## 6. Cập nhật upstream

Fork "để dùng" (`kind: fork`, REPO_STANDARD mục 14): không có lộ trình riêng (đã bỏ file ROADMAP trong `docs/`), việc của mình là giữ bản chạy và theo kịp upstream. Việc nên làm: đặt nhịp gộp (vd. mỗi tháng).

- Upstream: `https://github.com/liketrek/trek.git` (nhánh `main`; upstream nhận PR vào `dev`). Remote trên máy: chỉ `origin` = `https://github.com/cuonghapvn/trek.git`; không cần thêm remote `upstream`, dùng URL trực tiếp. Lần gộp gần nhất: v5.1.1 (9/11/2026, từ 4.3.3); trước đó nút **Sync fork** trên GitHub (2/7, 15/7, 21/7, 13/8, 8/10/2026).
- **Gộp** (cần anh duyệt vì kết thúc bằng push = deploy): `git fetch https://github.com/liketrek/trek.git main && git merge FETCH_HEAD` (merge, không rebase; không rebase/force-push `main`).
- **Trước khi gộp**: đọc release notes (GitHub Releases, `wiki/Updating`) xem có biến môi trường/migrate mới; liệt biến bắt buộc của Railway trong `docs/RAILWAY.md`. **Sao lưu** volume `/app/storage` (SQLite + uploads) trước khi deploy bản mới.
- **Migrate một chiều**: bản major (vd. v5) migrate DB khi khởi động và tạo `pre-migrate-*.db` cạnh DB; DB đã migrate không chạy lại được bản cũ. **Lùi bản** = redeploy bản cũ trên Railway kèm khôi phục từ `pre-migrate-*.db` (hoặc bản sao lưu) vào volume; cần anh duyệt.
- **Xung đột** chỉ có thể ở file mình đã đụng: `CLAUDE.md` → giữ dòng `@AGENTS.md` ở đầu rồi bản upstream nguyên văn (không chép sang AGENTS.md); `Dockerfile` (2 dòng `COPY scripts/railway-start.sh` + `chmod`), `.dockerignore` (2 dòng `!scripts/`, `!scripts/railway-start.sh`), file quy chuẩn. Giữ phần upstream, thêm lại phần của mình.
- **CI baseline**: nếu CI upstream `doc-paths` fail, thêm tay vào `scripts/ci/doc-paths-baseline.json` mục `wiki/Plugin-Development.md :: tools/list` (thư mục `tools/` của quy chuẩn làm checker coi tên method MCP là đường dẫn; `--update` chỉ rút bớt, không thêm). Chạy `sh tools/check.sh`.
- **Railway**: bật "Wait for CI" để không deploy khi CI đỏ. `railway up` (upload từ máy) dùng `.railwayignore`, phải giữ `wiki/` vì Dockerfile v5 `COPY wiki`.
- Diff của fork so với upstream = `git log --author=Cuong --no-merges` + file quanh (`company.json`, `AGENTS.md`, `tools/`, `railway.json`, `.railwayignore`, `scripts/railway-start.sh`, `docs/RAILWAY.md`). Giữ danh sách này ngắn; cải tiến riêng muốn giữ thì gửi PR lên upstream.

## 7. Hướng dẫn kỹ thuật của upstream

Nằm trong `CLAUDE.md` ngay dưới dòng `@AGENTS.md` (nguyên văn `CLAUDE.md` của liketrek, cập nhật theo mỗi lần gộp upstream; không chép vào đây để khỏi lệch). Khi gộp upstream mà `CLAUDE.md` xung đột: lấy bản upstream rồi thêm lại dòng `@AGENTS.md` đầu file.
