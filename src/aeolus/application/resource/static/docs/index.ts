interface endpointDoc {
    desc: string;
    url: string;
    method: string;
    parameters: Parameter[];
    example: string;
    successResponse: ResponseDoc;
    errorResponse: ResponseDoc[];
}

interface ResponseDoc {
    code: number;
    desc: string;
    body: string;
}

interface Parameter {
    name: string;
    type: string;
    isOptional: boolean;
    desc: string;
}

const endpoints: endpointDoc[] = [
    {
        desc: "Temperaturdaten speichern",
        url: "/rest/readings",
        method: "POST",
        parameters: [
            {
                name: "date",
                type: "string",
                isOptional: false,
                desc: "Das Datum der Messung im Format YYYY-MM-DD"
            },
            {
                name: "value",
                type: "string",
                isOptional: false,
                desc: "Die gemessene Temperatur"
            }
        ],
        example: "POST /rest/readings\nContent-Type: application/json\n\n{\n  \"date\": \"2024-06-01\",\n  \"temperature\": 22.5\n}",
        successResponse: {
            code: 201,
            desc: "CREATED",
            body: ""
        },
        errorResponse: [
            {
                code: 409,
                desc: "CONFLICT",
                body: "{\n  \"msg\": \"Reading for date 2024-06-01 already exists.\"\n}"
            }
        ]
    },
    {
        desc: "Letzten Temperaturwert abrufen",
        url: "/rest/readings/last",
        method: "GET",
        parameters: [],
        example: "GET /rest/readings/last",
        successResponse: {
            code: 200,
            desc: "OK",
            body: "{\n  \"date\": \"2024-06-01\",\n  \"value\": 16.8\n}"
        },
        errorResponse: [{
            code: 404,
            desc: "NOT FOUND",
            body: "{\n  \"message\": \"Could not find the last reading\"\n}"
        }]
    },
    {
        desc: "Daten für ein Jahr abrufen",
        url: "/rest/readings/{year}",
        method: "GET",
        parameters: [{
            name: "year",
            type: "integer",
            isOptional: false,
            desc: "Das Jahr für das alle Werte abgerufen werden sollen"
        }],
        example: "GET /readings/2024",
        successResponse: {
            code: 200,
            desc: "OK",
            body: "{\n  \"readings\": [\n    {\n      \"date\": \"2024-05-31\",\n      \"value\": 14.3\n    },\n    {\n      \"date\": \"2024-06-01\",\n      \"value\": 16.8\n    },\n    ...\n  ]\n}"
        },
        errorResponse: [{
            code: 409,
            desc: "BAD REQUEST",
            body: "{\n  \"msg\": \"Invalid year: notAYear\"\n}"
        }]
    },
    {
        desc: "Daten für einen Monat abrufen",
        url: "/rest/readings/{year}/{month}",
        method: "GET",
        parameters: [{
            name: "year",
            type: "integer",
            isOptional: false,
            desc: "Das Jahr für das alle Werte abgerufen werden sollen"
        }, {
            name: "month",
            type: "integer",
            isOptional: false,
            desc: "Der Monat für den alle Werte abgerufen werden sollen"
        }],
        example: "GET /readings/2024/05",
        successResponse: {
            code: 200,
            desc: "OK",
            body: "{\n  \"readings\": [\n    {\n      \"date\": \"2024-05-31\",\n      \"value\": 14.3\n    },\n    ...\n  ]\n}"
        },
        errorResponse: [{
            code: 409,
            desc: "BAD REQUEST",
            body: "{\n  \"msg\": \"Invalid year or month: notAYear-notAMonth\"\n}"
        }]
    },
    {
        desc: "Daten für eine bestimmtes Datum abrufen",
        url: "/rest/readings/{year}/{month}/{day}",
        method: "GET",
        parameters: [{
            name: "year",
            type: "integer",
            isOptional: false,
            desc: "Das Jahr für das alle Werte abgerufen werden sollen"
        }, {
            name: "month",
            type: "integer",
            isOptional: false,
            desc: "Der Monat für den alle Werte abgerufen werden sollen"
        }, {
            name: "day",
            type: "integer",
            isOptional: false,
            desc: "Der Tag für den der Wert abgerufen werden soll"
        }],
        example: "GET /readings/2024/06/01",
        successResponse: {
            code: 200,
            desc: "OK",
            body: "{\n  \"date\": \"2024-06-01\",\n  \"value\": 16.8\n}"
        },
        errorResponse: [{
            code: 409,
            desc: "BAD REQUEST",
            body: "{\n  \"msg\": \"Invalid year, month or day: notAYear-notAMonth-notADay\"\n}"
        }, {
            code: 404,
            desc: "NOT FOUND",
            body: "{\n  \"msg\": \"No reading found for date: 2024-06-02\"\n}"
        }]
    }
];

function generateDocs() {
    const container: HTMLDivElement = document.getElementById("docOutput") as HTMLDivElement;
    endpoints.forEach(e => container.appendChild(docComponent(e)));
}

function docComponent(doc: endpointDoc): HTMLDivElement {
    const container: HTMLDivElement = document.createElement("div");

    const heading: HTMLHeadingElement = document.createElement("h3");
    heading.innerText = doc.desc;
    container.appendChild(heading);

    const ulInfo: HTMLUListElement = document.createElement("ul");

    [["URL", "url"], ["Methode", "method"]].forEach(key => {
        const li: HTMLLIElement = document.createElement("li");
        // @ts-ignore trust me bro
        li.innerText = key[0] + ": " + (doc[key[1]] as string);
        ulInfo.appendChild(li);
    });

    const liParams: HTMLLIElement = document.createElement("li");
    liParams.innerText = "Parameter:";

    const ulParams: HTMLUListElement = document.createElement("ul");
    doc.parameters.forEach(param => {
        const li: HTMLLIElement = document.createElement("li");
        li.innerText = `${param.name} (${param.type}, ${param.isOptional ? "optional" : "pflicht"}): ${param.desc}`;
        ulParams.appendChild(li);
    });
    liParams.appendChild(ulParams);
    ulInfo.appendChild(liParams);
    container.appendChild(ulInfo);

    const pExample: HTMLParagraphElement = document.createElement("p");
    pExample.innerText = "Beispiel:";
    container.appendChild(pExample);
    container.appendChild(getPre(doc.example));

    const pResponse: HTMLParagraphElement = document.createElement("p");
    pResponse.innerText = "Antwort:";
    container.appendChild(pResponse);
    container.appendChild(getPre(responseToString(doc.successResponse)));

    const pErrorResponse: HTMLParagraphElement = document.createElement("p");
    pErrorResponse.innerText = "Antworten im Fehlerfall:";
    container.appendChild(pErrorResponse);
    doc.errorResponse.forEach((error) => container.appendChild(getPre(responseToString(error))));

    return container;
}

function getPre(content: string): HTMLPreElement {
    const pre: HTMLPreElement = document.createElement("pre");
    const code = document.createElement("code");
    code.innerText = content;
    pre.appendChild(code);
    return pre;
}

function responseToString(res: ResponseDoc): string {
    return `${res.code} ${res.desc}\n${res.body}`;
}