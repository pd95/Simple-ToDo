"use strict";

CloudKit.configure({
    containers: [{
        containerIdentifier: 'iCloud.com.yourcompany.Cloud-ToDo.todo',  // Use the same container identifier as in the mobile app
        apiTokenAuth: {
            apiToken: 'VALID API TOKEN',  // Generate a valid API token here https://icloud.developer.apple.com/dashboard
            persist: true
        },
        environment: 'development'
    }]
});
