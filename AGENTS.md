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

## 7. Hướng dẫn kỹ thuật của upstream (bản gốc `CLAUDE.md`, giữ nguyên văn)

Nội dung dưới đây là file `CLAUDE.md` do upstream viết (tiếng Anh), chuyển sang đây nguyên văn khi `CLAUDE.md` đổi thành `@AGENTS.md` (đợt 5, 8/11/2026). Nó mô tả kiến trúc, lệnh, bất biến và cổng chất lượng của upstream; đọc khi phải hiểu hoặc sửa code upstream. Khi mục này mâu thuẫn với 5 mục chuẩn ở trên về quyền hạn/deploy của fork thì 5 mục trên thắng; về kỹ thuật thì code upstream thắng.

---

# CLAUDE.md

Guidance for Claude Code in this repository. This file holds the commands, the invariants, the gates and the philosophy. Inventories (file lists, counts, history) deliberately live in the code and its READMEs, not here — when this file disagrees with the code, the code wins; fix the doc.

## What TREK is

A self-hosted, real-time collaborative travel planner. npm-workspaces monorepo:

- **`shared/`** (`@trek/shared`) — Zod schemas, the **single source of truth** for API contracts, plus all i18n locales. Must be built before server/client typecheck or run.
- **`server/`** (`@trek/server`) — NestJS API (Express adapter), SQLite via `better-sqlite3`, WebSocket sync, built-in MCP server, sandboxed plugin runtime.
- **`client/`** (`@trek/client`) — React 19 + Vite + Zustand + Tailwind PWA, offline-first via Dexie/IndexedDB.
- **`plugin-sdk/`** (`trek-plugin-sdk`) — **not a root workspace**: own lockfile, published to npm independently, must ship standalone. Run its commands from `plugin-sdk/`.

Each package has its own `CLAUDE.md`; this file covers the monorepo picture.

## Commands

Run from the repo root unless noted. **Use `npm run ... --workspace=<pkg>`, not `npm -w <pkg>`**.

```bash
npm run dev                       # build shared, then watch shared + server + client concurrently
npm run build                     # build shared → server → client (order matters)
npm run lint                      # lint all three workspaces (server and shared run eslint --fix and rewrite files; client is check-only)
npm run format                    # prettier --write all three
```

Tests:

```bash
npm run test                                       # all workspaces
npm run test --workspace=server                    # vitest run (server); also test:unit / test:integration / test:ws
npm run test:e2e                                   # server e2e (boots Nest against a temp SQLite)
npm run test:cov                                   # coverage (lcov) for all four packages incl. plugin-sdk
cd client && npm run test                          # client vitest run
cd client && npm run e2e                           # Playwright (local only)
cd client && npm run lint:pages                    # enforce the Page pattern (CI gate)
cd client && npm run theme:lint                    # flag styling that bypasses appearance tokens (local only)
npm run typecheck --workspace=server               # tsc --noEmit (also client/shared; server also has typecheck:tests)
```

Run a single test file or test:

```bash
npx vitest run tests/unit/nest/weather.controller.test.ts   # (from server/ or client/)
npx vitest run -t "name of the test"                        # by test-name pattern
```

i18n parity (CI gate — every non-`en` locale must have the identical file set and top-level keys):

```bash
npm run i18n:parity --workspace=shared            # audit (exit 0)
npm run i18n:parity:strict --workspace=shared     # CI gate (exit 1 on drift)
```

Dev ports: the server listens on **3001**; the Vite dev server proxies the API, websocket, uploads, MCP and OAuth paths to it (see `client/vite.config.js`). There is no Node version pin — the CI workflows and the Dockerfile define what is tested. `server/.env.example` is the env-var reference.

## Server invariants

Nest owns everything: every domain is a DI module under `server/src/nest/<domain>/` (`controller` + `service` + `module`, registered in `app.module.ts`), and ESLint refuses imports of the deleted legacy `services/` layer. `server/src/nest/README.md` is the module blueprint; **`weather/` is the reference implementation** — copy its shape. The domain's Zod contract lives in `shared/src/<domain>/`.

