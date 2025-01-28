import ballerina/http;
import ballerina/log;

type CentralAPIConfig record {|
    string url;
|};

configurable CentralAPIConfig centralConf = ?;

final http:Client centralApiClient = check new (centralConf.url, secureSocket = {enable: false});

service /repository/ballerina\-central on new http:Listener(9090) {

    isolated resource function get [string org]/[string package]/[string ver]/[string balafile]() returns http:Response|http:InternalServerError {
        do {
            log:printInfo(string `Requesting the package org:${org} package:${package} version:${ver}`);
            http:Response centralResponse = check centralApiClient->/packages/[org]/[package]/[ver]({
                "Accept-Encoding": "identity",
                "Accept": "application/octet-stream"
            });
            if centralResponse.statusCode != 302 {
                check error(string `Unexpected response encountered. Statuscode : ${centralResponse.statusCode}`);
            }
            string filePath = check centralResponse.getHeader("Location");
            http:Client fileServer = check new (filePath);
            http:Response downloadResponse = check fileServer->get("");
            return downloadResponse;
        } on fail error err {
            log:printError(string `Error occured while pulling the package org:${org} package:${package} version:${ver} reason:${err.message()}`);
            return {body: string `Error occured while pulling the package org:${org} package:${package} version:${ver}`};
        }
    }

    resource function head [string... path]() returns json {
        return {};
    }
}
