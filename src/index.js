import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';
import * as signalR from './signalr'

const app = Elm.Main.init({
	node: document.getElementById('root')
});

function bindConnectionMessage(connection) {
	var messageCallback = function (name, message) {
		if (!message) return;
		// deal with the message
		alert("message received:" + message);
	};
	// Create a function that the hub can call to broadcast messages.
	connection.on('broadcastMessage', messageCallback);
	connection.on('echo', messageCallback);
}

function onConnected() { }

var connection = new signalR.HubConnectionBuilder()
	.withUrl('https://elmseat.azurewebsites.net/api')
	.build();

bindConnectionMessage(connection);
connection.start()
	.then(function () {
		onConnected(connection);
	})
	.catch(function (error) {
		console.error(error.message);
	});

connection.on('postChange', postChange)

function postChange(message) {
	app &&
		app.ports &&
		app.ports.receivePost &&
		app.ports.receivePost.send(message);
}

registerServiceWorker();
