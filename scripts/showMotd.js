const motdElement = document.getElementById("motd").children[0];

fetch("/static/motds").then(async rres => {
    const res = (await rres.text());
    const motds = res.split("\n").map(motd => motd.split("#", 2));
    let motd = motds[Math.floor(Math.random() * motds.length)];
    console.log(motd);
    motdElement.innerHTML = motd[0].trimEnd();
    motdElement.setAttribute("title", motd[1].trimStart());
});