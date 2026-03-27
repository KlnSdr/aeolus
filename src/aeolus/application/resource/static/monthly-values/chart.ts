function getChartForYear(yearData: MonthlyValues[]): HTMLElement {
    const canvas: HTMLCanvasElement = document.createElement("canvas");
    const context = canvas.getContext('2d');

    if (!context) {
        alert("Ein Fehler beim Darstellen des Diagramms ist aufgetreten");
        const errorMessage = document.createElement("p");
        errorMessage.textContent = "Ein Fehler beim Darstellen des Diagramms ist aufgetreten";
        return errorMessage;
    }
    const chartData = {
        labels: yearData.map(month => month.date),
        datasets: [
            {
                label: 'Hochtarifstrom',
                data: yearData.map(month => month.highTariffPower),
                fill: true,
                borderColor: "#0000ff",
                backgroundColor: "transparent",
                tension: 0.1,
                type: "line"
            },
            {
                label: 'Niedrigtarifstrom',
                data: yearData.map(month => month.lowTariffPower),
                fill: true,
                borderColor: "#00ccff",
                backgroundColor: "transparent",
                tension: 0.1,
                type: "line"
            },
            {
                label: 'Hausstrom',
                data: yearData.map(month => month.householdPower),
                fill: true,
                borderColor: "#ff6600",
                backgroundColor: "transparent",
                tension: 0.1,
                type: "line"
            },
            {
                label: 'Betriebsstunden Heizung',
                data: yearData.map(month => month.operatingHoursHeating),
                fill: true,
                borderColor: "#666699",
                backgroundColor: "#666699",
                tension: 0.1
            },
            {
                label: 'Betriebsstunden Wasser',
                data: yearData.map(month => month.operatingHoursWater),
                fill: true,
                borderColor: "#668399",
                backgroundColor: "#668399",
                tension: 0.1
            }
        ]
    };
    const config = {
        type: "bar", data: chartData, options: {
            responsive: true, maintainAspectRatio: false, scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                    },
                    stacked: true
                }],
                xAxes: [{
                    stacked: true
                }]
            }
        }
    };

    // @ts-ignore
    new Chart(context, config);
    return canvas;
}

function getChartForYears(yearData: {[key: string]: MonthlyValues[]}): HTMLElement {
    const canvas: HTMLCanvasElement = document.createElement("canvas");
    const context = canvas.getContext('2d');

    if (!context) {
        alert("Ein Fehler beim Darstellen des Diagramms ist aufgetreten");
        const errorMessage = document.createElement("p");
        errorMessage.textContent = "Ein Fehler beim Darstellen des Diagramms ist aufgetreten";
        return errorMessage;
    }
    const keys: string[] = Object.keys(yearData).sort();

    const chartData = {
        labels: keys,
        datasets: [
            {
                label: 'Hochtarifstrom',
                data: keys.map(key => yearData[key].map(month => month.highTariffPower).reduce((a, b) => a + b, 0)),
                fill: true,
                borderColor: "#0000ff",
                backgroundColor: "transparent",
                tension: 0.1,
                type: "line"
            },
            {
                label: 'Niedrigtarifstrom',
                data: keys.map(key => yearData[key].map(month => month.lowTariffPower).reduce((a, b) => a + b, 0)),
                fill: true,
                borderColor: "#00ccff",
                backgroundColor: "transparent",
                tension: 0.1,
                type: "line"
            },
            {
                label: 'Hausstrom',
                data: keys.map(key => yearData[key].map(month => month.householdPower).reduce((a, b) => a + b, 0)),
                fill: true,
                borderColor: "#ff6600",
                backgroundColor: "transparent",
                tension: 0.1,
                type: "line"
            },
            {
                label: 'Betriebsstunden Heizung',
                data: keys.map(key => yearData[key].map(month => month.operatingHoursHeating).reduce((a, b) => a + b, 0)),
                fill: true,
                borderColor: "#666699",
                backgroundColor: "#666699",
                tension: 0.1
            },
            {
                label: 'Betriebsstunden Wasser',
                data: keys.map(key => yearData[key].map(month => month.operatingHoursWater).reduce((a, b) => a + b, 0)),
                fill: true,
                borderColor: "#668399",
                backgroundColor: "#668399",
                tension: 0.1
            }
        ]
    };
    const config = {
        type: "bar", data: chartData, options: {
            responsive: true, maintainAspectRatio: false, scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                    },
                    stacked: true
                }],
                xAxes: [{
                    stacked: true
                }]
            }
        }
    };

    // @ts-ignore
    new Chart(context, config);
    return canvas;
}
