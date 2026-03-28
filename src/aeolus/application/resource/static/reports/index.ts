interface Report {
    "owner": string;
    "reportType": "MONTH" | "YEAR";
    "name": string;
    "scheduleDay": "UNSET" | "FIRST_DAY_OF_MONTH" | "FIRST_DAY_OF_WEEK" | "FIRST_DAY_OF_YEAR";
    "id": string;
    "trigger": "MANUAL" | "SCHEDULE",
    "scheduleHour": number;
    "scheduleMinute": number;
    "reportFeatures": (
        "TEMPERATURE_CURVE" |
        "TREND" |
        "AVERAGES" |
        "OPERATING_HOURS_HEATING_CURVE" |
        "OPERATING_HOURS_WATER_CURVE" |
        "OPERATING_HOURS_TWO_CURVE" |
        "HIGH_TARIFF_POWER_CURVE" |
        "LOW_TARIFF_POWER_CURVE" |
        "HOUSEHOLD_POWER_CURVE" |
        "HOUSEHOLD_WATER_CURVE"
    )[]
}

interface UIDefinition {
    id: string;
    label: string;
    key: string;
    type: "text" | "select" | "checkboxes" | "time";
    classes?: string[];
    options?: {
        value: string;
        label: string;
        ifSelected?: UIDefinition[];
    }[];
}

const inputs: UIDefinition[] = [
    {
        id: "reportName",
        label: "Name:",
        key: "name",
        type: "text",
    },
    {
        id: "reportType",
        key: "reportType",
        label: "Typ:",
        type: "select",
        options: [
            {
                value: "MONTH",
                label: "Monatsbericht (Vormonat)",
            },
            {
                value: "YEAR",
                label: "Jahresbericht (Vorjahr)",
            },
        ],
    },
    {
        id: "reportFeatures",
        label: "Auswertungen:",
        key: "reportFeatures",
        type: "checkboxes",
        options: [
            {
                value: "TEMPERATURE_CURVE",
                label: "Temperaturverlauf",
            },
            {
                value: "TREND",
                label: "Trends",
            },
            {
                value: "AVERAGES",
                label: "Durchschnittswerte",
            },
            {
                value: "OPERATING_HOURS_HEATING_CURVE",
                label: "Verlauf Betriebsstunden Heizung (nur für Jahresauswertung)",
            },
            {
                value: "OPERATING_HOURS_WATER_CURVE",
                label: "Verlauf Betriebsstunden Wasser (nur für Jahresauswertung)",
            },
            {
                value: "OPERATING_HOURS_TWO_CURVE",
                label: "Verlauf Betriebsstunden 2 (nur für Jahresauswertung)",
            },
            {
                value: "HIGH_TARIFF_POWER_CURVE",
                label: "Verlauf Stromverbrauch Hochtarif (nur für Jahresauswertung)",
            },
            {
                value: "LOW_TARIFF_POWER_CURVE",
                label: "Verlauf Stromverbrauch Niedertarif (nur für Jahresauswertung)",
            },
            {
                value: "HOUSEHOLD_POWER_CURVE",
                label: "Verlauf Stromverbrauch (nur für Jahresauswertung)",
            },
            {
                value: "HOUSEHOLD_WATER_CURVE",
                label: "Verlauf Wasserverbrauch (nur für Jahresauswertung)",
            },
        ],
    },
    {
        id: "reportTrigger",
        key: "trigger",
        label: "Auslöser:",
        type: "select",
        options: [
            {
                value: "MANUAL",
                label: "manuell",
            },
            {
                value: "SCHEDULED",
                label: "automatisch",
                ifSelected: [
                    {
                        id: "reportScheduleDay",
                        label: "Tag:",
                        key: "scheduleDay",
                        type: "select",
                        options: [
                            {
                                value: "FIRST_DAY_OF_WEEK",
                                label: "erster Tag der Woche",
                            },
                            {
                                value: "FIRST_DAY_OF_MONTH",
                                label: "erster Tag des Monats",
                            },
                            {
                                value: "FIRST_DAY_OF_YEAR",
                                label: "erster Tag des Jahres",
                            },
                        ],
                    },
                    {
                        id: "scheduleTime",
                        label: "Uhrzeit (nicht eher als):",
                        key: "scheduleTime",
                        type: "time",
                    },
                ],
            },
        ],
    },
];

