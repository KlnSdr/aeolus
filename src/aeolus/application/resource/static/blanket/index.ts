const temperatureColors = [
    { min: -Infinity, max: -6, cssVar: 'nNine' },
    { min: -5.9, max: -3, cssVar: 'nSix' },
    { min: -2.9, max: 0, cssVar: 'nThree' },
    { min: 0, max: 2.9, cssVar: 'zero' },
    { min: 3, max: 5.9, cssVar: 'three' },
    { min: 6, max: 8.9, cssVar: 'six' },
    { min: 9, max: 11.9, cssVar: 'nine' },
    { min: 12, max: 14.9, cssVar: 'twelve' },
    { min: 15, max: 17.9, cssVar: 'fifteen' },
    { min: 18, max: 20.9, cssVar: 'eighteen' },
    { min: 21, max: 23.9, cssVar: 'twentyOne' },
    { min: 24, max: Infinity, cssVar: 'twentyFour' }
];

let monthData: dataPoint[] = [];
let dayIndex: number = 0;

let sketchInstance: any = null;

function openDayView() {
    clearOutput();
    const output: HTMLDivElement = document.getElementById("blanketOutput") as HTMLDivElement;

    const lblYear: HTMLLabelElement = document.createElement("label");
    lblYear.innerText = "Jahr:";
    output.appendChild(lblYear);

    const selectYear: HTMLSelectElement = document.createElement("select");
    selectYear.id = "selectYear";
    output.appendChild(selectYear);

    const lblMonth: HTMLLabelElement = document.createElement("label");
    lblMonth.innerText = "Monat:";
    output.appendChild(lblMonth);

    const selectMonth: HTMLSelectElement = document.createElement("select");
    selectMonth.id = "selectMonth";
    output.appendChild(selectMonth);

    ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"].forEach((month, index) => {
        const option: HTMLOptionElement = document.createElement("option");
        option.innerText = month;
        option.value = prependZero(index + 1);
        selectMonth.appendChild(option);
    });

    const bttnShowDiagram: HTMLButtonElement = document.createElement("button");
    bttnShowDiagram.id = "bttnShowDiagram";
    bttnShowDiagram.innerText = "anzeigen";
    bttnShowDiagram.onclick = loadNewData;
    output.appendChild(bttnShowDiagram);

    const outCurrentDate: HTMLParagraphElement = document.createElement("p");
    outCurrentDate.id = "outCurrentDate";
    outCurrentDate.innerText = "DD.MM.YYYY";
    output.appendChild(outCurrentDate);

    const outDayColor: HTMLDivElement = document.createElement("div");
    outDayColor.id = "outDayColor";
    output.appendChild(outDayColor);

    const bttnDecreaseDay: HTMLButtonElement = document.createElement("button");
    bttnDecreaseDay.classList.add("bigButton");
    bttnDecreaseDay.onclick = decreaseDay;
    bttnDecreaseDay.innerText = "<";
    outDayColor.appendChild(bttnDecreaseDay);

    const lblTemperature: HTMLLabelElement = document.createElement("label");
    lblTemperature.id = "outTemperature";
    lblTemperature.innerText = "XY.Z°C";
    outDayColor.appendChild(lblTemperature);

    const bttnIncreaseDay: HTMLButtonElement = document.createElement("button");
    bttnIncreaseDay.classList.add("bigButton");
    bttnIncreaseDay.onclick = increaseDay;
    bttnIncreaseDay.innerText = ">";
    outDayColor.appendChild(bttnIncreaseDay);

    initCalender();
}

function openPreview() {
    clearOutput();
    const output: HTMLDivElement = document.getElementById("blanketOutput") as HTMLDivElement;

    const container: HTMLDivElement = document.createElement("div");

    const lblYear: HTMLLabelElement = document.createElement("label");
    lblYear.innerText = "Jahr:";
    container.appendChild(lblYear);

    const selectYear: HTMLSelectElement = document.createElement("select");
    selectYear.id = "selectYear";
    fillYearSelect(selectYear);
    container.appendChild(selectYear);

    const bttnShowDiagram: HTMLButtonElement = document.createElement("button");
    bttnShowDiagram.id = "bttnShowDiagram";
    bttnShowDiagram.innerText = "anzeigen";
    bttnShowDiagram.onclick = () => {
        const year = selectYear.value;
        loadYearData(year).then(data => {
            yearData = data;
        })
        .catch(() => {
            yearData = [];
        })
    };
    container.appendChild(bttnShowDiagram);

    output.appendChild(container);

    bttnShowDiagram.click();

    if (!sketchInstance) {
        // @ts-ignore
        sketchInstance = new p5(sketch); // Create a new p5 instance
    }
}

function clearOutput() {
    if (sketchInstance) {
        sketchInstance.remove(); // Remove the p5 instance, clearing the canvas
        sketchInstance = null; // Reset the instance to null
    }
    (document.getElementById("blanketOutput") as HTMLDivElement).innerHTML = "";
}

// @ts-ignore
function initCalender() {
    const selectYear = document.getElementById("selectYear") as HTMLSelectElement;
    fillYearSelect(selectYear);

    const selectMonth = document.getElementById("selectMonth") as HTMLSelectElement;
    selectMonth.value = prependZero(new Date().getMonth() + 1);

    loadNewData();
}

function fillYearSelect(element: HTMLSelectElement) {
    const currentYear = new Date().getFullYear();

    for (let year = currentYear; year > 2000; year--) {
        const option = document.createElement("option") as HTMLOptionElement;
        option.innerText = year.toString();
        option.value = year.toString();

        element.appendChild(option);
    }
}

// @ts-ignore
function loadNewData() {
    const year = (document.getElementById("selectYear") as HTMLSelectElement).value;
    const month = (document.getElementById("selectMonth") as HTMLSelectElement).value;

    loadMonthData(year, month)
        .then(data => {
            monthData = data;
            dayIndex = 0;
            updateDisplayValue();
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
            resolve(processedData.map(day => {
                return {
                    date: day.date,
                    value: parseFloat(day.value).toFixed(1) + " °C"
                };
            }));
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

function decreaseDay() {
    dayIndex--;
    checkIndex();
    updateDisplayValue();
}

function increaseDay() {
    dayIndex++;
    checkIndex();
    updateDisplayValue();
}

function checkIndex() {
    if (dayIndex < 0) {
        dayIndex = 0;
        // todo load prev month
    }

    if (dayIndex >= monthData.length) {
        dayIndex = monthData.length - 1;
        // todo load next month
    }
}

function updateDisplayValue() {
    (document.getElementById("outTemperature") as HTMLLabelElement).innerText = monthData[dayIndex].value;
    (document.getElementById("outCurrentDate") as HTMLLabelElement).innerText = monthData[dayIndex].date.split("-").reverse().join(".");
    changeOutputColor();
}

function changeOutputColor() {
    const colorKey: string = backgroundColorFromTemperature();
    const color: string = `var(--${colorKey})`;
    (document.getElementById("outDayColor") as HTMLDivElement).style.backgroundColor = color;
    (document.getElementById("outTemperature") as HTMLDivElement).style.color = color.replace(")", "") + "FG)";
    (document.getElementById("outDayColor") as HTMLDivElement).style.boxShadow = `0 0 10px 5px ${color}`;
}

function backgroundColorFromTemperature(): string {
    const temp: number = parseFloat(monthData[dayIndex].value);
    const colorEntry = temperatureColors.find(entry => temp >= entry.min && temp <= entry.max);

    return colorEntry ? colorEntry.cssVar : '--transparent';
}