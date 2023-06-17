wasm-pack build --release --target web
cp -v ./pkg/ana* ./public/
cp -v index.html wordlist.gz ./public/
wrangler pages deploy public