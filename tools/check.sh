#!/bin/sh
# Kiểm nhanh OFFLINE cho fork TREK — lệnh `test` trong company.json (Quy chuẩn repo v1 mục 3).
# Không cần node_modules, không mạng, < 30 giây. Mã thoát 0 = qua, 1 = có lỗi, 2 = không chạy được.
#
# Kiểm: (1) cú pháp JSON của mọi *.json được git theo dõi (trừ *-lock.json và tsconfig*.json — TypeScript
# cho phép comment), (2) `node --check` mọi *.js / *.cjs / *.mjs được git theo dõi, (3) `sh -n` các *.sh.
# Bộ test đầy đủ của upstream (vitest, typecheck, eslint) cần `npm ci` và lâu hơn 2 phút: xem AGENTS.md mục Lệnh.
set -u
cd "$(dirname "$0")/.." || exit 2
command -v git >/dev/null 2>&1 || { echo "✗ không có git"; exit 2; }

fail=0
n_json=0
n_js=0
n_sh=0
t0=$(date +%s)

# Bỏ fixtures: upstream cố ý để file hỏng làm dữ liệu test (vd. shared/scripts/fixtures/baseline-broken.json)
for f in $(git ls-files '*.json' | grep -v -e '-lock\.json$' -e 'tsconfig[^/]*\.json$' -e '/fixtures/'); do
  n_json=$((n_json + 1))
  if ! python3 -I -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$f" 2>/dev/null; then
    fail=$((fail + 1)); echo "✗ JSON hỏng: $f"
  fi
done

if command -v node >/dev/null 2>&1; then
  for f in $(git ls-files '*.js' '*.cjs' '*.mjs'); do
    n_js=$((n_js + 1))
    if ! node --check "$f" 2>/dev/null; then
      fail=$((fail + 1)); echo "✗ cú pháp JS: $f"
    fi
  done
else
  fail=$((fail + 1)); echo "✗ node không có trên máy — không kiểm được cú pháp JS (TREK là repo Node)"
fi

for f in $(git ls-files '*.sh'); do
  n_sh=$((n_sh + 1))
  # Script khai #!/bin/bash thì kiểm bằng bash (cú pháp bash không phải POSIX sh)
  if head -1 "$f" | grep -q '^#!.*bash'; then shell=bash; else shell=sh; fi
  if ! "$shell" -n "$f" 2>/dev/null; then
    fail=$((fail + 1)); echo "✗ cú pháp sh: $f"
  fi
done

dt=$(( $(date +%s) - t0 ))
if [ "$fail" -eq 0 ]; then
  echo "✓ check.sh: $n_json JSON, $n_js JS, $n_sh sh hợp lệ (${dt}s). Bộ test đầy đủ: npm ci && npm test (upstream)."
  exit 0
fi
echo "✗ check.sh: $fail lỗi (${dt}s)"
exit 1
