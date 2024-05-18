function startup() {
    displayCurrentUserDisplayName().then(() => {
    });
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
