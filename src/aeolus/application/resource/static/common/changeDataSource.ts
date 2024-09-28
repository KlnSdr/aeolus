function displayCurrentDatasource() {
    const bttnChangeDataSource: HTMLButtonElement = document.getElementById("bttnDatasource") as HTMLButtonElement;

    const dataSource = localStorage.getItem("aeolus_different_datasource_userName") ?? "default";

    bttnChangeDataSource.textContent = `Datenquelle ändern (${dataSource})`;
}

function changeDataSource() {
    openPopup(buildChangeDataSourceUI());
}

function buildChangeDataSourceUI(): HTMLDivElement {
    const div = document.createElement('div');

    const heading: HTMLHeadingElement = document.createElement('h1');
    heading.textContent = 'Datenquelle ändern';
    div.appendChild(heading);

    const bttnUseOwnData: HTMLButtonElement = document.createElement('button');
    bttnUseOwnData.textContent = 'Eigene Daten verwenden';
    bttnUseOwnData.onclick = () => {
        closePopup(div);
        resetDatasource();
        window.location.reload();
    };
    div.appendChild(bttnUseOwnData);

    div.appendChild(document.createElement('br'));

    const dataSource: HTMLInputElement = document.createElement('input');
    dataSource.type = 'text';
    dataSource.placeholder = 'Datenquelle';
    div.appendChild(dataSource);

    const submit: HTMLButtonElement = document.createElement('button');
    submit.textContent = 'Ändern';
    submit.onclick = () => {
        submit.innerText = 'Lade...';
        checkIfUserExists(dataSource.value)
            .then((exists) => {
                closePopup(div);
                if (!exists) {
                    alertPopup('Datenquelle existiert nicht');
                } else {
                    window.location.reload();
                }
            }).catch((error) => {
            closePopup(div);
            alertPopup('Fehler beim Laden der Datenquelle: ' + error.message);
        });
    };
    div.appendChild(submit);

    return div;
}

function checkIfUserExists(dataSource: string): Promise<boolean> {
    return new Promise((resolve, reject) => {
        fetch(`{{CONTEXT}}/rest/readings/publicdataset/user/${dataSource}`)
            .then((response) => {
                if (response.ok) {
                    return response.json();
                } else {
                    resolve(false);
                }
            })
            .then((json) => {
                const userId: string | undefined = json['id'];
                if (!userId) {
                    throw new Error('Userid not present in response');
                }
                localStorage.setItem("aeolus_different_datasource_userId", userId);
                localStorage.setItem("aeolus_different_datasource_userName", dataSource);
                resolve(true);
            })
            .catch((error) => {
                reject(error);
            });
    });
}

function addParamForDifferentDataSource(): string {
    const userId = localStorage.getItem("aeolus_different_datasource_userId");
    if (userId) {
        return `?dataSource=${userId}`;
    }
    return '';
}

function alertPopup(msg: string) {
    const msgOut: HTMLParagraphElement = document.createElement('p');
    msgOut.innerText = msg;

    openPopup(msgOut);
}

function resetDatasource() {
    localStorage.removeItem("aeolus_different_datasource_userId");
    localStorage.removeItem("aeolus_different_datasource_userName");
}