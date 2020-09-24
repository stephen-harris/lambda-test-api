const Mocha = require('mocha');
const glob = require('glob')
const path = require('path')
const dd = require('./datadog')
const loadSecrets = require('./get-ssm')

module.exports.handler = (event) => 
{
    const testDir = __dirname + '/spec';
    const testFiles = glob.sync('*.spec.js', {cwd: testDir});

    return loadSecrets()
        .then(() => {
            return new Promise((resolve) => {
                const mocha = new Mocha();
                mocha.cleanReferencesAfterRun(true)

                testFiles.forEach((file) => {
                    mocha.addFile(path.join(testDir, file))
                });

                mocha.run().on('end', async function () {
                    mocha.unloadFiles();
                    await dd.reportToDatadog(this.stats);
                 return resolve(this.testResults);
                });
            });
        })
        .catch((error) => console.log(error))

};
