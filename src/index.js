const fromCommit = document.getElementById("from-commit");
const buildDate = document.getElementById("build-date");

fetch("/info.txt").then(async data => {
   const res = await data.text();
   let map = new Map();
   res.split("\n").map(x => x.split("=", 2)).map(([k, v]) => map[k] = v);
   fromCommit.innerHTML = " " + map["commit"].substr(0, 8);
   buildDate.innerHTML = " " + map["build_time"];
});
