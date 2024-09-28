const temperatureColors = [
    { min: -Infinity, max: -6, cssVar: '--nNine' },
    { min: -5.9, max: -3, cssVar: '--nSix' },
    { min: -2.9, max: 0, cssVar: '--nThree' },
    { min: 0, max: 2.9, cssVar: '--zero' },
    { min: 3, max: 5.9, cssVar: '--three' },
    { min: 6, max: 8.9, cssVar: '--six' },
    { min: 9, max: 11.9, cssVar: '--nine' },
    { min: 12, max: 14.9, cssVar: '--twelve' },
    { min: 15, max: 17.9, cssVar: '--fifteen' },
    { min: 18, max: 20.9, cssVar: '--eighteen' },
    { min: 21, max: 23.9, cssVar: '--twentyOne' },
    { min: 24, max: 26.9, cssVar: '--twentyFour' }
];

let monthData: dataPoint[] = [];
let dayIndex: number = 0;

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
    (document.getElementById("outCurrentDate") as HTMLLabelElement).innerText = monthData[dayIndex].date;
    changeOutputColor();
}

function changeOutputColor() {
    const color: string = `var(${backgroundColorFromTemperature()})`;
    (document.getElementById("outDayColor") as HTMLDivElement).style.backgroundColor = color;
    (document.getElementById("outDayColor") as HTMLDivElement).style.boxShadow = `0 0 10px 5px ${color}`;
}

function backgroundColorFromTemperature(): string {
    const temp: number = parseFloat(monthData[dayIndex].value);
    const colorEntry = temperatureColors.find(entry => temp >= entry.min && temp <= entry.max);

    return colorEntry ? colorEntry.cssVar : '--transparent';
}