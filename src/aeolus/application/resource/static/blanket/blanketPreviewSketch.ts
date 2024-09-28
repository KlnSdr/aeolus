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

        yearData.forEach((dataPoint, index) => {
            console.log(dataPoint);
        });
    };
};