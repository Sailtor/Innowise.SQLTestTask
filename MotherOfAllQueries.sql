-- Creating database
CREATE DATABASE InnowiseTestDB;
GO

-- Task 1
-- Creating database tables and constraints for them
USE InnowiseTestDB;

CREATE TABLE socialGroups
(
	Id INT IDENTITY,
	Name NVARCHAR(256) NOT NULL,

	CONSTRAINT PK_Social_Group_Id PRIMARY KEY (Id)
)
CREATE TABLE cities
(
	Id INT IDENTITY,
	Name NVARCHAR(256) NOT NULL,

	CONSTRAINT PK_City_Id PRIMARY KEY (Id)
)
CREATE TABLE banks
(
	Id INT IDENTITY,
	Name NVARCHAR(256) NOT NULL,

	CONSTRAINT PK_Bank_Id PRIMARY KEY (Id)
)
GO

CREATE TABLE branches
(
	Id INT IDENTITY,
	BankId INT NOT NULL,
	CityId INT NOT NULL,
	Name NVARCHAR(256) NOT NULL,

	CONSTRAINT PK_Branch_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Branch_Bank FOREIGN KEY (BankId) REFERENCES Banks(Id)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	CONSTRAINT FK_Branch_City FOREIGN KEY (CityId) REFERENCES Cities(Id)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
)
CREATE TABLE clients
(
	Id INT IDENTITY,
	Name NVARCHAR(256) NOT NULL,
	Surname NVARCHAR(256) NOT NULL,
	SocialGroupId INT NOT NULL,

	CONSTRAINT PK_Client_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Client_SocialGroup FOREIGN KEY (SocialGroupId) REFERENCES socialGroups(Id)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
)
CREATE TABLE accounts
(
	Id INT IDENTITY,
	ClientId INT NOT NULL,
	BankId INT NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT PK_Account_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Account_Client FOREIGN KEY (ClientId) REFERENCES clients(Id)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	CONSTRAINT FK_Account_Bank FOREIGN KEY (BankId) REFERENCES banks(Id)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	CONSTRAINT UC_Accounts UNIQUE (ClientId, BankId)
)
CREATE TABLE cards
(
	Id INT IDENTITY,
	AccountId INT NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT PK_Card_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Card_Account FOREIGN KEY (AccountId) REFERENCES accounts(Id)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
)
GO

-- Populating database with test data
INSERT INTO socialGroups (Name)
VALUES
	('Default'),
	('Retiree'),
	('Veteran'),
	('Employee'),
	('Child'),
	('Disabled')
INSERT INTO cities (Name)
VALUES
	('Minsk'),
	('Polotsk'),
	('Vitebsk'),
	('Brest'),
	('Gomel'),
	('Mogilev')
INSERT INTO banks (Name)
VALUES
	('Belarusbank'),
	('AlphaBank'),
	('BelInvestBank'),
	('BelAgroPromBank'),
	('SberBank'),
	('MTBank')
GO

INSERT INTO branches (BankId,CityId,Name)
VALUES
	(1,2,'BelarusBank ¹31'),
	(1,1,'BelarusBank HQ'),
	(1,2,'BelarusBank ¹22'),
	(1,6,'BelarusBank ¹118'),
	(2,4,'AlphaBank HQ'),
	(2,2,'AlphaBank ¹11'),
	(3,5,'BelInvestBank ¹228'),
	(3,1,'BelInvestBank ¹148'),
	(3,3,'BelInvestBank ¹3'),
	(4,3,'BelAgroPromBank ¹322'),
	(4,6,'BelAgroPromBank HQ'),
	(4,6,'BelAgroPromBank ¹11'),
	(4,5,'BelAgroPromBank ¹22'),
	(4,3,'BelAgroPromBank ¹322'),
	(5,6,'SberBank ¹124'),
	(6,4,'MTBank ¹2341'),
	(6,3,'MTBank ¹8'),
	(6,1,'MTBank ¹171')
INSERT INTO clients (Name,Surname,SocialGroupId)
VALUES
	('Vasya', 'Pupkin', 3),
	('Lena', 'Golovach', 1),
	('Yasos', 'Biba', 2),
	('Yana', 'Cist', 4),
	('Jechka', 'Dirova', 5),
	('Yappi', 'Door', 6),
	('Suq', 'Madiq', 1)
