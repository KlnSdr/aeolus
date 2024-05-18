// @ts-ignore
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

            const diffData: dataPoint[] = calculateDiff(yearAData, yearBData);
            const floatData: number[] = diffData.map(day => parseFloat(day.value))
            displayChart(diffData, "bar", darkredRGB, floatData.map(day => day > 0.0 ? darkredRGB : (day < 0.0 ? darkblueRGB : darkgreenRGB)));
        })
    })
}

function calculateDiff(yearA: any, yearB: any) {
    const getMonthDay = (dateStr: string) => dateStr.slice(5); // Extracts 'MM-DD'

    const monthDaysA = yearA.map((item: dataPoint) => getMonthDay(item.date));
    const monthDaysB = yearB.map((item: dataPoint) => getMonthDay(item.date));

    // Find the common month-day combinations
    const commonMonthDays = monthDaysA.filter((monthDay: dataPoint) => monthDaysB.includes(monthDay));

    // Filter both arrays to include only objects with the common month-day combinations
    const filteredArrayA = yearA.filter((item: dataPoint) => commonMonthDays.includes(getMonthDay(item.date))).sort(compareIsoDate);
    const filteredArrayB = yearB.filter((item: dataPoint) => commonMonthDays.includes(getMonthDay(item.date))).sort(compareIsoDate);

    const diff = [];
    for (let i = 0; i < filteredArrayB.length; i++) {
        diff.push({
            date: filteredArrayB[i].date.slice(5),
            value: (parseFloat(filteredArrayA[i].value) - parseFloat(filteredArrayB[i].value)).toFixed(2),
        });
    }

    return diff;
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