- **`bootstrap.ts` — `buildApp()`** is the single builder for production and the test harness. **Composition order is load-bearing**: everything registered on the raw Express instance must come **before `app.init()`**, because Nest's router throws `NotFoundException` on unmatched routes and nothing registered after init is reachable. Don't add routes to that pre-init shell — it bypasses every global guard, interceptor and filter.
- **`/mcp` bodies are raw by design** — the parser wrappers exempt `/mcp` so the MCP SDK reads the untouched stream; never `@Body()` a `/mcp` route.
- **Auth is default-deny**: global guards run as `APP_GUARD`s; public routes opt out with `@Public()`, and a boot-time ratchet (`validate-route-guards.ts`) refuses any public route not on its allow-list.
- **Trip-scoped routes** verify trip access (404) and the permission (403) — `@UseGuards(JwtAuthGuard, TripAccessGuard)` + `@RequirePermission('<action>')` per handler — and forward `X-Socket-Id` to the broadcast so the originating client doesn't echo its own change. **Never gate a multipart upload with a guard** (the client sees ECONNRESET instead of 403 — check in the handler).
- **DB** (`server/src/db/`): `better-sqlite3`, WAL, FK on. Migrations are positional and append-only. `NODE_ENV=test` gives each vitest worker an isolated `:memory:` DB.
- **Realtime**: `/ws` is a Nest gateway in `server/src/nest/realtime/` — inject `RealtimeService`; `server/src/websocket.ts` is a legacy re-export stub.
- **MCP**: tools are declared in `<domain>.mcp.ts` files beside each module, on the `server/src/nest-mcp/` decorator layer. A validation or permission change on a REST route must land in the parallel MCP tool in the same change. See `MCP.md`.
- **Addons** are admin-toggleable feature modules keyed by `ADDON_IDS` in `server/src/addons.ts`.
- **Plugins** (`server/src/nest/plugins/`): one forked child process per plugin, permission-gated RPC (a handler is registered only if the plugin holds the unlocking permission), install-time manifest/signature/egress/version-range gates. The protocol tables are **generated** into `plugin-sdk/` and `shared/` by `gen:plugin-facts`; `check:plugin-facts` is the CI gate. Author tooling is `plugin-sdk/`; the `trek-plugin-dev` skill covers authoring.
- **Storage**: uploads go through the driver abstraction in `server/src/nest/storage/` (local / S3 / mirror). Never touch the filesystem or the S3 SDK from a domain service.
- **Crons** go through `server/src/nest/scheduling/` only — never a `@Cron` decorator (it bypasses the test-time gate).

## Client invariants

Offline-first, with a layered data flow. A Page never owns state directly:

- **Page pattern** (enforced by `lint:pages`, spec in `client/src/pages/PATTERN.md`): a `*Page.tsx` is a **wiring container** composing a co-located `use<Page>()` hook; it must not call React state/effect/memo hooks itself.
- **Data flow**: `store (Zustand, client/src/store/) → repo (client/src/repo/) → api (client/src/api/) | Dexie (client/src/db/offlineDb.ts)`. Writes go through `sync/mutationQueue.ts`: optimistic Dexie write, then a replay with an `X-Idempotency-Key` header on reconnect. `store/slices/remoteEventHandler.ts` applies incoming WebSocket events. Components never call the API directly.
- **Styling**: semantic Tailwind tokens (`bg-surface*`, `text-content*`, `border-edge*`, `bg-accent*`) or the underlying `var(--token)` variables — never color literals, arbitrary-value color classes or numeric inline `fontSize`, so user-chosen scheme/transparency/text-size keep working. `theme:lint` flags bypasses; suppress intentional exceptions (map/PDF/brand) with a `theme-lint-disable` line comment.
- **PWA**: `vite-plugin-pwa` + Workbox cache tiles, API and uploads; `prebuild` generates icons.

## Shared contracts & i18n

- A route is "done" only once its contract lives in `shared/` and both sides import the inferred types. Edit the Zod schema, rebuild shared, then server (validation + DTO types) and client (typed requests) pick it up.
- Locale files live in `shared/src/i18n/<locale>/`, one file per domain; `en/` is canonical. When you add or change a key, **add a real translation to every locale** — parity fails CI on missing keys, and an English placeholder is not acceptable in a non-`en` locale.

## Project direction

These principles come out of a full-repo audit and shape all new code:

