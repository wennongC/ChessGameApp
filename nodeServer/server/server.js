const path = require('path');
const http = require('http');
const express = require('express');
const socketIO = require('socket.io');

const {Game} = require('./utils/Game');
const {UserList} = require('./utils/UserList');
const game = new Game();
const userList = new UserList();
var waitingUser = null;

const publicPath = path.join(__dirname, '../public'); // join function is to omit unneccesery path
const port = process.env.PORT || 8080;
var app = express();
var server = http.createServer(app);
var io = socketIO(server);

app.use(express.static(publicPath));

/* List of event emitted from server:
    emit('loginSuccess')
    emit('makeMove', params)
    emit('makePromotionMove', params)
    emit('message', msg)
    emit('win', displayMessage)
    emit('searchResult', email, username)
    emit('invitation', from)
    emit('invitationRefused', message)
    emit('gameStart', whichSideAreYou)
    emit('ok');
    emit('error');
*/

io.on('connection', socket => {
  console.log(`>>> Receive a new socket: ${socket.id}`);

  // When user connect to this server, it will emit the login event immediately to send server some data
  socket.on('login', (email, username, mark) => {
    console.log('>> Login');
    userList.addUser(socket.id, email, username, mark);
    socket.emit('loginSuccess', '>>>success');
  });

  // When user select the Quick Start mode
  socket.on('quickStart', () => {
    console.log('>> Quick Start');
    const thisUser = userList.getUserById(socket.id);
    if(waitingUser == null) { waitingUser = thisUser; }
    else if(waitingUser) {
      game.makePair(waitingUser, thisUser);
      io.to(waitingUser.id).emit('gameStart', 'first', thisUser.username, thisUser.mark);
      io.to(thisUser.id).emit('gameStart', 'second', waitingUser.username, waitingUser.mark);
      waitingUser = null;
    }
  });

  // user doesn't want to wait anymore
  socket.on('cancelWaiting', () => {
    console.log('>> Cancel Waiting');
    if(waitingUser){
      if(socket.id == waitingUser.id){
        waitingUser = null;
      }
    }
    game.deletePair(socket.id);
  });

  // After two users got paired, check again if two users are still online, in case the bad effect of latency。
  socket.on('gameStartCheck', () => {
    console.log('>> Game Start Check');
    if(game.findPairUser(socket.id)) {
      socket.emit('ok');
    } else {
      socket.emit('error');
    }
  });

  // When user select the Search Specific Player mode
  socket.on('searchPlayer', (email) => {
    console.log('>> Search Player');
    if (email) {
      const targetUser = userList.getUserByEmail(email);
      if(targetUser){
        return socket.emit('searchResult', targetUser.email, targetUser.username);
      }
      return socket.emit('searchResult');
    } else {
      return socket.emit('searchResult');
    }
  });

  socket.on('selectPlayer', email => {
    console.log('>> Select Player');
    const targetUser = userList.getUserByEmail(email);
    if(targetUser) {
      const thisUser = userList.getUserById(socket.id);
      if (targetUser.email === thisUser.email) {
        return socket.emit('invitationRefused', "You can not play with yourself");
      }
      game.makePair(thisUser, targetUser); // Make them a pair first, then wait for the response

      const from = `${thisUser.username} <${thisUser.email}>`;
      io.to(targetUser.id).emit('invitation', from);
    } else {
      socket.emit('invitationRefused', "That user is offline now");
    }
  });

  socket.on('invitationResponse', response => {
    const opponent = game.findPairUser(socket.id);
    if (opponent) {
      // If the opponent user is still waiting for response
      if (response) {
        const thisUser = userList.getUserById(socket.id);
        io.to(opponent.id).emit('gameStart', 'first', thisUser.username, thisUser.mark);
        socket.emit('gameStart', 'second', opponent.username, opponent.mark);
      } else {
        io.to(opponent.id).emit('invitationRefused', "That user refused your invitation");
        game.deletePair(socket.id);
      };
    } else if (response) {
      // If the opponent is already gone, and this user want to accept invitation, we should inform this user
      socket.emit('invitationRefused', "That user is offline now");
    }
    // Otherwise, nothing need to be done.
  });

  // When one user make a new move towards another user
  socket.on('makeMove', (fromHor, fromVer, toHor, toVer) => {
    console.log('>> make move');
    //find if the user are currently in the game
    const pairUser = game.findPairUser(socket.id);
    if(pairUser){
      io.to(pairUser.id).emit('makeMove', fromHor, fromVer, toHor, toVer);
    }
  });

  socket.on('makePromotionMove', (fromHor, fromVer, toHor, toVer, become) => {
    console.log('>> make promotion move');
    //find if the user are currently in the game
    const pairUser = game.findPairUser(socket.id);
    if(pairUser){
      io.to(pairUser.id).emit('makePromotionMove', fromHor, fromVer, toHor, toVer, become);
    }
  });

  socket.on('message', (msg) => {
    console.log('>> message: ', msg);
    const pairUser = game.findPairUser(socket.id);
    if(pairUser){
      io.to(pairUser.id).emit('message', msg);
    }
  });

  // The game is over by someone winning or both drawing (The winning side is dicided by client IOS program)
  socket.on('gameOver', () => {
    console.log(">>> Game Over");
    game.deletePair(socket.id);
  });

  // When user quit the game or surrender
  socket.on('exitGame', () => {
    console.log(">>> Exit Game");
    //find if the user are currently in the game
    const pairUser = game.findPairUser(socket.id);
    if(pairUser){
      io.to(pairUser.id).emit('win', 'You opposite surrenderred!');
      game.deletePair(socket.id);
    }
  });

  // When user get offline (by closing the app or lose internet)
  socket.on('disconnect', () => {
    console.log(">>> A socket left");
    //find if the user are currently in the game
    const pairUser = game.findPairUser(socket.id);
    if(pairUser){
      io.to(pairUser.id).emit('win', 'You opposite left the game!');
      game.deletePair(socket.id);
    }
    // check if this user is waiting for quickStart
    if(waitingUser){
      if(waitingUser.id == socket.id) { waitingUser = null; }
    }
    // remove users from the list
    userList.removeUserById(socket.id);
  });
});

server.listen(port, () => {
  console.log(`Started on the port ${port}`);
});
