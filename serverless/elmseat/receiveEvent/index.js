module.exports = function (context, req) {
    context.res = { body: '' };
    context.res.headers = {
        'Access-Control-Allow-Origin': 'http://localhost:3001t',
        'Access-Control-Allow-Headers': 'Content-Type'
    };
    if (req.method === 'POST') {
        context.log(req.body)
        context.bindings.newEvent = JSON.stringify({
            type: req.body.type,
            data: req.body.data,
        });
    }
    context.done();
};