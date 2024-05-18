let currentChart: Object | null = null;

function initCalender() {
    const selectYearA = document.getElementById("selectYearA") as HTMLSelectElement;
    const selectYearB = document.getElementById("selectYearB") as HTMLSelectElement;
    const currentYear = new Date().getFullYear();

    for (let year = currentYear; year > 2000; year--) {
        const optionA = document.createElement("option") as HTMLOptionElement;
        optionA.innerText = year.toString();
        optionA.value = year.toString();

        const optionB = document.createElement("option") as HTMLOptionElement;
        optionB.innerText = year.toString();
        optionB.value = year.toString();

        selectYearA.appendChild(optionA);
        selectYearB.appendChild(optionB);
    }
}

function showCompareYears() {
    const yearA = (document.getElementById("selectYearA") as HTMLSelectElement).value;
    const yearB = (document.getElementById("selectYearB") as HTMLSelectElement).value;

    loadYear(yearA).then(dataA => {
        const yearAData = dataA;
        loadYear(yearB).then(dataB => {
            const yearBData = dataB;
            displayChart(calculateDiff(yearAData, yearBData));
        })
    })
}

function calculateDiff(yearA: any, yearB: any) {
    const getMonthDay = (dateStr) => dateStr.slice(5); // Extracts 'MM-DD'

    const monthDaysA = yearA.map(item => getMonthDay(item.date));
    const monthDaysB = yearB.map(item => getMonthDay(item.date));

    // Find the common month-day combinations
    const commonMonthDays = monthDaysA.filter(monthDay => monthDaysB.includes(monthDay));

    // Filter both arrays to include only objects with the common month-day combinations
    const filteredArrayA = yearA.filter(item => commonMonthDays.includes(getMonthDay(item.date))).sort(compareIsoDate);
    const filteredArrayB = yearB.filter(item => commonMonthDays.includes(getMonthDay(item.date))).sort(compareIsoDate);

    const diff = [];
    for (let i = 0; i < filteredArrayB.length; i++) {
        diff.push({
            date: filteredArrayB[i].date.slice(5),
            value: (parseFloat(filteredArrayA[i].value) - parseFloat(filteredArrayB[i].value)).toFixed(2),
        });
    }

    return diff;
}


function displayChart(data: dataPoint[]) {
    const ctx = document.getElementById('myChart') as HTMLCanvasElement;
    const context = ctx.getContext('2d');

    if (!context) {
        alert("Ein Fehler beim Darstellen des Diagramms ist aufgetreten");
        return;
    }
    const darkredRGB = 'rgb(139, 0, 0)';
    const darkblueRGB = 'rgb(0, 0, 139)';
    const darkgreenRGB = 'rgb(0, 139, 0)';
    const floatData = data.map(day => parseFloat(day.value));
    const chartData = {
        labels: data.map(day => day.date), datasets: [{
            label: 'Temperaturen',
            data: floatData,
            fill: true,
            backgroundColor: floatData.map(day => day > 0.0 ? darkredRGB : (day < 0.0 ? darkblueRGB : darkgreenRGB)),
            tension: 0.1
        }]
    };
    const config = {
        type: 'bar', data: chartData, options: {
            scales: {
                x: {
                    beginAtZero: true
                }, y: {
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

function loadYear(year: string) {
    return new Promise((resolve, reject) => {
        fetch(`{{CONTEXT}}/rest/readings/${year}`, {}).then(res => {
            if (!res.ok) {
                throw new Error();
            }

            return res.json();
        }).then(data => {
            const processedData = preprocessData(data["readings"]);
            resolve(processedData);
        }).catch(_ => {
            alert("Ein Fehler ist beim Laden der Daten aufgetreten");
        });
    });
}

function preprocessData(data: dataPoint[]) {
    return data.map(day => {
        return {
            date: day.date, value: parseFloat(day.value).toFixed(1),
        };
    }).sort(compareIsoDate);
}

function compareIsoDate(a: dataPoint, b: dataPoint): number {
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
