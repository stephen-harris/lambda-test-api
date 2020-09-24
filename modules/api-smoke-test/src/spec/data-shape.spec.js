var chakram = require('chakram');
expect = chakram.expect;

describe("Testing data shape", function() {
    var apiResponse;

    before(function () {
        apiResponse = chakram.get("http://httpbin.org/uuid")
        return apiResponse;
    });

    it("should return 200 on success", function () {
        return expect(apiResponse).to.have.status(200);
    });

    it("should return a uuid", function () {
        return expect(apiResponse).to.have.json(function(json) {
            return expect(json.uuid).to.match(/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/, "uuid property should look like a uuid")
        });
    });
    
    it("should satisfy the json schema", function () {
        expect(apiResponse).to.have.schema({
            "type": "object",
            properties: {
                uuid: {
                    type: "string"
                }
            }
        });
        return chakram.wait();
    });

    it("should have the content type set", function () {
        expect(apiResponse).to.have.header('content-type', 'application/json');
        return chakram.wait();
    });

});



