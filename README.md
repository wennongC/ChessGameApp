# ChessGameApp (using Swift 4 as the client-side and NodeJS as the server-side)
(Legacy Project) An IOS application that can play chess. Chess board rendering and game rules restriction is self-implemented. Legacy code, server stops maintaining.

<hr />

## nodeServer folder

Served as the server-side for online chess playing. Using socketIO library to establish the connection between 2 players. and transfer the information received from one player to another.

## swiftClient folder

Stored the IOS application code. The source code are inside ./swiftClient/assignment
The "Game board" folder contains the rendering logic for chess board and its figures.
The game rules restriction, The functions during the game (e.g. moving figure, take a step back) are implemented inside the file "MainGameViewController.swift"
