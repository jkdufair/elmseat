module.exports = async function (context, documents) {
    if (!!documents && documents.length > 0) {
        context.bindings.signalREvents = documents.map(d => ({
            "target": "eventCreated",
            "arguments": [d]
        }));
        context.done();
    }
}
