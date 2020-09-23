var chakram = require('chakram');
expect = chakram.expect;

describe("Testing authenticated calls", function() {
    var apiResponse;


    before(function () {
        // This endpoint just returns what we send it,
        // we'll pretend we're getting back an access token (environment var PASSWORD should be set to "foobar")
        return chakram.post("https://httpbin.org/anything", {
            token: process.env.PASSWORD
        }).then((response) => {
            accessToken = JSON.parse(response.body.data).token;
            return accessToken;
        });
    })

    before(function () {
        // We can use this token to make a call to anuthenticated endpoint.
        // this fails if the token is empty
        apiResponse = chakram.get("https://httpbin.org/bearer", {
            'auth': {
                'bearer': accessToken
            }
        })
        return apiResponse;
    });

    it("should return 200 on success", function () {
        return expect(apiResponse).to.have.status(200);
    });

    it("should return return in < 1 second", function () {
        return expect(apiResponse).to.have.responsetime(1000);
    });

    it("should have correctly authenticated", function () {
        return expect(apiResponse).to.have.json('authenticated', true);
    });

    it("should have returned the token used", function () {
        return expect(apiResponse).to.have.json('token', 'foobar');
    });

});

