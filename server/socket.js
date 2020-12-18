const dgram = require('dgram');
const server = dgram.createSocket('udp4');
server.bind(3000);
var clients = [];
var playersPosition = [];

server.on('error', (err) => {
	console.log(`server error:\n${err.stack}`);
	server.close();
});

function isItemInArray(array, item) {
	for (var i = 0; i < array.length; i++) {
		if (array[i][0] == item[0] && array[i][1] == item[1]) {
			return i;
		}
	}
	return false;
}

function findFromSerial(array, serial) {
	for (var i = 0; i < array.length; i++) {
		if (array[i][0] == serial) {
			return i;
		}
	}
	return false;
}

server.on('message', (msg, rinfo) => {
	var jsonData = JSON.parse(msg.toString('ascii'));
	if (jsonData[0] == "connect") {
		console.log(`${rinfo.address}:${rinfo.port} has joined the game.`);
		clients.push([rinfo.address,rinfo.port]);
	}
	if (jsonData[0] == "disconnect") {
		var id = isItemInArray(clients, [rinfo.address,rinfo.port]);
		clients.splice(id, 1);
		console.log(`${rinfo.address}:${rinfo.port} has left the game.`);
	}

	if (jsonData[0] == "playersPosition") {
		if ( Number.isInteger(findFromSerial(playersPosition, jsonData[1])) ) {
			playersPosition.splice(findFromSerial(playersPosition, jsonData[1]), 1, [jsonData[1], jsonData[2], jsonData[3], jsonData[4], jsonData[5], jsonData[6]]);
		} else {
			playersPosition.push([jsonData[1], jsonData[2], jsonData[3], jsonData[4], jsonData[5], jsonData[6]]);
		}
	}

});

server.on('listening', () => {
	const address = server.address();
	console.log(`server listening ${address.address}:${address.port}`);
});

const interval = setInterval(function() {
	for(let data of clients) {
		var msgSend = JSON.stringify([ "Reset" ]);
		server.send(msgSend, 0, msgSend.length, data[1], data[0]);
		for(let data2 of clients) {
			var id2 = isItemInArray(clients, [data2[0],data2[1]]);
			if (data[1] != data2[1]) {
				if (playersPosition[id2]) {
					var msgSend = JSON.stringify([ "SetPosition", playersPosition[id2][0], playersPosition[id2][1], playersPosition[id2][2], playersPosition[id2][3], playersPosition[id2][4], playersPosition[id2][5] ]);
					server.send(msgSend, 0, msgSend.length, data[1], data[0]);
				}
			}
		}
	}
 }, 250);