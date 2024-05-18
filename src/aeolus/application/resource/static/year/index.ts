interface dataPoint {
    date: string,
    value: string
}

let currentChart: Object | null = null;

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

function prependZero(val: number) {
    return val > 9 ? val.toString() : "0" + val;
}

function loadNewData() {
    const year = (document.getElementById("selectYear") as HTMLSelectElement).value;

    fetch(`{{CONTEXT}}/rest/readings/${year}`, {}).then(res => {
        if (!res.ok) {
            throw new Error();
        }

        return res.json();
    }).then(data => {
        const processedData = preprocessData(data["readings"]);
        displayChart(processedData);
    }).catch(_ => {
        alert("Ein Fehler ist beim Laden der Daten aufgetreten");
    });
}

function preprocessData(data: dataPoint[]) {
    return data.map(day => {
        return {
            date: day.date,
            value: parseFloat(day.value).toFixed(1),
        };
    }).sort(compareIsoDate);
}

function compareIsoDate(a: dataPoint , b: dataPoint): number {
    const splitA = a.date.split("-");
    const splitANum = splitA.map(part => parseInt(part, 10));
    const splitB = b.date.split("-");
    const splitBNum = splitB.map(part => parseInt(part, 10));

    if (splitANum[0] > splitBNum[0]) {
        return 1;
    } else if (splitANum[0] < splitBNum[1]) {
        return -1;
    } else if (splitANum[1] > splitBNum[1]) {
        return 1;
    } else if (splitANum[1] < splitBNum[1]) {
        return -1;
    } else if (splitANum[2] > splitBNum[2]) {
        return 1;
    } else if (splitANum[2] < splitBNum[2]) {
        return -1;
    }
    return 0;
}

function displayChart(data: dataPoint[]) {
    const ctx = document.getElementById('myChart') as HTMLCanvasElement;
    const context = ctx.getContext('2d');

    if (!context) {
        alert("Ein Fehler beim Darstellen des Diagramms ist aufgetreten");
        return;
    }
    const chartData = {
        labels: data.map(day => day.date),
        datasets: [{
            label: 'Temperaturen',
            data: data.map(day => parseFloat(day.value)),
            fill: true,
            borderColor: 'rgb(139, 0, 0)',
            tension: 0.1
        }]
    };
    const config = {
        type: 'line',
        data: chartData,
        options: {
            scales: {
                x: {
                    beginAtZero: true
                },
                y: {
                    beginAtZero: true
                }
            }
        }
    };

    if (currentChart) {
        // @ts-ignore
        currentChart.destroy();
    }

    // @ts-ignore
    currentChart = new Chart(context, config);
}