INSERT INTO accounts (ClientId,BankId,Balance)
VALUES
	(1,2,1000),
	(1,1,12000),
	(1,4,23),
	(2,5,2345),
	(2,3,0),
	(3,4,5),
	(3,1,2010.11),
	(4,6,0.53),
	(4,3,100500),
	(5,4,42),
	(6,3,69420.69),
	(7,6,9000)
INSERT INTO cards (AccountId,Balance)
VALUES
	(1,500),
	(2,800),
	(2,1100),
	(2,6790.09),
	(4,110),
	(4,90),
	(5,0),
	(6,5),
	(8,0.53),
	(8,0),
	(9,10000),
	(9,900),
	(11,69),
	(11,228),
	(11,69),
	(12,1000),
	(12,800)
GO

-- Task 2 (city ID = 4)
SELECT DISTINCT banks.Name
FROM branches
	JOIN banks on branches.BankId = banks.Id		
WHERE branches.CityId = 2
GO

-- Task 3
SELECT clients.Name AS ClientName, cards.Balance, banks.Name AS BankName
FROM cards
	JOIN accounts on cards.AccountId = accounts.Id
	JOIN clients on accounts.ClientId = clients.Id
	JOIN banks on accounts.BankId = banks.Id
GO

-- Task 4
SELECT accounts.Id, accounts.Balance AS AccountBalance, COALESCE(SUM(cards.Balance),0) AS CardsBalance, accounts.Balance - COALESCE(SUM(cards.Balance),0) AS Mismatch
FROM accounts
	LEFT JOIN cards on accounts.Id = cards.AccountId
GROUP BY accounts.Id, accounts.Balance
HAVING accounts.Balance - COALESCE(SUM(cards.Balance),0) != 0
GO

-- Task 5 (using GROUP BY)
SELECT socialGroups.Id, socialGroups.Name, COUNT(cards.Id) AS CardsCount
FROM socialGroups
	LEFT JOIN clients on clients.SocialGroupId = socialGroups.Id
	LEFT JOIN accounts on accounts.ClientId = clients.Id
	LEFT JOIN cards on cards.AccountId = accounts.Id
GROUP BY socialGroups.Id, socialGroups.Name
GO

-- Task 5 (using subquery)
SELECT socGroupsHigh.Id, socGroupsHigh.Name, (
	SELECT COUNT(cards.Id) 
	FROM socialGroups
		LEFT JOIN clients on clients.SocialGroupId = socialGroups.Id
		LEFT JOIN accounts on accounts.ClientId = clients.Id
		LEFT JOIN cards on cards.AccountId = accounts.Id
	WHERE socialGroups.Id = socGroupsHigh.Id) AS CardsCount
FROM socialGroups as socGroupsHigh
GO

-- Task 6 
CREATE PROCEDURE Add10$ToSocGroup 
	@SocGroupId INT
AS
BEGIN
	IF @SocGroupId < 1
		BEGIN
			PRINT 'Invalid social group ID'
		END;
	ELSE
		IF NOT EXISTS (SELECT * 
			FROM socialGroups
			WHERE socialGroups.Id = @SocGroupId)
			BEGIN
				PRINT 'Social group with this ID does not exist'
			END;
		ELSE
		IF NOT EXISTS (SELECT *
			FROM clients
			WHERE clients.SocialGroupId = @SocGroupId)
			BEGIN
				PRINT 'No clients of that social group found'
			END;
			ELSE
				IF NOT EXISTS (SELECT *
					FROM accounts
						JOIN clients on accounts.ClientId = clients.Id
					WHERE clients.SocialGroupId = @SocGroupId)
					BEGIN
						PRINT 'No accounts associated with clients of that social group found'
					END
				ELSE
				BEGIN
					UPDATE accounts
					SET Balance += 10
					FROM accounts
						JOIN clients on clients.Id = accounts.ClientId
					WHERE clients.SocialGroupId = @SocGroupId
				END;
END;
GO

SELECT accounts.Balance
FROM accounts

EXEC Add10$ToSocGroup 1

SELECT accounts.Balance
FROM accounts
GO

