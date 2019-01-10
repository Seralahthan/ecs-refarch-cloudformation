import ballerina/http;
import ballerina/log;
import ballerinax/docker;
import ballerina/config;
import ballerina/io;
import ballerina/mysql;

public boolean configLoaded = false;

mysql:Client testDB = new({
    host: config:getAsString("DBEndpointURL", default = "default"),
    port: 3306,
    name: "testDB",
    username: "testballerina",
    password: "testballerina",
    poolOptions: { maximumPoolSize: 8 },
    dbOptions: { useSSL: false }
});

@docker:Expose{}
listener http:Listener utilityEP = new (8280);

@http:ServiceConfig {
    basePath: "/utility"
}

@docker:Config {
    registry:"765515728978.dkr.ecr.us-west-2.amazonaws.com",
    name:"ecr",
    tag:"v1.0"
}

@docker:CopyFiles {
    files: [{ source: "/tmp/mysql-connector-java-8.0.13/mysql-connector-java-8.0.13.jar", target: "/ballerina/runtime/bre/lib" }]
}

service Utility on new http:Listener(8280) {
     @http:ResourceConfig {
        methods:["GET"],
        path: "/{studentName}"  
    }

    resource function sayHello(http:Caller caller, http:Request req, string studentName) {
        http:Response res = new;
        if(studentName == "loadtest"){
            res.setTextPayload("Load Test Success", contentType = "text/plain");
        } else {
            createTable();
            insertIntoTable();

            io:println("\nThe select operation - Select data from a table");
            var selectRet = testDB->select("SELECT * FROM student WHERE name=" + "'" + untaint studentName + "'", ());

            io:println(selectRet);

            if (selectRet is table<record {}>) {
                io:println("\nConvert the table into json");
                var jsonConversionRet = json.convert(selectRet);
                if (jsonConversionRet is json) {
                    res.setJsonPayload(untaint jsonConversionRet, contentType = "application/json");
                } else {
                    io:println("Error in table to json conversion");
                }
            } else {
                io:println("Select data from student table failed");
            }
        }

        var result = caller -> respond(res);
        if(result is error) {
            log:printError("Error sending response", err = result);
        }

    }


}

function createTable() {
    io:println("The update operation - Creating a table:");
    var ret = testDB->update("CREATE TABLE IF NOT EXISTS student(id INT AUTO_INCREMENT,
                          age INT, name VARCHAR(255), PRIMARY KEY (id))");
    handleUpdate(ret, "Create student table");
}

function insertIntoTable() {
    io:println("\nThe update operation - Inserting data to a table");
    var ret = testDB->update("INSERT INTO student(age, name)
                          values (23, 'john')");
    handleUpdate(ret, "Insert to student table with no parameters");
}

function handleUpdate(int|error returned, string message) {
    if (returned is int) {
        io:println(message + " status: " + returned);
    } else {
        io:println(message + " failed: " + <string>returned.detail().message);
    }
}