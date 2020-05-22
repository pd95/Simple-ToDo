"use strict";

var user = {}

function updateUI(records, parentID) {
    console.log(parentID, records)

    // Get parent element and clear existing children
    let parentElement = document.querySelector(parentID)
    if (parentElement == undefined) {
        console.warn(`updateUI: ${parentID} does not exist`)
        return
    }
    if (parentElement.childElementCount > 0) {
        parentElement.textContent = ""
    }

    // Sort according to modification timestamp
    records.sort((a,b) => { return b.modified.timestamp - a.modified.timestamp })

    records.forEach(record => {
        // Extract relevant field data
        let title = record.fields.CD_title.value
        let details = record.fields.CD_details.value
        let done = record.fields.CD_done.value != 0
        let createDate = record.fields.CD_createDate.value

        // Build list item and append it to parent
        let li = document.createElement("li")
        let text = `${title}: ${details}`
        let className = undefined
        if (record.created.userRecordName === user.userRecordName) {
            className = "ownRecord"
        }
        li.textContent = text
        if (className) {
            li.className = className
        }
        parentElement.appendChild(li)
    });
}

function fetchRecords(database, targetList) {
    var query = { recordType: "CD_TodoItem" };

    // Set the options.
    var options = {
        // Restrict our returned fields to this array of keys.
        desiredKeys: ["CD_title", "CD_details", "CD_done", "CD_createDate"],

        // Fetch 5 results at a time.
        resultsLimit: 100
    };

    database.performQuery(query, options).then(function (response) {
        if (response.hasErrors) {
            // Insert error handling
            throw response.errors[0];
        } else {
            // Insert successfully fetched record
            updateUI(response.records, targetList)
        }
    });
}

function setUpAuth() {

    // Get the container.
    var container = CloudKit.getDefaultContainer();

    function gotoAuthenticatedState(userIdentity) {
        console.log("userIdentity", userIdentity)

        fetchRecords(container.publicCloudDatabase, 'div#records-public ul')
        fetchRecords(container.privateCloudDatabase, 'div#records-private ul')

        document.querySelector('div#records-private').style.display = ""
        container
            .whenUserSignsOut()
            .then(gotoUnauthenticatedState);
    }

    function gotoUnauthenticatedState(error) {

        if (error && error.ckErrorCode === 'AUTH_PERSIST_ERROR') {
            console.log('AUTH_PERSIST_ERROR', error);
        }

        fetchRecords(container.publicCloudDatabase, 'div#records-public ul')
        updateUI([], 'div#records-private ul')

        document.querySelector('div#records-private').style.display = "none"
        console.log('Unauthenticated User');
        container
            .whenUserSignsIn()
            .then(gotoAuthenticatedState)
            .catch(gotoUnauthenticatedState);
    }

    // Check a user is signed in and render the appropriate button.
    return container.setUpAuth()
        .then(function (userIdentity) {

            // Either a sign-in or a sign-out button was added to the DOM.

            // userIdentity is the signed-in user or null.
            if (userIdentity) {
                user = userIdentity
                gotoAuthenticatedState(userIdentity);
            } else {
                user = {}
                gotoUnauthenticatedState();
            }
        });
}


setUpAuth();
