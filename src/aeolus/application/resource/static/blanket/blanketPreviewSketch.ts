// NOTE keep in sync with blanket/style.css
const temperatureColorsP5 = [
    { min: -Infinity, max: -6, color: '#3c224a' },
    { min: -5.9, max: -3, color: '#232040' },
    { min: -2.9, max: 0, color: '#84d0d9' },
    { min: 0, max: 2.9, color: '#3bebd3' },
    { min: 3, max: 5.9, color: '#184a5c' },
    { min: 6, max: 8.9, color: '#00300f' },
    { min: 9, max: 11.9, color: '#134f07' },
    { min: 12, max: 14.9, color: '#769400' },
    { min: 15, max: 17.9, color: '#fc9292' },
    { min: 18, max: 20.9, color: '#ab5824' },
    { min: 21, max: 23.9, color: '#a82c07' },
    { min: 24, max: Infinity, color: '#571000' }
];

let yearData: dataPoint[] = [];
let p5DidError: boolean = false;

async function loadYearData(year: number): Promise<dataPoint[]> {
    const res = await fetch(`{{CONTEXT}}/rest/readings/${year}`, {});
    if (!res.ok) {
        throw new Error();
    }
    const data = await res.json();
    return preprocessData(data["readings"]);
}

const sketch = function(p: any) {
    p.setup = function() {
        let canvas = p.createCanvas(400, 400);
        canvas.parent('blanketOutput');
        p.background(255);

        loadYearData(2024).then(data => {
            yearData = data;
        })
        .catch(() => {
            yearData = [];
        });
    };

    p.draw = function() {
        p.background(255);
        if (p5DidError) {
            p.fill(0);
            p.textSize(20);
            p.text("An error occurred", 100, 200);
            return;
        }
        if (yearData.length === 0) {
            p.fill(0);
            p.textSize(20);
            p.text("Waiting for data", 100, 200);
            return;
        }

        const barWidth = p.width / yearData.length;
        p.noStroke();

        yearData.forEach((dataPoint, index) => {
            const temp: number = parseFloat(dataPoint.value);
            const colorEntry = temperatureColorsP5.find(entry => temp >= entry.min && temp <= entry.max);
            p.fill(colorEntry ? colorEntry.color : 0);
            p.rect(index * barWidth, 0, barWidth, p.height);
        });
        p.noLoop();
    };
};