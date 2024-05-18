// @ts-ignore
function initCalender() {
    const selectYear = document.getElementById("selectYear") as HTMLSelectElement;
    const currentYear = new Date().getFullYear();

    for (let year = currentYear; year > 2000; year--) {
        const option = document.createElement("option") as HTMLOptionElement;
        option.innerText = year.toString();
        option.value = year.toString();

        selectYear.appendChild(option);
    }

    (document.getElementById("bttnShowDiagram") as HTMLButtonElement).click();
}

// @ts-ignore
function loadNewData() {
    const year = (document.getElementById("selectYear") as HTMLSelectElement).value;

    fetch(`{{CONTEXT}}/rest/readings/${year}`, {}).then(res => {
        if (!res.ok) {
            throw new Error();
        }

        return res.json();
    }).then(data => {
        const processedData = preprocessData(data["readings"]);
        displayChart(processedData, "line", darkredRGB, undefined);
    }).catch(_ => {
        alert("Ein Fehler ist beim Laden der Daten aufgetreten");
    });
}