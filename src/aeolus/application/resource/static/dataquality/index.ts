interface CheckerConfig {
  userId: string;
  enabled: boolean;
  startHour: number;
  startMinute: number;
  lastRunDay: number;
  lastRunMonth: number;
  lastRunYear: number;
  lastRunHour: number;
  lastRunMinute: number;
  lastRunStatus: string;
}

function loadCheckerConfig() {
  fetch("{{CONTEXT}}/rest/data-quality-checker-config")
    .then((response: Response) => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status} ${response.statusText}`);
      }
      return response.json();
    })
    .then((data: CheckerConfig) => {
      (
        document.getElementById("runStatus") as HTMLSpanElement
      ).className = `statusSpan ${runStatusToCss(data.lastRunStatus)}`;
      (document.getElementById("checkerStatus") as HTMLLabelElement).innerText =
        data.enabled ? "aktiv" : "inaktiv";
      (document.getElementById("actionToggle") as HTMLButtonElement).innerText =
        data.enabled ? "deaktivieren" : "aktivieren";
      (document.getElementById("actionToggle") as HTMLButtonElement).onclick =
        data.enabled ? () => deactivateChecker() : () => activateChecker();
      (
        document.getElementById("lastCheck") as HTMLLabelElement
      ).innerText = `${data.lastRunDay}.${data.lastRunMonth}.${data.lastRunYear} ${data.lastRunHour}:${data.lastRunMinute}`;
      (document.getElementById("inTime") as HTMLInputElement).value = `${
        (data.startHour < 10 ? "0" : "") + data.startHour
      }:${(data.startMinute < 10 ? "0" : "") + data.startMinute}`;
    })
    .catch((e) => {
      console.error(e);
    });
}

function runStatusToCss(status: string): string {
  switch (status) {
    case "OK":
      return "statusGreen";
    case "WARNING":
      return "statusYellow";
    case "ERROR":
      return "statusRed";
    default:
      return "statusGrey";
  }
}

function activateChecker() {
  fetch("{{CONTEXT}}/rest/data-quality-checker-config/enable", {
    method: "POST",
  }).then((response: Response) => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status} ${response.statusText}`);
    }
    loadCheckerConfig();
  });
}

function deactivateChecker() {
  fetch("{{CONTEXT}}/rest/data-quality-checker-config/disable", {
    method: "POST",
  }).then((response: Response) => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status} ${response.statusText}`);
    }
    loadCheckerConfig();
  });
}

function saveStartTime() {
  (document.getElementById("bttnSaveStart") as HTMLButtonElement).innerText =
    "...";
  const time: string = (document.getElementById("inTime") as HTMLInputElement)
    .value;
  fetch("{{CONTEXT}}/rest/data-quality-checker-config/start-time", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      hour: parseInt(time.split(":")[0]),
      minute: parseInt(time.split(":")[1]),
    }),
  }).then((response: Response) => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status} ${response.statusText}`);
    }
    (document.getElementById("bttnSaveStart") as HTMLButtonElement).innerText =
      "speichern";
    loadCheckerConfig();
  });
}

function triggerRun() {
  (document.getElementById("bttnTrigger") as HTMLButtonElement).innerText =
    "...";
  fetch("{{CONTEXT}}/rest/data-quality-checker-config/run", {
    method: "POST",
  }).then((response: Response) => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status} ${response.statusText}`);
    }
    (document.getElementById("bttnTrigger") as HTMLButtonElement).innerText =
      "manuellPrüfen";
    loadCheckerConfig();
  });
}

interface Reading {
    date: string,
    value: number
}
interface InterpolationResult {
    interpolatedReadings: Reading[];
    notInterpolatedHoles: string[];
}

function requestInterpolation() {
    (document.getElementById("bttnInterpolate") as HTMLButtonElement).innerText = "...";
    fetch("{{CONTEXT}}/rest/interpolation")
        .then((response: Response) => {
            if (!response.ok) {
                throw new Error(`HTTP ${response.status} ${response.statusText}`);
            }
            (document.getElementById("bttnInterpolate") as HTMLButtonElement).innerText = "Daten interpolieren";
            return response.json();
        })
        .then((data: InterpolationResult) => {
            const uiElement = buildInterpolationUI(data);
            openPopup(uiElement);
        })
        .catch((e) => {
            console.error(e);
        });
}

function buildInterpolationUI(interpolationData: InterpolationResult): HTMLElement {
    const container = document.createElement("div");
    container.classList.add("interpolation-container");
    const title = document.createElement("h3");
    title.innerText = "Interpolierte Daten";
    container.appendChild(title);

    const data: {[key: string]: number} = {};

    for (const reading of interpolationData.interpolatedReadings) {
        const readingDiv = document.createElement("div");
        readingDiv.classList.add("interpolated-reading");
        container.appendChild(readingDiv);

        const dateSpan = document.createElement("span");
        dateSpan.classList.add("reading-date");
        dateSpan.innerText = `${reading.date}`;
        readingDiv.appendChild(dateSpan);

        const valueInput = document.createElement("input");
        valueInput.type = "number";
        valueInput.classList.add("reading-value");
        valueInput.value = reading.value.toFixed(1);
        valueInput.oninput = () => {
            data[reading.date] = parseFloat(valueInput.value);
        }
        readingDiv.appendChild(valueInput);

        data[reading.date] = parseFloat(reading.value.toFixed(1));
    }

    const button = document.createElement("button");
    button.innerText = "speichern";
    button.onclick = () => {
        button.innerText = "...";
        button.disabled = true;
        uploadInterpolationData(data, button);
    };
    container.appendChild(button);

    const titleNotInterpolated = document.createElement("h3");
    titleNotInterpolated.innerText = "Nicht-Interpolierte Daten";
    container.appendChild(titleNotInterpolated);

    for (const hole of interpolationData.notInterpolatedHoles) {
        const holeDiv = document.createElement("div");
        holeDiv.classList.add("not-interpolated-hole");
        holeDiv.innerText = hole;
        container.appendChild(holeDiv);
    }
    return container;
}

function uploadInterpolationData(data: {[key: string]: number}, sender: HTMLElement) {
    fetch("{{CONTEXT}}/rest/readings/batch", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            readings: Object.keys(data).map(date => {
                return {
                    date: date,
                    value: data[date]
                }
            })
        })
    }).then((response: Response) => {
        closePopup(sender);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status} ${response.statusText}`);
        }
        showMessage("Daten erfolgreich gespeichert.");
    })
    .catch((e) => {
        console.error(e);
        showMessage("Fehler beim Speichern der Daten: " + e.message);
    });
}

function showMessage(message: string) {
    const messageDiv = document.createElement("div");
    messageDiv.classList.add("message-popup");
    messageDiv.innerText = message;
    openPopup(messageDiv);
    setTimeout(() => {
        closePopup(messageDiv);
    }, 3000);
}