function openPopupNewReport() {
    const container: HTMLDivElement = document.createElement("div");

    const heading: HTMLHeadingElement = document.createElement("h2");
    heading.textContent = "Neuer Bericht";
    container.appendChild(heading);

    const table: HTMLTableElement = document.createElement("table");
    render(inputs, table);
    container.appendChild(table);

    const bttnSave: HTMLButtonElement = document.createElement("button");
    bttnSave.textContent = "Speichern";
    bttnSave.addEventListener("click", () => {
        const reportData: {[key: string]: any} = readInputValues(inputs);
        saveReport(reportData)
            .then(() => {
                closePopup(bttnSave);
                displayAlert("Bericht erfolgreich gespeichert.");
                loadReports();
            })
            .catch((err) => {
                displayAlert("Ein Fehler ist beim Speichern aufgetreten: " + err.message);
            });
    });
    container.appendChild(bttnSave);

    openPopup(container);
}

function saveReport(data: {[key: string]: any}): Promise<void> {
    return new Promise((resolve, reject) => {
        fetch("{{CONTEXT}}/rest/report", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(data)
        })
        .then((response: Response) => {
            if (!response.ok) {
                throw new Error("HTTP error, status = " + response.status);
            }
            resolve();
        })
        .catch((error: any) => {
            console.error("Error saving report:", error);
            reject(error);
        });
    });
}

function readInputValues(ui: UIDefinition[]): {[key: string]: any} {
    let reportData: {[key: string]: any} = {};
    ui.forEach((input) => {
        switch (input.type) {
            case "text":
                reportData[input.key] = (
                    document.getElementById(input.id) as HTMLInputElement
                ).value;
                break;
            case "time":
                reportData[input.key] = (
                    document.getElementById(input.id) as HTMLInputElement
                ).value;
                break;
            case "select":
                reportData[input.key] = (
                    document.getElementById(input.id) as HTMLSelectElement
                ).value;
                if (input.options) {
                    const selectedOption = input.options.find(
                        (opt) => opt.value === reportData[input.key]
                    );
                    if (selectedOption?.ifSelected) {
                        const nestedData = readInputValues(selectedOption.ifSelected);
                        reportData = {...reportData, ...nestedData};
                    }
                }
                break;
            case "checkboxes":
                const selectedOptions: string[] = [];
                input.options?.forEach((option) => {
                    const checkbox = document.getElementById(
                        `${input.id}_${option.value}`
                    ) as HTMLInputElement;
                    if (checkbox.checked) {
                        selectedOptions.push(option.value);
                    }
                });
                reportData[input.key] = selectedOptions;
                break;
        }
    });
    return reportData;
}

