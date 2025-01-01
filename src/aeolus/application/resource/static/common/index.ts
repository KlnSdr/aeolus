function displayRawData(data: dataPoint[]) {
    let halveLen = Math.floor(data.length / 2);

    if (halveLen !== data.length / 2) {
        data.push({date: "", value: ""})
        halveLen++;
    }

    const table: HTMLTableElement = document.getElementById("tblRawData") as HTMLTableElement;
    table.innerHTML = '';

    for (let i = 0; i < halveLen; i++) {
        const dayEven = data[i];
        const dayOdd = data[halveLen + i];

        const tr: HTMLTableRowElement = document.createElement("tr");

        const tdEvenDate: HTMLTableCellElement = document.createElement("td");
        tdEvenDate.innerText = dayEven.date;
        tr.appendChild(tdEvenDate);

        const tdEvenValue: HTMLTableCellElement = document.createElement("td");
        tdEvenValue.innerText = dayEven.value + " °C";
        tr.appendChild(tdEvenValue);

        const tdOddDate: HTMLTableCellElement = document.createElement("td");
        tdOddDate.innerText = dayOdd.date;
        tr.appendChild(tdOddDate);

        const tdOddValue: HTMLTableCellElement = document.createElement("td");
        tdOddValue.innerText = dayOdd.value + (dayOdd.value !== "" ? " °C": "");
        tr.appendChild(tdOddValue);

        table.appendChild(tr);
    }
}

function displayMinMaxAvg(data: dataPoint[]) {
    const min = document.getElementById("minTemp") as HTMLLabelElement;
    const minDate = document.getElementById("minTempDate") as HTMLLabelElement;
    const max = document.getElementById("maxTemp") as HTMLLabelElement;
    const maxDate = document.getElementById("maxTempDate") as HTMLLabelElement;
    const avg = document.getElementById("avgTemp") as HTMLLabelElement;

    if (data.length === 0) {
        min.innerText = "Keine Daten";
        minDate.innerText = "";
        max.innerText = "Keine Daten";
        maxDate.innerText = "";
        avg.innerText = "Keine Daten";
        return;
    }

    const values = data.filter(day => day.value !== "").map(day => parseFloat(day.value));

    min.innerText = Math.min(...values).toFixed(1) + " °C";
    minDate.innerText = data[values.indexOf(Math.min(...values))].date;
    max.innerText = Math.max(...values).toFixed(1) + " °C";
    maxDate.innerText = data[values.indexOf(Math.max(...values))].date;
    avg.innerText = (values.reduce((a, b) => a + b, 0) / values.length).toFixed(1) + " °C";
}

function downloadRawData(data: dataPoint[], filename: string) {
    const blob: Blob = new Blob([rawDataToCsv(data)], {type: "text/plain;charset=utf-8"});

    const downloadLink: HTMLAnchorElement = document.createElement("a") as HTMLAnchorElement;
    downloadLink.href = URL.createObjectURL(blob);
    downloadLink.download = filename + ".csv";

    downloadLink.click();
}

function rawDataToCsv(data: dataPoint[]): string {
    return "datum,temperatur\n" + data.filter(day => day.date !== "" && day.value !== "").map(day => day.date + "," + day.value).join("\n");
}