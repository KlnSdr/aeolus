interface dataPoint {
    date: string,
    value: string
}

const darkredRGB = 'rgb(139, 0, 0)';
const darkblueRGB = 'rgb(0, 0, 139)';
const darkgreenRGB = 'rgb(0, 139, 0)';

let currentChart: {[key: string]: Object} = {};

function preprocessData(data: {date: string, value: number}[]): dataPoint[] {
    return data.map(day => {
        return {
            date: day.date, value: day.value.toFixed(2),
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

function prependZero(val: number) {
    return val > 9 ? val.toString() : "0" + val;
}

function displayChart(data: dataPoint[], type: string, borderColor: string | string[], backgroundColor: string | string[] | undefined, canvasId: string = 'myChart') {
    const ctx = document.getElementById(canvasId) as HTMLCanvasElement;
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
            borderColor: borderColor,
            backgroundColor: backgroundColor,
            tension: 0.1
        }]
    };
    const config = {
        type: type,
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

    if (currentChart[canvasId] !== undefined) {
        // @ts-ignore
        currentChart[canvasId].destroy();
    }

    // @ts-ignore
    currentChart[canvasId] = new Chart(context, config);
}