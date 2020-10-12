// [{
//   user1: UserList.getUserById(id),
//   user2: UserList.getUserById(id)
// }]

class Game {
  constructor() {
    this.pairs = [];
  }

    // Make a new pair. Record which two users are playing together
  makePair(user1, user2) {
    if( this.findPair(user1.id) || this.findPair(user2.id) ) return false;
    var pair = {user1, user2};
    this.pairs.push(pair);
  }

    // Delete the pair that contains the given id (either user1 or user2)
  deletePair(uid) {
    this.pairs = this.pairs.filter(p => p.user1.id !== uid && p.user2.id !== uid);
  }

    // find the opposite user based on the given user id (socket id)
  findPairUser(uid) {
    var pair = this.findPair(uid);
    if(pair) {
      return pair.user1.id === uid ? pair.user2 : pair.user1;
    }
    return false;
  }

  findPair(uid) {
    const result = this.pairs.filter(p => p.user1.id === uid || p.user2.id === uid);
    if(result.length == 0) return false;
    else return result[0];
  }
}

module.exports = {Game};
