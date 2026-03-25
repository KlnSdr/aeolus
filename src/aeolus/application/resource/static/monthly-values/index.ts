interface MonthlyValues {
    date: string;
    owner: string;
    operatingHoursHeating: number;
    operatingHoursWater: number;
    operatingHoursTwo: number;
    highTariffPower: number;
    lowTariffPower: number;
    householdPower: number;
    householdWater: number;
}

const displayNames: string[] = ["Datum", "Betriebsstunden Heizung", "Betriebsstunden Wasser", "Betriebsstunden 2", "Hochtarifstrom (1.81)", "Niedertarifstrom (1.82)", "Hausstrom", "Wasser"];
const keys: string[] = ["date", "operatingHoursHeating", "operatingHoursWater", "operatingHoursTwo", "highTariffPower", "lowTariffPower", "householdPower", "householdWater"];

function getMonthNameFromNumber(monthNumber: number): string {
    return ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"][monthNumber - 1];
}

function loadMonthlyValues() {
    const container: HTMLDivElement = document.getElementById("historicMonthlyValuesContainer") as HTMLDivElement;
    container.innerHTML = "";

    fetch(`{{CONTEXT}}/rest/monthly-values`).then(response => {
        if (!response.ok) {
            throw new Error("HTTP error, status = " + response.status);
        }
        return response.json();
    })
        .then((data: { readings: MonthlyValues[] }) => {
            const readings: MonthlyValues[] = data.readings;
            const years: { [key: string]: MonthlyValues[] } = {};
            readings.forEach(reading => {
                const year = reading.date.substring(0, 4);
                if (!years[year]) {
                    years[year] = [];
                }
                years[year].push(reading);
            });
            Object.keys(years).sort().reverse().forEach(year => {
                const heading: HTMLHeadingElement = document.createElement("h1");
                heading.innerText = year;
                container.appendChild(heading);

                const yearSection: HTMLDivElement = document.createElement("div");
                yearSection.classList.add("yearSection");
                container.appendChild(yearSection);

                years[year].forEach(reading => {
                    const card: HTMLDivElement = document.createElement("div");
                    card.classList.add("card");
                    card.onclick = () => openMonthlyValuesPopup(reading);

                    const lbl: HTMLLabelElement = document.createElement("label");
                    lbl.innerText = getMonthNameFromNumber(parseInt(reading.date.substring(5, 7)));
                    card.appendChild(lbl);

                    yearSection.appendChild(card);
                });
            });
        })
        .catch(_ => {
            container.innerText = "Fehler beim Laden der Monatswerte.";
        })
}

function openMonthlyValuesPopup(monthlyValues: MonthlyValues) {
    const units: string[] = ["", "h", "h", "kW/h", "kW/h", "kW/h", "kW/h", "m^3"];

    const container: HTMLDivElement = document.createElement("div");
    container.classList.add("popup-container");
    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.innerText = "Monatswerte " + getMonthNameFromNumber(parseInt(monthlyValues.date.substring(5, 7))) + " " + monthlyValues.date.substring(0, 4);
    container.appendChild(heading);

    // peak webdevelopent
    const table: HTMLTableElement = document.createElement("table");

    for (let i = 0; i < displayNames.length; i++) {
        if (keys[i] === "date") {
            continue;
        }
        const row: HTMLTableRowElement = document.createElement("tr");

        const columnLabel: HTMLTableCellElement = document.createElement("td");
        const label: HTMLLabelElement = document.createElement("label");
        label.innerText = displayNames[i];
        columnLabel.appendChild(label);

        const columnValue: HTMLTableCellElement = document.createElement("td");
        const value: HTMLLabelElement = document.createElement("label");
        value.innerText = (monthlyValues as any)[keys[i]];
        columnValue.appendChild(value);

        const columnUnit: HTMLTableCellElement = document.createElement("td");
        const unit: HTMLLabelElement = document.createElement("label");
        unit.innerText = units[i] || "";
        columnUnit.appendChild(unit);

        row.appendChild(columnLabel);
        row.appendChild(columnValue);
        row.appendChild(columnUnit);

        table.appendChild(row);
    }

    container.appendChild(table);
    openPopup(container);
}

function openPopupEnterMonthlyValues() {
    const inputTypes: string[] = ["date", "number", "number", "number", "number", "number", "number", "number"];

    const container: HTMLDivElement = document.createElement("div");
    container.classList.add("popup-container");
    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.innerText = "Monatswerte";
    container.appendChild(heading);

    // peak webdevelopent
    const table: HTMLTableElement = document.createElement("table");

    for (let i = 0; i < displayNames.length; i++) {
        const row: HTMLTableRowElement = document.createElement("tr");

        const columnLabel: HTMLTableCellElement = document.createElement("td");
        const label: HTMLLabelElement = document.createElement("label");
        label.innerText = displayNames[i];
        label.htmlFor = keys[i];
        columnLabel.appendChild(label);

        const columnValue: HTMLTableCellElement = document.createElement("td");
        const input: HTMLInputElement = document.createElement("input");
        input.type = inputTypes[i];
        input.id = keys[i];
        columnValue.appendChild(input);

        row.appendChild(columnLabel);
        row.appendChild(columnValue);
        table.appendChild(row);
    }

    container.appendChild(table);

    const bttnSave: HTMLButtonElement = document.createElement("button");
    bttnSave.innerText = "speichern";
    bttnSave.onclick = () => {
        const data: { [key: string]: number | string } = getDataObject(keys);
        closePopup(bttnSave);
        saveValues(data)
            .then(() => {
                displayAlert("Wert erfolgreich gespeichert.");
                loadMonthlyValues();
            })
            .catch(err => {
                displayAlert("Ein Fehler ist beim Speichern aufgetreten: " + err.message);
            });
    };
    container.appendChild(bttnSave);

    openPopup(container);
}

function getDataObject(keys: string[]): { [key: string]: number | string } {
    const data: { [key: string]: string | number } = {};
    keys.forEach(key => {
        const inputElement = document.getElementById(key) as HTMLInputElement;
        if (inputElement) {
            data[key] = inputElement.type === "number" ? parseInt(inputElement.value) : inputElement.value;
        }
    });

    return data;
}

function saveValues(data: { [key: string]: number | string }): Promise<void> {
    return new Promise((resolve, reject) => {
        fetch(`{{CONTEXT}}/rest/monthly-values/${(data["date"] as string).substring(0, 4)}/${(data["date"] as string).substring(5, 7)}`, {
            method: "PUT", headers: {
                "Content-Type": "application/json"
            }, body: JSON.stringify(data)
        }).then((response) => {
            if (!response.ok) {
                throw new Error("HTTP error, status = " + response.status);
            }
            resolve();
        }).catch((error) => {
            reject(error);
        });
    });
}
