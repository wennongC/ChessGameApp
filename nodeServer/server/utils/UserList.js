// [{
//   id: 'socket id',
//   email: 'email',
//   username: 'name',
//   mark: 0
// }]

class UserList {
  constructor() {
    this.users = [];
  }

  addUser(id, email, username, mark) {
    let duplication = this.getUserByEmail(email);
    if(!duplication){
      const user = {id, email, username, mark};
      this.users.push(user);
      console.log(this.users);
      return user;
    } else {
      if (duplication.mark !== mark){
        // If the mark has changed, re-create this user
        this.removeUserByEmail(email);
        const user = {id, email, username, mark};
        this.users.push(user);
        return user;
      }
    }
    return false;
  }

  removeUserByEmail(email) {
    var user = this.getUserByEmail(email);
    if(user) {
      this.users = this.users.filter(user => user.email !== email);
    }
    return user;
  }

  removeUserById(id) {
    var user = this.getUserById(id);
    if(user) {
      this.users = this.users.filter(user => user.id !== id);
    }
    return user;
  }

  getUserByEmail(email) {
    return this.users.filter(user => user.email === email)[0];
  }

  getUserById(id) {
    return this.users.filter(user => user.id === id)[0];
  }
}

module.exports = {UserList};
