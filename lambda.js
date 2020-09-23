const Mocha = require('mocha');
const glob = require('glob')
const path = require('path')
const dd = require('./datadog')

module.exports.handler = async (event) => 
{
    const mocha = new Mocha();
    const testDir = './spec';
    const testFiles = glob.sync('*.spec.js', {cwd: testDir});

    testFiles.forEach((file) => mocha.addFile(path.join(testDir, file)));

    mocha.run().on('end', function(){
        console.log(this.stats)
        dd.reportToDatadog(this.stats);
    });;

};
