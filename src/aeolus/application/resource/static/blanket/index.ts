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

    const selectMonth = document.getElementById("selectMonth") as HTMLSelectElement;
    selectMonth.value = prependZero(new Date().getMonth() + 1);

    loadNewData();
}

// @ts-ignore
function loadNewData() {
    const year = (document.getElementById("selectYear") as HTMLSelectElement).value;
    const month = (document.getElementById("selectMonth") as HTMLSelectElement).value;

    loadMonthData(year, month)
        .then(data => {
            console.log(data);
        })
        .catch(displayErrorPopUp);
}

function loadMonthData(year: string, month: string): Promise<dataPoint[]> {
    return new Promise((resolve, reject) => {
        fetch(`{{CONTEXT}}/rest/readings/${year}/${month}`, {}).then(res => {
            if (!res.ok) {
                throw new Error(res.statusText);
            }

            return res.json();
        }).then(data => {
            const processedData: dataPoint[] = preprocessData(data["readings"]);
            if (processedData.length === 0) {
                throw new Error("Keine Daten vorhanden");
            }
            resolve(processedData);
        }).catch(e => {
            reject(e);
        });
    });
}

function displayErrorPopUp(reason: any) {
    const errorBody: HTMLDivElement = document.createElement("div");
    errorBody.innerText = `Ein Fehler ist aufgetreten: ${reason}`.replace("Error: ", "");
    openPopup(errorBody);
}