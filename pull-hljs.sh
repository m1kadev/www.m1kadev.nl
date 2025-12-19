#!/bin/sh

cd static

rm highlight.min.js

rm rs.min.js
rm html.min.js

rm arta.min.css

wget https://raw.githubusercontent.com/highlightjs/cdn-release/refs/heads/main/build/highlight.min.js

wget https://raw.githubusercontent.com/highlightjs/cdn-release/refs/heads/main/build/languages/rust.min.js
wget https://raw.githubusercontent.com/highlightjs/cdn-release/refs/heads/main/build/languages/html.min.js

wget https://raw.githubusercontent.com/highlightjs/cdn-release/refs/heads/main/build/styles/arta.min.css

mv rust.min.js rs.min.js