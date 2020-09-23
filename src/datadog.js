const request = require('request')

module.exports.reportToDatadog = async (stats) => 
{

    if (!process.env.DD_CLIENT_API_KEY) {
        console.log('No datadog client key found, skipping report to datadog');
        return;
    }

    await request.post({
        uri: `https://api.datadoghq.eu/api/v1/series?api_key=${process.env.SSM_DD_CLIENT_API_KEY}`,
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            "series": [
              {
                "metric": "testpass",
                "points": [
                  [
                    "" + Math.round(new Date().getTime()/1000),
                    "" + stats.passes
                  ]
                ]
              },
              {
                "metric": "testfail",
                "points": [
                  [
                    "" + Math.round(new Date().getTime()/1000),
                    "" + stats.failures
                  ]
                ]
              }
            ]
        })
    });
};
