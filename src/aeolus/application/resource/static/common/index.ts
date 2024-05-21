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