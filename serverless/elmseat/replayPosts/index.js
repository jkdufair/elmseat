module.exports = function (context, req) {
    context.res = { body: context.bindings.allPosts.map(p => ({
        message: p.data.message,
        voteCount: Math.floor(Math.random() * 4),
        isStarred: Math.floor(Math.random() * 2) === 0 ? true : false,
        _ts: p._ts,
        replies: []
    })) };
    context.res.headers = {
        'Access-Control-Allow-Origin': 'http://localhost:3001',
        'Access-Control-Allow-Headers': 'Content-Type'
    };
    context.done();
};