/*
CS361 OSU Fall 2020
Team: 5++
Members: 
    Phoenix Harris
    Melissa Lagunas
    Alexa Langen
    Ryan McKenzie
    Nishant Tharani
    Ben Wichser
Project Title: Book Swap
*/

/*
Drop prior tables.
*/

DROP TABLE IF EXISTS Books;
DROP TABLE IF EXISTS CopyQualities;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS TradeStatuses;
DROP TABLE IF EXISTS Trades;
DROP TABLE IF EXISTS Wishlists;
DROP TABLE IF EXISTS WishlistsBooks;
DROP TABLE IF EXISTS UserBooks;

/*
Queries that initialize the tables.
*/

-- Books
CREATE TABLE IF NOT EXISTS Books (
    id INTEGER NOT NULL PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    ISBN INTEGER NOT NULL,
    cover BLOB
);
    
-- CopyQualities
CREATE TABLE IF NOT EXISTS CopyQualities(
    id INTEGER NOT NULL PRIMARY KEY,
    qualityDescription VARCHAR(255) NOT NULL
);

-- Users
CREATE TABLE IF NOT EXISTS Users(
    id INTEGER NOT NULL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    fName VARCHAR(255) NOT NULL,
    lName VARCHAR(255) NOT NULL,
    streetAddress VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    state VARCHAR(255) NOT NULL,
    postCode VARCHAR(255) NOT NULL,
    dateCreated DATETIME DEFAULT current_timestamp,
    points INT DEFAULT 0
);

-- TradeStatuses
CREATE TABLE IF NOT EXISTS TradeStatuses(
    id INTEGER NOT NULL PRIMARY KEY,
    statusDescription VARCHAR(255) NOT NULL
);

-- Trades
CREATE TABLE IF NOT EXISTS Trades(
    id INTEGER NOT NULL PRIMARY KEY,
    userRequestedId INTEGER,
    userPostedId INTEGER,
    bookId INTEGER,
    statusId INTEGER,
    dateCreated DATETIME DEFAULT current_timestamp,
    FOREIGN KEY (userRequestedId) REFERENCES Users (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (userPostedId) REFERENCES Users (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (bookId) REFERENCES Books (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (statusId) REFERENCES TradeStatuses (id) ON DELETE NO ACTION ON UPDATE CASCADE
);

-- Wishlists
CREATE TABLE IF NOT EXISTS Wishlists(
    id INTEGER NOT NULL PRIMARY KEY,
    userId INTEGER,
    dateCreated DATETIME DEFAULT current_timestamp,
    FOREIGN KEY (userId) REFERENCES Users (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- WishlistBooks -- Intersection for Wishlists and Books
CREATE TABLE IF NOT EXISTS WishlistsBooks(
    wishlistId INTEGER,
    bookId INTEGER,
    dateCreated DATETIME DEFAULT current_timestamp,
    PRIMARY KEY (wishlistId, bookId),
    FOREIGN KEY (wishlistId) REFERENCES Wishlists (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bookId) REFERENCES Books (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- UserBooks -- Intersection between Users and Books
CREATE TABLE IF NOT EXISTS UserBooks(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT ,
    userId INTEGER,
    bookId INTEGER,
    copyQualityId INTEGER,
    dateCreated DATETIME DEFAULT current_timestamp,
    FOREIGN KEY (userId) REFERENCES Users (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bookId) REFERENCES Books (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (CopyQualityId) REFERENCES CopyQualities (id) ON DELETE CASCADE ON UPDATE CASCADE
);


/*
Inserting sample data
*/

-- Sample Books
INSERT INTO Books ('title', 'author', 'ISBN') VALUES
    ('Yellow River', 'Freely, I.P.', '99999'),
    ('Forever A Loan', 'Nook, Tom', '1111111111111'),
    ('Six of Crows', 'Bardugo, Leigh', '9781627795227');

-- Sample Copy Qualities
INSERT INTO CopyQualities ('qualityDescription') VALUES ('Brand New'),
    ('Mint -- Like New'), ('Very Good'), ('Useable'), ('Tattered'), ('Dust');

-- Sample "admin" user, for easy login check
INSERT INTO Users('username', 'password', 'fName', 'lName', 'streetAddress',
    'city', 'state', 'postCode') VALUES
    ('admin@bookswap.com', 'password', 'Admin', 'Istrator', '123 Main Street', 'Springfield',
        'Oregon', '97475');

-- Sample User data from mockaroo.com
INSERT INTO Users ('username', 'password', 'fName', 'lName', 'streetAddress',
    'city', 'state', 'postCode') VALUES
    ('fpringle0@archive.org', '5o6RPSL', 'Filmore', 'Pringle', '99 Ruskin Court',	
        'Knoxville', 'Tennessee', '37924'),
    ('khildrup1@pen.io',	'IuYdId', 'Kit', 'Hildrup', '82567 Onsgard Road',	
        'Richmond',	'Virginia',	'23203'),
    ('csearl2@cdc.gov', 'nAvtnI', 'Cassey', 'Searl', '44681 Pearson Alley', 
        'Saint Louis', 'Missouri', '63131'),
    ('esabates3@samsung.com', 'kydXrZxzz9Va', 'Edward', 'Sabates',	'63 Welch Court',
        'Spokane', 'Washington', '99215'),
    ('jextal4@reference.com', 'DUwvKPx81Iji', 'Jason', 'Extal', '98 Sugar Alley', 
        'Nashville', 'Tennessee', '37215');

-- Sample Wishlists
INSERT INTO Wishlists (userId) VALUES
    ((SELECT id from Users WHERE username = 'fpringle0@archive.org')),
    ((SELECT id from Users WHERE username = 'khildrump1@pen.io')),
    ((SELECT id from Users WHERE username = 'csearl2@cdc.gov'))
    ;

-- Sample Wishlist Books
    -- First user has no books in their wishlist
    -- Second user wants "Yellow River"
INSERT INTO WishlistsBooks (wishlistId, bookId) VALUES
    (
        (SELECT id FROM Wishlists WHERE userId = (
            SELECT id FROM Users WHERE username = 'khildrump1@pen.io')
    ),
        (SELECT id FROM Books WHERE ISBN = '99999')
    );

    -- Third user wants "Forever A Loan" and "Six of Crows"
INSERT Into WishlistsBooks (wishlistId, bookId) VALUES
    (
        ( SELECT id FROM Wishlists WHERE userId = (
            SELECT id FROM Users WHERE username = 'csearl2@cdc.gov')),
        (SELECT id FROM Books WHERE ISBN = '1111111111111')
    ),
    (
        ( SELECT id FROM Wishlists WHERE userId = (
                SELECT id FROM Users Where username = 'csearl2@cdc.gov')),
        (SELECT ID FROM BOOKS WHERE ISBN = '9781627795227')
    )
    ;

INSERT INTO UserBooks (userId, bookId, copyQualityId) VALUES
    (1, 1, 2),
    (1, 3, 4);

