mkdir -p ./public/pkg
wasm-pack build --release --target web
cp -v ./pkg/ana* ./public/pkg/
cp -v index.html wordlist.gz ./public/
wrangler pages deploy public