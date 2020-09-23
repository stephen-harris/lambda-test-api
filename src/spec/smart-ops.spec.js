var chakram = require('chakram');
expect = chakram.expect;

describe("Smart ops API", function() {
    var apiResponse;

    before(function () {
        chakram.startDebug()
        apiResponse = chakram.get("https://api.smart-ops-sandbox.ovoenergy.com/v1/health")
        return apiResponse;
    });

    it("should return 200 on success", function () {
        return expect(apiResponse).to.have.status(200);
    });

});



