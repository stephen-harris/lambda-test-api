const Mocha = require('mocha');
const glob = require('glob')
const path = require('path')
const dd = require('./datadog')
const loadSecrets = require('./get-ssm')

module.exports.handler = (event) => 
{
    const mocha = new Mocha();
    const testDir = __dirname + '/spec';
    const testFiles = glob.sync('*.spec.js', {cwd: testDir});

    loadSecrets()
        .then(() => {
            testFiles.forEach((file) => {
                mocha.addFile(path.join(testDir, file))
            });

            mocha.run().on('end', function(){
                dd.reportToDatadog(this.stats);
            });;
        })
        .catch((error) => console.log(error))

};