-- Task 7
SELECT accounts.Id, clients.Name, clients.Surname, accounts.Balance - COALESCE(SUM(cards.Balance),0) AS AvailableFunds
FROM accounts
	JOIN clients on accounts.ClientId = clients.Id
	LEFT JOIN cards on cards.AccountId = accounts.Id
GROUP BY accounts.Id, clients.Name, clients.Surname, accounts.Balance
GO

-- Task 8
CREATE PROCEDURE TransferMoneyToCardFromAcc 
	@AccountId INT,
	@CardId INT,
	@Amount MONEY
AS
BEGIN
	IF @AccountId < 1 OR @CardId < 1 OR @Amount<=0
		BEGIN
			PRINT 'Invalid input'
		END;
	ELSE
		BEGIN TRANSACTION
		IF NOT EXISTS (SELECT * 
			FROM accounts
			WHERE accounts.Id = @AccountId)
			BEGIN
				PRINT 'Account with this ID does not exist'
			END;
		ELSE
			IF NOT EXISTS (SELECT *
				FROM cards
				WHERE cards.Id = @CardId)
				BEGIN
					PRINT 'Card with this ID does not exist'
				END;
				ELSE
					IF NOT EXISTS (SELECT * 
						FROM cards
						WHERE cards.Id = @CardId
							AND cards.AccountId = @AccountId)
						BEGIN
							PRINT 'Specified card does not belong to specified account'
						END;
						ELSE
							IF NOT EXISTS (SELECT accounts.Id, accounts.Balance
								FROM accounts
									JOIN cards on cards.AccountId = accounts.Id
								WHERE accounts.Id = @AccountId
								GROUP BY accounts.Id, accounts.Balance
								HAVING accounts.Balance - SUM(cards.Balance) >= @Amount)
								BEGIN
									PRINT 'Not enough money on account to transfer'
								END
							ELSE
							BEGIN TRY
								UPDATE cards
								SET Balance += @Amount
								FROM cards
								WHERE Id = @CardId
								COMMIT
							END TRY
							BEGIN CATCH
								ROLLBACK
							END CATCH
END;
GO

SELECT cards.Id, cards.Balance
FROM cards

EXEC TransferMoneyToCardFromAcc 4,5,100

SELECT cards.Id, cards.Balance
FROM cards
GO

--Task 9
CREATE TRIGGER Accounts_UPDATE
ON accounts
INSTEAD OF UPDATE
AS
BEGIN
	UPDATE accounts
	SET accounts.Balance = (
		SELECT inserted.Balance
		FROM inserted
		WHERE accounts.Id = inserted.Id)
	WHERE EXISTS (
		SELECT *
		FROM inserted
			JOIN cards on cards.AccountId = inserted.Id
		WHERE inserted.Id = accounts.Id
		GROUP BY inserted.Id, inserted.Balance
		HAVING inserted.Balance - SUM(cards.Balance) >= 0)

	IF @@ROWCOUNT < (
		SELECT COUNT(inserted.Id)
		FROM inserted)
		PRINT 'Some of the rows were not affected because of the card/account balance issuses'
END;
GO

SELECT *
FROM accounts

UPDATE accounts
SET Balance = 500
WHERE accounts.BankId = 6

SELECT *
FROM accounts
GO

CREATE TRIGGER Cards_UPDATE
ON cards
INSTEAD OF UPDATE
AS
BEGIN
	UPDATE cards
	SET cards.Balance = insHigh.Balance
	FROM cards 
		JOIN inserted as insHigh on cards.Id = insHigh.Id
		JOIN deleted on deleted.Id = insHigh.Id
	WHERE (
		SELECT accounts.Balance - SUM(cards.Balance)
		FROM accounts
			JOIN cards on cards.AccountId = accounts.Id
		WHERE cards.AccountId = insHigh.AccountId
		GROUP BY accounts.Id, accounts.Balance) >= (insHigh.Balance - deleted.Balance)

	IF @@ROWCOUNT < (
	SELECT COUNT(inserted.Id)
	FROM inserted)
	PRINT 'Some of the rows were not affected because of the card/account balance issuses'
END;
GO

SELECT * 
FROM cards

UPDATE cards
SET Balance += 600
WHERE Id = 2 or Id = 9

SELECT * 
FROM cards
GO