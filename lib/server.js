/*
Copyright (c) 2016, Yahoo Inc.
Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
*/

var express = require('express'),
    bodyParser = require('body-parser'),
    badger = require('badge-up'),
    path = require('path');

function routerApiVOne() {
    var api = express.Router({caseSensitive: true});

    api.get('/status', function (request, response) {
        response.json({
            'status': 'OK'
        });
    });

    api.get('/colors', function (request, response) {
        response.json({
            colors: Object.keys(badger.colors)
        });
    });

    api.get('/:label/:value/:color', function (request, response) {
        var color = badger.colors[request.params.color] || '#000';

        console.log('View Badge: Label=%s Value=%s Color=%s', request.params.label, request.params.value, color);
        badger(request.params.label, request.params.value, color, function (error, data) {
            response.status(200).type('svg').send(data);
        });
    });

    return api;
}

function setup(callback) {
    var app = express(),
        port = 4080,
        server,
        staticAssetsPath = path.join(__dirname, '..', 'public');

    app.use(bodyParser.urlencoded({
        extended: true  // for use with 'qs' library
    }));
    app.use(bodyParser.json());
    app.use('/api/v1', routerApiVOne());
    app.use(express.static(staticAssetsPath));

    server = app.listen(port, function () {
        if (callback) {
            callback(null, server);
        }
    });
}

module.exports = setup;
