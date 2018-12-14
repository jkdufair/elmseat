module.exports = function (context, req, connectionInfo) {
    context.res = { body: connectionInfo };
    context.res.headers = {
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Origin': 'http://localhost:3001',
        'Access-Control-Allow-Headers': 'X-Requested-With'
    };
    context.done();
};
