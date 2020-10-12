const {Game} = require('./Game');
const {UserList} = require('./UserList');

var userList = new UserList();
var game = new Game();

userList.addUser("00001", "m@m.com", "admin", 20);
userList.addUser("00002", "a@a.com", "alice", 31);
userList.addUser("00003", "b@b.com", "bill", 42);
userList.addUser("00004", "c@c.com", "cathy", 16);

if(userList.users.length == 4) {console.log(">>> addUser function success");} else {console.log("! addUser function FAIL!");}

userList.addUser("00001", "m@m.com", "admin", 20);
if(userList.users.length == 4) {console.log(">>> prevent email duplication success");} else {console.log("! prevent email duplication FAIL!");}

let ut1 = userList.getUserById("00001");
if(ut1.username === "admin") {console.log(">>> getUserById function success");} else {console.log("! getUserById function FAIL!");}

let ut2 = userList.getUserByEmail("c@c.com");
if(ut2.username === "cathy") {console.log(">>> getUserByEmail function success");} else {console.log("! getUserByEmail function FAIL!");}

userList.removeUserById("00004");
let ut3 = userList.getUserByEmail("c@c.com");
if(!ut3) {console.log(">>> removeUserById function success");} else {console.log("! removeUserById function FAIL!");}
userList.addUser("00004", "c@c.com", "cathy", 16);

game.makePair(userList.getUserById("00001"), userList.getUserById("00002"));
game.makePair(userList.getUserById("00003"), userList.getUserById("00004"));
let ut4 = game.findPairUser("00001");
if(ut4.username === "alice") {console.log(">>> makePair function success");} else {console.log("! makePair function FAIL!");}

ut4 = game.findPair("0");
if(ut4 == false) {console.log(">>> findPair function success");} else {console.log("! findPair function FAIL!");}

game.deletePair("00004");
if(game.pairs.length === 1) {console.log(">>> deletePair function success");} else {console.log("! deletePair function FAIL!");}

game.makePair(userList.getUserById("00002"), userList.getUserById("00004"));
game.makePair(userList.getUserById("00003"), userList.getUserById("00001"));
if(game.pairs.length === 1) {console.log(">>> prevent duplication function success");} else {console.log("! prevent duplication function FAIL!");}
