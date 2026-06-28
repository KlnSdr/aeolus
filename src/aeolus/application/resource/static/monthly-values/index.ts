interface Tariff {
    centsHighTariff: number;
    centsLowTariff: number;
    centsHouseholdPower: number;
    [key: string]: any;
}

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
    tariffPrices: Tariff;
    [key: string]: any;
}

function keyToTariff(key: string): string {
  if (key === "highTariffPower") {
    return "centsHighTariff";
  } else if (key === "lowTariffPower") {
    return "centsLowTariff";
  } else if (key === "householdPower") {
    return "centsHouseholdPower";
  }
  return "";
}

const displayNames: string[] = ["Datum", "Betriebsstunden Heizung", "Betriebsstunden Wasser", "Betriebsstunden 2", "Hochtarifstrom (1.81)", "Niedertarifstrom (1.82)", "Hausstrom", "Wasser"];
const keys: string[] = ["date", "operatingHoursHeating", "operatingHoursWater", "operatingHoursTwo", "highTariffPower", "lowTariffPower", "householdPower", "householdWater"];
const months: string[] = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"];

function getMonthNameFromNumber(monthNumber: number): string {
    return months[monthNumber - 1];
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
                const headingContainer: HTMLDivElement = document.createElement("div");
                headingContainer.classList.add("yearHeadingContainer");
                container.appendChild(headingContainer);
                const heading: HTMLHeadingElement = document.createElement("h1");
                heading.innerText = year;
                headingContainer.appendChild(heading);

                const bttnOpenSum: HTMLButtonElement = document.createElement("button");
                renderSumButton(bttnOpenSum);
                bttnOpenSum.onclick = () => openPopupSumYear(years[year]);
                headingContainer.appendChild(bttnOpenSum);

                const bttnOpenChart: HTMLButtonElement = document.createElement("button");
                renderChartButton(bttnOpenChart);
                bttnOpenChart.onclick = () => openPopupChartYear(years[year]);
                headingContainer.appendChild(bttnOpenChart);

                const bttnOpenTarif: HTMLButtonElement = document.createElement("button");
                renderTarifButton(bttnOpenTarif);
                bttnOpenTarif.onclick = () => openTariffPopup(years[year]);
                headingContainer.appendChild(bttnOpenTarif);

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
            (document.getElementById("bttnTrend") as HTMLButtonElement).onclick = () => openPopupTrend(years);
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
function openPopupMaintenance() {
    const inputTypes: string[] = ["date", "number", "number", "number", "number", "number", "number", "number"];

    const container: HTMLDivElement = document.createElement("div");
    container.classList.add("popup-container");
    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.innerText = "Wartung vermerken";
    container.appendChild(heading);

    // peak webdevelopent
    const table: HTMLTableElement = document.createElement("table");

    for (let i = 0; i < displayNames.length; i++) {
        if (keys[i] == "date") {
            continue;
        }
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

        const columnEnable: HTMLTableCellElement = document.createElement("td");
        const checkbox: HTMLInputElement = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.id = keys[i] + "_enable";
        columnEnable.appendChild(checkbox);

        row.appendChild(columnLabel);
        row.appendChild(columnValue);
        row.appendChild(checkbox);

        table.appendChild(row);
    }

    container.appendChild(table);

    const bttnSave: HTMLButtonElement = document.createElement("button");
    bttnSave.innerText = "speichern";
    bttnSave.onclick = () => {
        const data: { [key: string]: number | string } = getDataObjectMaintenance(keys);
        closePopup(bttnSave);
        saveValuesMaintenance(data)
            .then(() => {
                displayAlert("Wartung erfolgreich vermerkt.");
            })
            .catch(err => {
                displayAlert("Ein Fehler ist beim Speichern aufgetreten: " + err.message);
            });
    };
    container.appendChild(bttnSave);

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

function getDataObjectMaintenance(keys: string[]): { [key: string]: number | string } {
    const data: { [key: string]: string | number } = {};
    keys.filter(k => k != "date").forEach(key => {
        const inputElement = document.getElementById(key) as HTMLInputElement;
        if (inputElement) {
            if ((document.getElementById(key + "_enable") as HTMLInputElement).checked) {
                data[key] = inputElement.type === "number" ? parseInt(inputElement.value) : inputElement.value;
            } else {
                data[key] = -1;
            }
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

function saveValuesMaintenance(data: { [key: string]: number | string }): Promise<void> {
    return new Promise((resolve, reject) => {
        fetch(`{{CONTEXT}}/rest/monthly-values/temporary`, {
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

function openPopupChartYear(yearData: MonthlyValues[]) {
    const container: HTMLDivElement = document.createElement("div");
    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.innerText = "Monatswerte " + yearData[0].date.substring(0, 4);
    container.appendChild(heading);

    container.appendChild(getChartForYear(yearData));

    openPopup(container);
}

function openPopupSumYear(yearData: MonthlyValues[]) {
    const container: HTMLDivElement = document.createElement("div");
    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.innerText = "Monatswerte " + yearData[0].date.substring(0, 4);
    container.appendChild(heading);

    container.appendChild(getSumTableForYear(yearData));

    openPopup(container);
}

function getSumTableForYear(yearData: MonthlyValues[]): HTMLTableElement {
  const table: HTMLTableElement = document.createElement("table");

  const tableHeader: HTMLTableRowElement = document.createElement("tr");
  ["", ...months, "Summe"].forEach((name: string) => {
    const th: HTMLTableCellElement = document.createElement("th");
    th.innerText = name;
    tableHeader.appendChild(th);
  });
  table.appendChild(tableHeader);

  keys.forEach((key: string, index: number) => {
    if (key === "date") {
      return;
    }
    const row: HTMLTableRowElement = document.createElement("tr");
    const displayName: string = displayNames[index];
    row.appendChild(createTableCell(displayName));

    months.forEach((_month: string, monthIndex: number) => {
      if (monthIndex >= yearData.length) {
      row.appendChild(createTableCell(""));
        return;
      }
      row.appendChild(createTableCell(yearData[monthIndex][key]));
    });

    row.appendChild(createTableCell(yearData.map((month: MonthlyValues) => month[key]).reduce((acc: number, val: number) => acc + val, 0)))
    table.appendChild(row);
  });

  return table;
}

function createTableCell(value: string): HTMLTableCellElement {
  const td: HTMLTableCellElement = document.createElement("td");
  td.innerText = value;
  return td;
}

function renderSumButton(bttn: HTMLButtonElement) {
  bttn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><!--!Font Awesome Free v7.3.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2026 Fonticons, Inc.--><path fill="rgb(255, 255, 255)" d="M480 96C515.3 96 544 124.7 544 160L544 480C544 515.3 515.3 544 480 544L160 544L153.5 543.7C121.2 540.4 96 513.1 96 480L96 160C96 124.7 124.7 96 160 96L480 96zM160 384L160 480L288 480L288 384L160 384zM352 384L352 480L480 480L480 384L352 384zM160 320L288 320L288 224L160 224L160 320zM352 320L480 320L480 224L352 224L352 320z"/></svg>';
}

function renderChartButton(bttn: HTMLButtonElement) {
  bttn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><!--!Font Awesome Free v7.3.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2026 Fonticons, Inc.--><path fill="rgb(255, 255, 255)" d="M128 128C128 110.3 113.7 96 96 96C78.3 96 64 110.3 64 128L64 464C64 508.2 99.8 544 144 544L544 544C561.7 544 576 529.7 576 512C576 494.3 561.7 480 544 480L144 480C135.2 480 128 472.8 128 464L128 128zM534.6 214.6C547.1 202.1 547.1 181.8 534.6 169.3C522.1 156.8 501.8 156.8 489.3 169.3L384 274.7L326.6 217.4C314.1 204.9 293.8 204.9 281.3 217.4L185.3 313.4C172.8 325.9 172.8 346.2 185.3 358.7C197.8 371.2 218.1 371.2 230.6 358.7L304 285.3L361.4 342.7C373.9 355.2 394.2 355.2 406.7 342.7L534.7 214.7z"/></svg>';
}

function renderTarifButton(bttn: HTMLButtonElement) {
  bttn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><!--!Font Awesome Free v7.3.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2026 Fonticons, Inc.--><path fill="rgb(255, 255, 255)" d="M169.3 256C196.8 163.5 282.5 96 384 96L448 96C465.7 96 480 110.3 480 128C480 145.7 465.7 160 448 160L384 160C318.4 160 262 199.5 237.3 256L368 256C381.3 256 392 266.7 392 280C392 293.3 381.3 304 368 304L224.8 304C224.3 309.3 224 314.6 224 320C224 325.4 224.3 330.7 224.8 336L368 336C381.3 336 392 346.7 392 360C392 373.3 381.3 384 368 384L237.3 384C262 440.5 318.4 480 384 480L448 480C465.7 480 480 494.3 480 512C480 529.7 465.7 544 448 544L384 544C282.5 544 196.8 476.5 169.3 384L136 384C122.7 384 112 373.3 112 360C112 346.7 122.7 336 136 336L160.6 336C159.9 325.5 159.9 314.5 160.6 304L136 304C122.7 304 112 293.3 112 280C112 266.7 122.7 256 136 256L169.3 256z"/></svg>';
}

function openPopupTrend(yearData: {[key: string]: MonthlyValues[]}) {
    const container: HTMLDivElement = document.createElement("div");
    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.innerText = "Jahrestrend";
    container.appendChild(heading);

    container.appendChild(getChartForYears(yearData));

    openPopup(container);
}

function openTariffPopup(yearData: MonthlyValues[]) {
    const container: HTMLDivElement = document.createElement("div");
    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.innerText = "Kosten " + yearData[0].date.substring(0, 4);
    container.appendChild(heading);

    const bttnUpdateTariff: HTMLButtonElement = document.createElement("button");
    bttnUpdateTariff.innerText = "Tarif anpassen";
    bttnUpdateTariff.addEventListener("click", () => {
      closePopup(bttnUpdateTariff);
      openTariffEditPopup(yearData)
    });
    container.appendChild(bttnUpdateTariff);

    container.appendChild(buildTariffUI(yearData));

    openPopup(container);
}

function buildTariffUI(yearData: MonthlyValues[]): HTMLTableElement {
  const table: HTMLTableElement = document.createElement("table");

  const tableHeader: HTMLTableRowElement = document.createElement("tr");
  ["", "Tarif (€/kWh)", ...months.map(m => m + " (kWh)"), "Summe (€)"].forEach((name: string) => {
    const th: HTMLTableCellElement = document.createElement("th");
    th.innerText = name;
    tableHeader.appendChild(th);
  });
  table.appendChild(tableHeader);

  keys.forEach((key: string, index: number) => {
    if (["date", "operatingHoursHeating", "operatingHoursWater", "operatingHoursTwo", "householdWater"].includes(key)) {
      return;
    }
    const row: HTMLTableRowElement = document.createElement("tr");
    const displayName: string = displayNames[index];
    row.appendChild(createTableCell(displayName));

    if (yearData.length > 0) {
      row.appendChild(createTableCell(displayTariff(yearData[0].tariffPrices[keyToTariff(key)])));
    } else {
      row.appendChild(createTableCell(""));
    }

    months.forEach((_month: string, monthIndex: number) => {
      if (monthIndex >= yearData.length) {
      row.appendChild(createTableCell(""));
        return;
      }
      row.appendChild(createTableCell(yearData[monthIndex][key]));
    });

    row.appendChild(createTableCell((yearData.map((month: MonthlyValues) => month[key]).reduce((acc: number, val: number) => acc + val, 0) * yearData[0].tariffPrices[keyToTariff(key)] * .0001).toFixed(2)))
    table.appendChild(row);
  });

  return table;
}

function displayTariff(cents: number): string {
  return (cents * 0.0001).toFixed(4);
}

function openTariffEditPopup(yearData: MonthlyValues[]) {
    const container: HTMLDivElement = document.createElement("div");
    const heading: HTMLHeadingElement = document.createElement("h2");
    const year: string = yearData[0].date.substring(0, 4)
    heading.innerText = "Preise " + year;
    container.appendChild(heading);

    const prices: {[key: string]: {eur: number, cents: number}} = {};
    container.appendChild(tariffEditPopupTable(yearData, prices));

    const bttnSave: HTMLButtonElement = document.createElement("button");
    bttnSave.innerText = "speichern";
    bttnSave.addEventListener("click", _ => {
      saveTariffPrices(prices, year)
      .then(_ => {
        yearData.forEach((month: MonthlyValues) => {
          month.tariffPrices = {
            centsHighTariff: toCents(prices, "highTariffPower"),
            centsLowTariff: toCents(prices, "lowTariffPower"),
            centsHouseholdPower: toCents(prices, "householdPower")
          }
        })
        closePopup(bttnSave);
        openTariffPopup(yearData);
      })
      .catch(err => {
        const p: HTMLParagraphElement = document.createElement("p");
        p.innerText = "Tarife konnten nicht gespeichert werden";
        console.error(err);
        openPopup(p);
      })
    });
    container.appendChild(bttnSave);

    openPopup(container);
}

function toCents(data: {[key: string]: {eur: number, cents: number}}, key: string): number {
  return parseInt((parseFloat(data[key].eur + "." + data[key].cents) * 10_000).toFixed(0));
}

function saveTariffPrices(data: {[key: string]: {eur: number, cents: number}}, year: string): Promise<void> {
  return new Promise((resolve, reject) => {
    fetch(`{{CONTEXT}}/rest/tariff-prices/${year}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        centsHighTariff: toCents(data, "highTariffPower"),
        centsLowTariff: toCents(data, "lowTariffPower"),
        centsHouseholdPower: toCents(data, "householdPower"),
      })
    }).then((response: Response) => {
      if (!response.ok) {
        throw new Error("HTTP " + response.status + " " + response.statusText);
      }
      resolve();
    })
    .catch(err => {
      reject(err);
    });
  });
}

function tariffEditPopupTable(yearData: MonthlyValues[], prices: {[key: string]: {eur: number, cents: number}}) {
  const table: HTMLTableElement = document.createElement("table");

  const tableHeader: HTMLTableRowElement = document.createElement("tr");
  ["", "Euro", "", "Cent"].forEach((name: string) => {
    const th: HTMLTableCellElement = document.createElement("th");
    th.innerText = name;
    tableHeader.appendChild(th);
  });
  table.appendChild(tableHeader);

  keys.forEach((key: string, index: number) => {
    if (["date", "operatingHoursHeating", "operatingHoursWater", "operatingHoursTwo", "householdWater"].includes(key)) {
      return;
    }
    const row: HTMLTableRowElement = document.createElement("tr");
    const displayName: string = displayNames[index];
    row.appendChild(createTableCell(displayName));

    let price: string;
    if (yearData.length > 0) {
      price = displayTariff(yearData[0].tariffPrices[keyToTariff(key)])
    } else {
      price = displayTariff(yearData[0].tariffPrices[keyToTariff(key)])
    }
    const splitPrice: string[] = price.split(".");
    prices[key] = {
      eur: parseInt(splitPrice[0]),
      cents: parseInt(splitPrice[1])
    }

    row.appendChild(createTableCellWithInput(splitPrice[0], (value: string) => prices[key].eur = parseInt(value)))
    row.appendChild(createTableCell(","));
    row.appendChild(createTableCellWithInput(splitPrice[1], (value: string) => prices[key].cents = parseInt(value)))

    table.appendChild(row);
  });

  return table;
}

function createTableCellWithInput(value: string, onChange: (value: string) => void): HTMLTableCellElement {
  const td: HTMLTableCellElement = document.createElement("td");

  const input: HTMLInputElement = document.createElement("input");
  input.value = value;
  input.type = "number";
  input.onchange = _ => {
    onChange(input.value);
  }
  td.appendChild(input);

  return td;
}

