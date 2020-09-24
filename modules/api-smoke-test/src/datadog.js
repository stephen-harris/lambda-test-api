const request = require('request')

module.exports.reportToDatadog = async (stats) => 
{

    if (!process.env.SSM_DD_CLIENT_API_KEY) {
        console.log('No datadog client key found, skipping report to datadog');
        return;
    }

    await request.post({
        uri: `https://api.datadoghq.com/api/v1/series?api_key=${process.env.SSM_DD_CLIENT_API_KEY}`,
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            "series": [
              {
                "metric": `lambda-smoke-test.${process.env.SERVICE}.success`,
                "points": [
                  [
                    "" + Math.round(new Date().getTime()/1000),
                    "" + stats.passes
                  ]
                ],
                "tags": process.env.DD_TAGS ? process.env.DD_TAGS.split(" ") : []
              },
              {
                "metric": `lambda-smoke-test.${process.env.SERVICE}.fail`,
                "points": [
                  [
                    "" + Math.round(new Date().getTime()/1000),
                    "" + stats.failures
                  ]
                ],
                "tags": process.env.DD_TAGS ? process.env.DD_TAGS.split(" ") : []
              }
            ]
        })
    }, function(err, response) {
      console.log(err);
      console.log(response);
    });
};
