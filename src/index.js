const fromCommit = document.getElementById("from-commit");
const buildDate = document.getElementById("build-date");

import hljs from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/es/highlight.min.js';
import rust from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/es/languages/rust.min.js';

hljs.registerLanguage('rust', rust);
hljs.highlightAll();

fetch("/info.txt").then(async data => {
   const res = await data.text();
   let map = new Map();
   res.split("\n").map(x => x.split("=", 2)).map(([k, v]) => map[k] = v);
   fromCommit.innerHTML = map["commit"].substr(0, 8);
   buildDate.innerHTML =  map["build_time"];
});
