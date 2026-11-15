#!/bin/sh
# Check the artifact page before publishing: run its script against the catalog (needs node and lhbox, signed in).
set -e
here=$(cd "$(dirname "$0")" && pwd)
out=$(mktemp -d)/page_check.mjs
python3 - "$here/../artifact/page/index.html" "$out" <<'PY'
import sys
s = open(sys.argv[1]).read()
js = s[s.index('<script type="module">') + len('<script type="module">'):s.rindex('</script>')]
open(sys.argv[2], 'w').write(js.replace("import { lhbox } from '/_lhbox/lhbox.js';", 'const lhbox = globalThis.lhbox;'))
PY
PAGE_SCRIPT="$out" node "$here/page_harness.mjs" | tee /dev/stderr | grep -q '^FAIL' && exit 1 || exit 0
