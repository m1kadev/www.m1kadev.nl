const fromCommit = Array.from(document.getElementsByClassName("from-commit-short"));
const buildDate = Array.from(document.getElementsByClassName("build-date"));
const htmlMinifierNext = Array.from(document.getElementsByClassName("html-minifier-next"));
const lightningcss = Array.from(document.getElementsByClassName("lightningcss"));
const uglifyjs = Array.from(document.getElementsByClassName("uglifyjs"));

fetch("/info.txt").then(async data => {
   const res = await data.text();
   let map = new Map();
   res.split("\n").map(x => x.split("=", 2)).map(([k, v]) => map[k] = v);

   fromCommit.forEach(e => e.innerHTML = map["commit"].substr(0, 8));
   buildDate.forEach(e => e.innerHTML = map["build_time"]);
   htmlMinifierNext.forEach(e => e.innerHTML = map["html_minifier_next"]);
   lightningcss.forEach(e => e.innerHTML = map["lightningcss"]);
   uglifyjs.forEach(e => e.innerHTML = map["uglifyjs"]);
});
