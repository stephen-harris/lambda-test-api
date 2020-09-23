const AWS = require('aws-sdk');

const ssm = new AWS.SSM();

const loadSecrets = () =>
  new Promise((resolve, reject) => {

    ssm.getParametersByPath(
      {
        Path: '/smoke-tests',
        Recursive: true,
        WithDecryption: true
      },
      (err, data) => {
        if (err) {
          console.log(err, err.stack);
          reject(err);
        } else {
          data.Parameters.map((param) => {
            var name = "SSM_" + param.Name.split("/").pop().toUpperCase()
            console.log(param);
            console.log("Export " + name + " with value " + param.Value);
            process.env[name] = param.Value;
          });
           
          resolve(true);
        }
      }
    );
  });

module.exports = loadSecrets;