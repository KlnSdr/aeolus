function startup() {
    displayCurrentUserDisplayName().then(() => {});
    loadLastReading();
}

function loadLastReading() {
    const lastValue = document.getElementById("lastValue") as HTMLLabelElement;
    const lastValueFrom = document.getElementById("lastValueFrom") as HTMLLabelElement;

    fetch("{{CONTEXT}}/rest/readings/last", {}).then(res => {
        if (res.ok) {
            return res.json();
        }
        throw new Error("Something went wrong");
    }).then(data => {
        lastValue.innerText = parseFloat(data["value"]).toFixed(1) + " °C";
        lastValueFrom.innerText = `vom: ${isoToDisplayDate(data["date"])}`;
    }).catch(e => {
        lastValue.innerText = e.message;
        lastValueFrom.innerText = "";
    })
}

function isoToDisplayDate(isoDate: string) {
    const splitIso: string[] = isoDate.split("-");
    return splitIso[2] + "." + splitIso[1] + "." + splitIso[0];
}

async function displayCurrentUserDisplayName() {
    fetch("{{CONTEXT}}/rest/users/loginUserInfo", {
        method: "GET", headers: {
            "Content-Type": "application/json",
        }
    }).then((response) => {
        if (response.ok) {
            return response.json();
        } else {
            throw new Error("HTTP error, status = " + response.status);
        }
    }).then((data) => {
        (document.getElementById("lblCurrentUser") as HTMLLabelElement).innerText = `(${data["displayName"]})`;
    }).catch((error) => {
        alert(error.message);
    });
}