function render(uiDef: UIDefinition[], parent: HTMLElement): void {
    uiDef.forEach((input) => {
        const row: HTMLTableRowElement = document.createElement("tr");

        const labelCell: HTMLTableCellElement = document.createElement("td");
        labelCell.textContent = input.label;
        row.appendChild(labelCell);

        const inputCell: HTMLTableCellElement = document.createElement("td");
        let inputElement: HTMLElement;

        switch (input.type) {
            case "text":
                inputElement = document.createElement("input");
                (inputElement as HTMLInputElement).type = "text";
                break;
            case "time":
                inputElement = document.createElement("input");
                (inputElement as HTMLInputElement).type = "time";
                break;
            case "select":
                inputElement = document.createElement("select");
                input.options?.forEach((option) => {
                    const optionElement: HTMLOptionElement =
                        document.createElement("option");
                    optionElement.value = option.value;
                    optionElement.textContent = option.label;
                    (inputElement as HTMLSelectElement).appendChild(optionElement);
                });
                inputElement.onchange = () => {
                    Array.from(
                        document.getElementsByClassName("isSelected" + input.id)
                    ).forEach((el) => el.remove());
                    const value: string = (inputElement as HTMLSelectElement).value;
                    const selectedOption = input.options?.find(
                        (opt) => opt.value === value
                    );
                    if (selectedOption?.ifSelected) {
                        render(
                            selectedOption.ifSelected.map((ui: UIDefinition) => {
                                return {
                                    ...ui,
                                    classes: ui.classes
                                        ? [...ui.classes, "isSelected" + input.id]
                                        : ["isSelected" + input.id],
                                };
                            }),
                            parent
                        );
                    }
                };
                break;
            case "checkboxes":
                inputElement = document.createElement("div");
                input.options?.forEach((option) => {
                    const checkboxContainer: HTMLDivElement =
                        document.createElement("div");

                    const checkbox: HTMLInputElement = document.createElement("input");
                    checkbox.type = "checkbox";
                    checkbox.value = option.value;
                    checkbox.id = `${input.id}_${option.value}`;
                    checkboxContainer.appendChild(checkbox);

                    const checkboxLabel: HTMLLabelElement =
                        document.createElement("label");
                    checkboxLabel.htmlFor = checkbox.id;
                    checkboxLabel.textContent = option.label;
                    checkboxContainer.appendChild(checkboxLabel);

                    (inputElement as HTMLDivElement).appendChild(checkboxContainer);
                });
                break;
        }
        inputElement.id = input.id;
        inputElement.classList.add(...(input.classes || []));
        row.classList.add(...(input.classes || []));

        inputCell.appendChild(inputElement);
        row.appendChild(inputCell);
        parent.appendChild(row);
    });
}

function loadReports() {
    const container: HTMLDivElement = document.getElementById("reportView") as HTMLDivElement;
    container.innerHTML = "";
    fetchReports()
        .then((reports: Report[]) => {
            reports.forEach((report) => {
                const card: HTMLDivElement = document.createElement("div");
                card.classList.add("reportCard");

                const heading: HTMLHeadingElement = document.createElement("h3");
                heading.textContent = report.name;
                card.appendChild(heading);

                const detailsContainer: HTMLDivElement = document.createElement("div");
                detailsContainer.classList.add("reportDetails");

                const lblType: HTMLParagraphElement = document.createElement("p");
                lblType.textContent = "Typ:";
                detailsContainer.appendChild(lblType);
                const lblTypeValue: HTMLParagraphElement = document.createElement("p");
                lblTypeValue.textContent = report.reportType === "MONTH" ? "Monatsbericht" : "Jahresbericht";
                detailsContainer.appendChild(lblTypeValue);

                const lblTrigger: HTMLParagraphElement = document.createElement("p");
                lblTrigger.textContent = "Auslöser:";
                detailsContainer.appendChild(lblTrigger);
                const lblTriggerValue: HTMLParagraphElement = document.createElement("p");
                lblTriggerValue.textContent = report.trigger === "MANUAL" ? "manuell" : (`automatisch (${scheduleDayToString(report.scheduleDay)}, ${report.scheduleHour}:${report.scheduleMinute < 10 ? "0" : ""}${report.scheduleMinute} Uhr)`);
                detailsContainer.appendChild(lblTriggerValue);

                const lblFeatures: HTMLParagraphElement = document.createElement("p");
                lblFeatures.textContent = "Enthaltene Auswertungen:";
                detailsContainer.appendChild(lblFeatures);
                const featuresList: HTMLUListElement = document.createElement("ul");
                report.reportFeatures.forEach((feature) => {
                    const featureItem: HTMLLIElement = document.createElement("li");
                    switch (feature) {
                        case "TEMPERATURE_CURVE":
                            featureItem.textContent = "Temperaturverlauf";
                            break;
                        case "TREND":
                            featureItem.textContent = "Trends";
                            break;
                        case "AVERAGES":
                            featureItem.textContent = "Durchschnittswerte";
                            break;
                        case "OPERATING_HOURS_HEATING_CURVE":
                            featureItem.textContent = "Verlauf Betriebsstunden Heizung";
                            break;
                        case "OPERATING_HOURS_WATER_CURVE":
                            featureItem.textContent = "Verlauf Betriebsstunden Wasser";
                            break;
                        case "OPERATING_HOURS_TWO_CURVE":
                            featureItem.textContent = "Verlauf Betriebsstunden 2";
                            break;
                        case "HIGH_TARIFF_POWER_CURVE":
                            featureItem.textContent = "Verlauf Stromverbrauch Hochtarif";
                            break;
                        case "LOW_TARIFF_POWER_CURVE":
                            featureItem.textContent = "Verlauf Stromverbrauch Niedertarif";
                            break;
                        case "HOUSEHOLD_POWER_CURVE":
                            featureItem.textContent = "Verlauf Stromverbrauch";
                            break;
                        case "HOUSEHOLD_WATER_CURVE":
                            featureItem.textContent = "Verlauf Wasserverbrauch";
                            break;
                    }
                    featuresList.appendChild(featureItem);
                });
                detailsContainer.appendChild(featuresList);

                card.appendChild(detailsContainer);

                const containerButtons: HTMLDivElement = document.createElement("div");
                containerButtons.classList.add("buttonBar");

                const bttnDelete: HTMLButtonElement = document.createElement("button");
                bttnDelete.textContent = "Löschen";
                bttnDelete.classList.add("deleteButton");
                bttnDelete.addEventListener("click", () => {
                    if (confirm("Möchten Sie diesen Bericht wirklich löschen?")) {
                        deleteReport(report.id)
                            .then(() => {
                                displayAlert("Bericht erfolgreich gelöscht.");
                                loadReports();
                            })
                            .catch((err: any) => {
                                displayAlert("Ein Fehler ist beim Löschen aufgetreten: " + err);
                            });
                    }
                });
                containerButtons.appendChild(bttnDelete);

                const bttnTrigger: HTMLButtonElement = document.createElement("button");
                bttnTrigger.textContent = "Jetzt ausführen";
                bttnTrigger.addEventListener("click", () => {
                    renderReport(report.id);
                });
                containerButtons.appendChild(bttnTrigger);
                card.appendChild(containerButtons);

                container.appendChild(card);
            });
        })
        .catch((error) => {
            console.error("Error fetching reports:", error);
            displayAlert("Ein Fehler ist beim Laden der Berichte aufgetreten: " + error.message);
        });
}