- **Protect the crown jewels.** The client's offline-first data core (repos + mutation queue + Dexie), the out-of-process plugin sandbox, the Zod contract layer, and the auth primitives are production-grade. Extend them; never route around them or rewrite them in anger.
- **No "modern shell over legacy core."** The debt pattern is a modern frame delegating to the old approach underneath (on the client: feature components calling the raw API past the offline core). New code goes all-in on the target architecture; when touching a legacy seam, migrate it rather than adding another wrapper.
- **Single source of truth over manual synchronization.** Never add a hand-mirrored copy of state, schema, or contract (server↔Dexie↔Zustand, schema↔SQL, the plugin contract). Derive from one source, or guard the copy with a parity test that cannot silently skip.
- **DI over global mutable module state.** New server code injects its dependencies; new client code avoids `window`-global buses and mutable module state.
- **Use the runtime's native idioms.** Prefer React 19 features (`useOptimistic`, Actions, `use()`/Suspense) and Nest subsystems (providers, pipes, guards, `@nestjs/schedule`) over hand-rolled equivalents.
- **Fail closed, gates stay on.** Security switches default to safe; misconfiguration must refuse, not degrade. Never lower a quality gate to land a change — no new `any`, no new `eslint-disable`, no downgrading rules to `warn`, no lowered coverage thresholds.

## Conventions (from CONTRIBUTING.md)

- **Target the `dev` branch** for PRs, not `main` (exception: `wiki/`-only changes).
- **Discuss first**: outside contributions are pitched in the `#github-pr` Discord channel before any code is written.
- **PRs follow `.github/PULL_REQUEST_TEMPLATE.md`** and need a linked issue (`Closes #N`) for fixes or an approved feature discussion for features.
- **Conventional commits** (`fix(maps): ...`, `feat(budget): ...`). **No Co-Authored-By or other tool-attribution trailers.**
- One focused change per PR; no breaking changes; no unrelated reformatting. Tests ship in the same change — the project holds 80%+ coverage.
- **Parity is law** when touching a route: same URL, method, query/body, HTTP status, `Set-Cookie` and JSON body, including bespoke error strings. Nest defaults POST to 201 — add `@HttpCode(200)` where the contract returns 200. Declare static sub-routes (`/reorder`) **before** `:id` param routes.

## Quality gates in CI

`.github/workflows/test.yml` runs, per package: typecheck (server also `typecheck:tests`), `lint:check`, `lint:pages`, `check:plugin-facts`, `i18n:parity:strict`, the S3 contract suite, coverage for all four packages, then a SonarCloud scan. `lint-prettier.yml` additionally runs `lint` + `format:check` on `shared/`. `plugin-sdk` has no lint script and is outside the eslint gates. **Not in CI**: `theme:lint`, Playwright, `check:gl-split` — run them locally. There are no git hooks; nothing runs before a commit except you. Other workflows build Docker images, scan them, and publish `trek-plugin-sdk` on `plugin-sdk-v*` tags.

**SonarCloud** (project `liketrek_TREK`, the built-in Sonar way gate; the run takes 20–25 min, so get it right before pushing) measures **new code only** on a PR; any failing condition blocks it:

| Condition (new code) | Must be |
|---|---|
| Coverage | ≥ 80% |
| Duplicated lines | ≤ 3% |
| Security / reliability / maintainability rating | A |
| Security hotspots reviewed | 100% |

- **Duplication is the one that bites.** Desktop and phone shells (`client/src/components/<X>` ↔ `client/src/mobile/screens/.../M<X>`) are deliberate mirrors that are already heavily duplicated. Every line added identically to both counts against the 3% budget, so a feature touching both shells fails on its own. Put the logic in ONE hook/module (precedents: `useInstanceSettings`, `useRangeBypass` under `client/src/components/Admin/`) and leave only markup in each shell. Locale files are excluded from duplication, so i18n additions are free.
- **Coverage is per new line across all four packages.** A new file without tests drags the PR under 80%. Files in `sonar.coverage.exclusions` don't count either way.
- **Ratings are about new issues.** One new bug drops reliability; one new vulnerability drops security. Don't introduce hotspot patterns (`Math.random` in anything security-adjacent, `child_process` through PATH, backtracking regexes, secret-looking strings). Path-wide suppressions live only in `sonar-project.properties` with a written justification; one-off findings are resolved on SonarCloud, never with an inline `// NOSONAR`.
- **Check it yourself.** The `sonarqube` MCP is connected: `list_pull_requests` → `get_project_quality_gate_status` shows each condition's value; `search_duplicated_files` + `get_duplications` show what tripped duplication; `search_sonar_issues_in_projects` lists new issues. Test files are excluded from analysis — when duplication fires, the source is the problem.

## Reference docs

- `MCP.md` (MCP server, tools, scopes) · `README.md` (deployment, env vars, reverse proxy) · `server/src/nest/README.md` (module blueprint, test layout) · `server/src/app-config/README.md` (env parsing quirks) · `plugin-sdk/README.md` (plugin author guide).
- `wiki/` — end-user documentation. `Dockerfile` / `docker-compose*.yml` — the deployment path and the local S3 test stack.
