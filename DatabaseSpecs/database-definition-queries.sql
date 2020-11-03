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
DROP TABLE IF EXISTS WishlistBooks;
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
    points INT DEFAULT 0
);

-- TradeStatuses
CREATE TABLE IF NOT EXISTS TradeStatuses(
    id INT NOT NULL PRIMARY KEY,
    statusDescription VARCHAR(255) NOT NULL
);

-- Trades
CREATE TABLE IF NOT EXISTS Trades(
    id INT NOT NULL PRIMARY KEY,
    userRequestedId INT,
    userPostedId INT,
    bookId INT,
    statusId INT,
    FOREIGN KEY (userRequestedId) REFERENCES Users (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (userPostedId) REFERENCES Users (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (bookId) REFERENCES Books (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (statusId) REFERENCES TradeStatuses (id) ON DELETE NO ACTION ON UPDATE CASCADE
);

-- Wishlists
CREATE TABLE IF NOT EXISTS Wishlists(
    id INT NOT NULL PRIMARY KEY,
    userId INT,
    FOREIGN KEY (userId) REFERENCES Users (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- WishlistBooks -- Intersection for Wishlists and Books
CREATE TABLE IF NOT EXISTS WishlistsBooks(
    wishlistId INT,
    bookId INT,
    PRIMARY KEY (wishlistId, bookId),
    FOREIGN KEY (wishlistId) REFERENCES Wishlists (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bookId) REFERENCES Books (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- UserBooks -- Intersection between Users and Books
CREATE TABLE IF NOT EXISTS UserBooks(
    id INT NOT NULL PRIMARY KEY,
    userId INT,
    bookId INT,
    copyQualityId INT,
    FOREIGN KEY (userId) REFERENCES Users (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bookId) REFERENCES Books (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (CopyQualityId) REFERENCES CopyQualities (id) ON DELETE CASCADE ON UPDATE CASCADE
);


/*
Inserting sample data
*/

INSERT INTO Books ('title', 'author', 'ISBN') VALUES
    ('Yellow River', 'Freely, I.P.', '99999'),
    ('Forever A Loan', 'Nook, Tom', '1111111111111'),
    ('Six of Crows', 'Bardugo, Leigh', '9781627795227');

INSERT INTO CopyQualities ('qualityDescription') VALUES ('Brand New'),
    ('Mint -- Like New'), ('Very Good'), ('Useable'), ('Tattered'), ('Dust');

-- Sample User data from mockaroo.com
INSERT INTO Users ('username', 'password', 'fName', 'lName', 'streetAddress',
    'city', 'state', 'postCode') VALUES
    ('nrubinowicz0', '5o6RPSL', 'Nettie', 'Rubinowicz', '99 Ruskin Court',	
        'Knoxville', 'Tennessee', '37924'),
    ('kreignould1',	'IuYdId', 'Kissiah', 'Reignould', '82567 Onsgard Road',	
        'Richmond',	'Virginia',	'23203'),
    ('afoan2', 'nAvtnI', 'Andonis', 'Foan', '44681 Pearson Alley', 
        'Saint Louis', 'Missouri', '63131'),
    ('epennicott3', 'kydXrZxzz9Va', 'Emilia', 'Pennicott',	'63 Welch Court',
        'Spokane', 'Washington', '99215'),
    ('elongmate4', 'DUwvKPx81Iji', 'El', 'Longmate', '98 Sugar Alley', 
        'Nashville', 'Tennessee', '37215');