function scheduleDayToString(val: string): string {
    switch (val) {
        case "UNSET":
            return "nicht festgelegt";
        case "FIRST_DAY_OF_MONTH":
            return "erster Tag des Monats";
        case "FIRST_DAY_OF_WEEK":
            return "erster Tag der Woche";
        case "FIRST_DAY_OF_YEAR":
            return "erster Tag des Jahres";
        default:
            return val;
    }
}

function fetchReports(): Promise<Report[]> {
    return new Promise((resolve, reject) => {
        fetch(`{{CONTEXT}}/rest/report`)
            .then((response) => {
                if (!response.ok) {
                    throw new Error("HTTP error, status = " + response.status);
                }
                return response.json();
            })
            .then((json: {reports: Report[]}) => {
                resolve(json.reports.sort((a, b) => a.name.localeCompare(b.name)));
            })
            .catch((error) => {
                reject(error);
            });
    });
}

function deleteReport(id: string): Promise<void> {
    return new Promise((resolve, reject) => {
        fetch(`{{CONTEXT}}/rest/report/id/${id}`, {
            method: "DELETE"
        })
            .then((response) => {
                if (!response.ok) {
                    throw new Error("HTTP error, status = " + response.status);
                }
                resolve();
            })
            .catch((error) => {
                reject(error);
            });
    });
}

function  renderReport(reportId: string) {
    // fetch(`{{CONTEXT}}/rest/report/id/${reportId}/render`, {
    //     method: "POST"
    // })
    //     .then((response) => {
    //         if (!response.ok) {
    //             throw new Error("HTTP error, status = " + response.status);
    //         }
    //         console.log("Report triggered successfully.");
    //     })
    //     .catch((error) => {
    //         console.error("Error rendering report:", error);
    //     });
    // @ts-ignore
    window.open(`{{CONTEXT}}/rest/report/id/${reportId}/render`, '_blank').focus();
}