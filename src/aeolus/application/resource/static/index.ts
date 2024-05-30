function startup() {
    displayCurrentUserDisplayName().then(() => {});
    loadLastReading();
}

function loadLastReading() {
    const lastValue = document.getElementById("lastValue") as HTMLLabelElement;
    const lastValueFrom = document.getElementById("lastValueFrom") as HTMLLabelElement;

    fetch("{{CONTEXT}}/rest/readings/last", {}).then(res => {
        if (res.ok) {
            return res.json();
        }
        throw new Error("Something went wrong");
    }).then(data => {
        lastValue.innerText = parseFloat(data["value"]).toFixed(1) + " °C";
        lastValueFrom.innerText = `vom: ${isoToDisplayDate(data["date"])}`;
    }).catch(e => {
        lastValue.innerText = e.message;
        lastValueFrom.innerText = "";
    })
}

function isoToDisplayDate(isoDate: string) {
    const splitIso: string[] = isoDate.split("-");
    return splitIso[2] + "." + splitIso[1] + "." + splitIso[0];
}

async function displayCurrentUserDisplayName() {
    fetch("{{CONTEXT}}/rest/users/loginUserInfo", {
        method: "GET", headers: {
            "Content-Type": "application/json",
        }
    }).then((response) => {
        if (response.ok) {
            return response.json();
        } else {
            throw new Error("HTTP error, status = " + response.status);
        }
    }).then((data) => {
        (document.getElementById("lblCurrentUser") as HTMLLabelElement).innerText = `(${data["displayName"]})`;
    }).catch((error) => {
        alert(error.message);
    });
}

function openAddValueManually() {
    const container = document.createElement("div");

    const heading: HTMLHeadingElement = document.createElement("h3");
    heading.innerText = "Daten eintragen";
    container.appendChild(heading);

    // peak web development
    const table: HTMLTableElement = document.createElement("table");

    const rowDate: HTMLTableRowElement = document.createElement("tr");

    const tdDateLbl: HTMLTableCellElement = document.createElement("td");
    const dateLbl: HTMLLabelElement = document.createElement("label");
    dateLbl.innerText = "Datum:";
    tdDateLbl.appendChild(dateLbl);
    rowDate.appendChild(tdDateLbl);

    const tdDateInput: HTMLTableCellElement = document.createElement("td");
    const dateInput: HTMLInputElement = document.createElement("input");
    dateInput.type = "date";
    tdDateInput.appendChild(dateInput);
    rowDate.appendChild(tdDateInput);

    const rowValue: HTMLTableRowElement = document.createElement("tr");

    const tdValueLbl: HTMLTableCellElement = document.createElement("td");
    const valueLbl: HTMLLabelElement = document.createElement("label");
    valueLbl.innerText = "Temperatur:";
    tdValueLbl.appendChild(valueLbl);
    rowValue.appendChild(tdValueLbl);

    const tdValueInput: HTMLTableCellElement = document.createElement("td");
    const valueInput: HTMLInputElement = document.createElement("input");
    valueInput.type = "number";
    tdValueInput.appendChild(valueInput);
    rowValue.appendChild(tdValueInput);

    table.appendChild(rowDate);
    table.appendChild(rowValue);

    container.appendChild(table);

    const saveBttn: HTMLButtonElement = document.createElement("button");
    saveBttn.innerText = "speichern";
    saveBttn.onclick = () => {
        closePopup(saveBttn);
        saveValue(dateInput.value, valueInput.value)
            .then(() => {
                displayAlert("Wert erfolgreich gespeichert.");
            })
            .catch(err => {
                displayAlert("Ein Fehler ist beim Speichern aufgetreten: " + err.message);
            });
    };
    container.appendChild(saveBttn);

    openPopup(container);
}

function displayAlert(msg: string) {
    const msgOut: HTMLParagraphElement = document.createElement("p");
    msgOut.innerText = msg;

    openPopup(msgOut);
}

function saveValue(date: string, value: string): Promise<void> {
    return new Promise((resolve, reject) => {
        fetch("{{CONTEXT}}/rest/readings", {
            method: "POST", headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({value: value, date: date})
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