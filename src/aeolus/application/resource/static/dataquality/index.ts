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
    loadCheckerConfig();
  });
}

function triggerRun() {
  fetch("{{CONTEXT}}/rest/data-quality-checker-config/run", {
    method: "POST",
  }).then((response: Response) => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status} ${response.statusText}`);
    }
    loadCheckerConfig();
  });
}
