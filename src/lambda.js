const Mocha = require('mocha');
const glob = require('glob')
const path = require('path')
const dd = require('./datadog')

module.exports.handler = (event) => 
{
    const mocha = new Mocha();
    const testDir = __dirname + '/spec';
    const testFiles = glob.sync('*.spec.js', {cwd: testDir});

    testFiles.forEach((file) => {
        mocha.addFile(path.join(testDir, file))
    });
    mocha.run().on('end', function(){
        dd.reportToDatadog(this.stats);
    });;

};
