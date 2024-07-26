-- =======================================================================================================
-- Developer:		Aderoju A.

-- Date: May 2024
-- Project:		Order Management System (OMS)
-- Description: The OMS facilitates tracking of orders From inception to fulfillment and managing the people, 
--				processes and data connected to the order as it moves through its lifecycle.

-- Key Features: Visibility into Sales, Orders and People Management, 
--				 Inventory Management, Order Fulfilment Optimization
--				 Analytics and Reports
-- =======================================================================================================
GO
 
-- Drop OMS DB if already existing on the server
IF EXISTS (SELECT 1 FROM sys.databases WHERE database_id = DB_ID('OMS'))
BEGIN
	USE Master;           --	Switch to Master DB to avoid dropping an active Database
	ALTER DATABASE OMS SET SINGLE_USER WITH ROLLBACK IMMEDIATE; --	Switch to single user and logout other users
	DROP DATABASE OMS
END

-- Create OMS DB to contain all the Tables, procedures, Functions, Triggers etc, that enable OMS functionalities
CREATE DATABASE OMS;
GO

-- Activate the DB
USE OMS;
GO

-- ========================================================================================================
--  Step 1: Create and link all the necessary Tables: Customers, Inventory, Sales, Orders etc
-- ========================================================================================================
GO

-- 1. Create a dimensional Table for Details of Sales Managers
CREATE TABLE manager (Territory VARCHAR(20) PRIMARY KEY,
FirstName VARCHAR(30) NOT NULL,
LastName VARCHAR(30) NOT NULL,
DateofBirth DATE NOT NULL,
DateJoined DATE DEFAULT CURRENT_TIMESTAMP)
GO

-- 2. Create a dimensional Table for Business locations
CREATE TABLE location (LocationID CHAR(7) PRIMARY KEY,
Region VARCHAR(20) NOT NULL,
State VARCHAR(40) NOT NULL,
Territory VARCHAR(20) NOT NULL,
City VARCHAR(20) NOT NULL,
CONSTRAINT fk_location FOREIGN KEY (Territory) REFERENCES manager(Territory)
ON UPDATE CASCADE,
CONSTRAINT loc_uniq UNIQUE (Region,Territory,State,city))
GO

-- 3. Create a dimensional Table for different type of customers
CREATE TABLE CustomerType(CustomerTypeID INT PRIMARY KEY,Description VARCHAR(15))
GO

-- 4. Create a dimensional Table to store customers details
CREATE TABLE Customer (CustomerID CHAR(8) PRIMARY KEY,
CustomerName VARCHAR(50) NOT NULL,
CustomerTypeID INT NOT NULL,
EmailAddress VARCHAR(60) NOT NULL,
DateRegistered DATETIME DEFAULT CURRENT_TIMESTAMP,
LocationID CHAR(7),
CreditLimit DECIMAL(18,2) DEFAULT 0,
AccountBalance DECIMAL(18,2) DEFAULT 0,
CONSTRAINT fk_loc FOREIGN KEY(LocationID) REFERENCES location(LocationID),
CONSTRAINT fk_custype FOREIGN KEY(CustomerTypeID) REFERENCES customerType(CustomerTypeID),
CONSTRAINT uniq_custlocation UNIQUE (CustomerName,LocationID,CustomerTypeID)
)
GO

-- 5. Create a Table to store information on deleted customers details for auditory purpose
CREATE TABLE customer_audit(
CustomerID CHAR(8) PRIMARY KEY,
CustomerName VARCHAR(50) NOT NULL,
CustomerTypeID INT NOT NULL,
EmailAddress VARCHAR(50) NOT NULL,
DateRegistered DATETIME,
LocationID CHAR(7),
CreditLimit decimal(18,2),
AccountBalance decimal(18,2),
DateRemoved DATETIME DEFAULT CURRENT_TIMESTAMP,
RemovedBy VARCHAR(30) DEFAULT ORIGINAL_LOGIN()
)
GO

-- 6. Create a dimensional Table to store information on company's products
CREATE TABLE product (ProductID  CHAR(7) PRIMARY KEY,
[Product Description] VARCHAR(50) NOT NULL,
Brand VARCHAR(30) NOT NULL,
PricePerCase DECIMAL(18,2),
UnitCost DECIMAL(18,2) NOT NULL,
QTY INT DEFAULT 0,
CONSTRAINT CHK_Qty  CHECK (QTY>=0),
ValidFrom DATETIME2(2) GENERATED ALWAYS AS ROW START HIDDEN,
ValidTo DATETIME2(2) GENERATED ALWAYS AS ROW END HIDDEN,
PERIOD FOR SYSTEM_TIME(ValidFrom,ValidTo))
WITH (SYSTEM_VERSIONING=ON (HISTORY_TABLE=dbo.InventoryHistory))
GO

--7. Create Invoice Table to keep track of invoices
CREATE TABLE Invoice (OrderID CHAR(13) PRIMARY KEY,
Status VARCHAR(50) DEFAULT 'Not Billed',
Amount DECIMAL(18,2) DEFAULT 0)
GO

-- 8. Create a transactional Table to keep track of orders
CREATE TABLE orders (OrderID CHAR(13) NOT NULL,
CustomerID CHAR(8) NOT NULL,
LocationID CHAR(7) NOT NULL,
DateofOrder DATETIME DEFAULT CURRENT_TIMESTAMP,
ProductID CHAR(7) NOT NULL,
Qty INT,
Amount DECIMAL(18,2) DEFAULT 0,
CONSTRAINT fk_orders FOREIGN KEY (ProductID) REFERENCES product (ProductID))
GO

-- 9. Create a transactional Table to store information on invoiced orders
CREATE TABLE sales (OrderID CHAR(13),
TransactionDate DATETIME DEFAULT CURRENT_TIMESTAMP,
ProductID CHAR(7) NOT NULL,
CustomerID CHAR(8) NOT NULL,
[Qty Returned] INT DEFAULT 0,
[Qty Sold] INT DEFAULT 0,
[Qty Net] INT DEFAULT 0,
[Avalaible Qty] INT DEFAULT 0,
[Unit Price] DECIMAL(18,2) NOT NULL,
[Selling Amount] DECIMAL(18,2) NOT NULL,
VAT DECIMAL(18,2) NOT NULL,
[Unit Cost] DECIMAL(18,2) NOT NULL,
[Total Cost] DECIMAL(18,2) NOT NULL,
[Profit Margin] DECIMAL(18,2) NOT NULL,
[%Profit] DECIMAL(18,2) NOT NULL)
GO

-- 10. Create a transactional Table to store records of payment FROM customers
CREATE TABLE payment (CustomerID CHAR(8) NOT NULL,
AmountPaid DECIMAL(18,2) NOT NULL,
PaymentDate DATETIME DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT fk_payment FOREIGN KEY (CustomerID) REFERENCES customer(CustomerID)
)
GO

-- 11. Create a transactional Table to store records of payment FROM customersKeeps records of both paymnet and sales
CREATE TABLE Lodgement (CustomerID CHAR(8) NOT NULL,
ValueDate DATETIME DEFAULT CURRENT_TIMESTAMP,
Debit DECIMAL(18,2) DEFAULT 0,
Credit DECIMAL(18,2) DEFAULT 0,
AccountBalance DECIMAL(18,2) DEFAULT 0,
Description VARCHAR (30) NOT NULL,
CONSTRAINT fk_lodgement FOREIGN KEY (CustomerID) REFERENCES customer(CustomerID)
)
go

-- 12. Create a Table to store information on deleted orders for auditory purpose
CREATE TABLE orders_audit(OrderID CHAR(13),
CustomerID CHAR(8) NOT NULL,
LocationID CHAR(7) NOT NULL,
DateofOrder DATETIME NOT NULL,
ProductID CHAR(7) NOT NULL,
Qty INT,
Amount DECIMAL(18,2),
DateDeleted DATETIME DEFAULT CURRENT_TIMESTAMP,
ByPersonnel VARCHAR(30) DEFAULT ORIGINAL_LOGIN()
)
GO

-- 13. Create a transactional Table to store information on returned orders
CREATE TABLE Reversal(OrderID CHAR(13) NOT NULL,
Prodcode CHAR(7) NOT NULL,
[QTY returned] INT DEFAULT 0,
Amount DECIMAL(18,2),
DateReturned DATETIME DEFAULT CURRENT_TIMESTAMP,
ByPersonnel VARCHAR(30) DEFAULT ORIGINAL_LOGIN(),
Reason VARCHAR(100) NOT NULL
)
GO
-- 14. Create a dimensional Table to store information on shippers for delivering orders
CREATE TABLE shipper (LocationID CHAR(7),
ShipperFirstName VARCHAR(30) NOT NULL,
ShipperLAStName VARCHAR(30) NOT NULL,
PhoneNumber CHAR(11) NOT NULL,
CONSTRAINT fk_shipper FOREIGN KEY (LocationID) REFERENCES Location (LocationID)
on UPDATE CASCADE)
GO

-- 15. Create a transactional Table to keep track of rebate
CREATE TABLE RebateDetail (
CustomerID CHAR(8) NOT NULL,
PurchaseMonth DATE DEFAULT CURRENT_TIMESTAMP,
[Total Purchase] DECIMAL(18,2) DEFAULT 0,
[Total Qty] INT DEFAULT 0,
RebateAmount DECIMAL(18,2) DEFAULT 0,
RebateType VARCHAR(10) DEFAULT '5% off',
RebateStatus VARCHAR(20))
GO

-- ========================================================================================================
--  Here, we will insert records into the dimension tables
-- ========================================================================================================
SET NOCOUNT ON
GO
-- 1. Insert product details into the product Table
INSERT INTO product
VALUES ('PRD0001','4TH STREET 75CL NON ALCOHOLIC SWEET WINE','4S NON ALCOHOLIC',13500,13485.96,881),
('PRD0002','4TH STREET SPARKLING WHITE','4S SPARKLING ALCOHOLIC',15600,10245.18,799),
('PRD0003','4TH STREET SPARKLING RED','4S SPARKLING ALCOHOLIC',15600,8859.55,241),
('PRD0004','4TH STREET SPARKLING ROSE','4S SPARKLING ALCOHOLIC',15600,287.68,461),
('PRD0005','4TH STREET RED 12X37.5CL','4TH STREET',14400,4615.25,550),
('PRD0006','4TH STREET ROSE 12X37.5CL','4TH STREET',14400,13787.01,692),
('PRD0007','4TH STREET WHITE 12X37.5CL','4TH STREET',14400,2007.26,627),
('PRD0008','4TH STREET RED 6X75CL','4TH STREET',14700,3066.15,454),
('PRD0009','4TH STREET ROSE 6X75CL','4TH STREET',14700,8712.72,464),
('PRD0010','4TH STREET WHITE 6X75CL','4TH STREET',14700,1230.63,308),
('PRD0011','AMARULA CREAM 6X700ML','AMARULA',30500,22378.3,657),
('PRD0012','AMARULA CREAM 12X375ML','AMARULA',38500,23174.14,369),
('PRD0013','CELLAR CASK NATURAL JUICY RED WINE','CELLAR CASK',39900,13888.36,341),
('PRD0014','CELLAR CASK NATURAL LIVELY WHITE WINE','CELLAR CASK',19950,11011,890),
('PRD0015','CHAMDOR GIFT PACK','CHAMDOR',13800,6062.49,640),
('PRD0016','CHAMDOR RED','CHAMDOR',17100,16348.88,529),
('PRD0017','CHAMDOR WHITE','CHAMDOR',17100,14585.59,607),
('PRD0018','DROSTDY HOF EXTRA LIGHT ROSE 12X75CL','DROSTDY HOF',20000,1731.46,320),
('PRD0019','ESPRIT APPLE','ESPIRIT',13585,5527.42,331),
('PRD0020','ESPRIT MANGO','ESPIRIT',13585,9386.91,578),
('PRD0021','DROSTDY HOF EXTRA LIGHT WHITE 12X75CL','DROSTDY HOF',20000,1743.19,466),
('PRD0022','DROSTDY HOF GRAND CRU 12X375ML','DROSTDY HOF',22000,3168.8,991)
GO

-- 2. Insert details about sales managers into the manager Table
INSERT INTO manager
VALUES ('Benin','Henry','Obarisiagbon','19870812','20231004'),
('Onitsha','Nzemeka','Samson','19830614','20190304'),
('Enugu','Michael','Okereke','19861215','20200713'),
('Calabar','Collins','Anumenechi','19810708','20210809'),
('Aba','Ezeoha','Erondu','19880812','20180919'),
('Ibadan','Taiye','Ikuponiyi','19890224','20230926'),
('Port Harcout','Benjamin','Ekwueme','19840719','20190720'),
('Kaduna','Timothy','Dominic','19821210','20190128'),
('Ilorin','Abayomi','Emmanuel','19860224','20220718'),
('Yola','Omeye','Hyginus','19890103','20191111'),
('Jos','Lazarus','Sule','19870413','20230914'),
('Abeokuta','Emmanuel','Oyeniyi','19960812','20230224'),
('Lagos','Johnbosco','Nwokoro','19951116','20190128'),
('Abuja','Victor','Dike','19860804','20221026'),
('Owerri','Ikenna','Umeh','19960411','20190408')
GO

-- 3. Insert location details into the Location Table
INSERT INTO Location
VALUES ('LOC0001','SOUTH','Edo','BENIN','Auchi'),
('LOC0002','SOUTH','Edo','BENIN','Benin'),
('LOC0003','SOUTH','Edo','BENIN','Sapele'),
('LOC0004','SOUTH','Edo','BENIN','Warri'),
('LOC0005','SOUTH','Edo','BENIN','Esan'),
('LOC0006','SOUTH','Edo','BENIN','Akoko'),
('LOC0007','SOUTH','Edo','BENIN','Etsako'),
('LOC0008','SOUTH','Edo','BENIN','Igueben'),
('LOC0009','SOUTH','Edo','BENIN','Owan'),
('LOC0010','SOUTH','Edo','BENIN','Ovia'),
('LOC0011','SOUTH','Edo','BENIN','Ikpoba'),
('LOC0012','NORTH','Federal Capital Territory','ABUJA','Gwagbalada'),
('LOC0013','NORTH','Federal Capital Territory','ABUJA','Berger Wuse'),
('LOC0014','NORTH','Federal Capital Territory','ABUJA','Zuba'),
('LOC0015','NORTH','Federal Capital Territory','ABUJA','Mararaba'),
('LOC0016','NORTH','Federal Capital Territory','ABUJA','Gwarimpa'),
('LOC0017','NORTH','Federal Capital Territory','ABUJA','Bamburu'),
('LOC0018','NORTH','Federal Capital Territory','ABUJA','Maitama'),
('LOC0019','NORTH','Federal Capital Territory','ABUJA','Garki'),
('LOC0020','NORTH','Federal Capital Territory','ABUJA','ASokoro'),
('LOC0021','NORTH','Federal Capital Territory','ABUJA','Karu'),
('LOC0022','NORTH','Federal Capital Territory','ABUJA','Kubwa'),
('LOC0023','NORTH','Federal Capital Territory','ABUJA','Jikwoyi'),
('LOC0024','NORTH','Federal Capital Territory','ABUJA','Masaka'),
('LOC0025','NORTH','Federal Capital Territory','ABUJA','Kurunduma'),
('LOC0026','NORTH','Federal Capital Territory','ABUJA','New Nyanya'),
('LOC0027','NORTH','Federal Capital Territory','ABUJA','karshi'),
('LOC0028','NORTH','Federal Capital Territory','ABUJA','Yoba'),
('LOC0029','NORTH','Federal Capital Territory','ABUJA','Jabi'),
('LOC0030','NORTH','Federal Capital Territory','ABUJA','Wuse'),
('LOC0031','EAST','Anambra','ONITSHA','ASaba'),
('LOC0032','EAST','Anambra','ONITSHA','Onitsha'),
('LOC0033','EAST','Anambra','ONITSHA','Oba'),
('LOC0034','EAST','Anambra','ONITSHA','Awka'),
('LOC0035','EAST','Anambra','ONITSHA','Nnewi'),
('LOC0036','EAST','Anambra','ONITSHA','Agbor'),
('LOC0037','EAST','Anambra','ONITSHA','Kwale'),
('LOC0038','EAST','Anambra','ONITSHA','Ogbaru'),
('LOC0039','EAST','Anambra','ONITSHA','Aguata'),
('LOC0040','EAST','Anambra','ONITSHA','Idemili'),
('LOC0041','EAST','Anambra','ONITSHA','Ihiala'),
('LOC0042','EAST','Anambra','ONITSHA','Njikoka'),
('LOC0043','EAST','Enugu ','ENUGU','Nsukka'),
('LOC0044','EAST','Enugu ','ENUGU','Agbani'),
('LOC0045','EAST','Enugu ','ENUGU','Awgu'),
('LOC0046','EAST','Enugu ','ENUGU','Enugu'),
('LOC0047','EAST','Enugu ','ENUGU','Udi'),
('LOC0048','SOUTH','Akwa Ibom','CALABAR','Akamkpa'),
('LOC0049','SOUTH','Akwa Ibom','CALABAR','Akim'),
('LOC0050','SOUTH','Akwa Ibom','CALABAR','Bakassi'),
('LOC0051','SOUTH','Akwa Ibom','CALABAR','Ikot'),
('LOC0052','SOUTH','Akwa Ibom','CALABAR','Ansa'),
('LOC0053','SOUTH','Akwa Ibom','CALABAR','Kasuk'),
('LOC0054','WEST','Lagos','LAGOS','Oke-Arin'),
('LOC0055','WEST','Lagos','LAGOS','Lekki'),
('LOC0056','WEST','Lagos','LAGOS','Ajah'),
('LOC0057','WEST','Lagos','LAGOS','Trade Fair'),
('LOC0058','WEST','Lagos','LAGOS','Mushin'),
('LOC0059','WEST','Lagos','LAGOS','Ikorodu'),
('LOC0060','WEST','Lagos','LAGOS','Ikeja'),
('LOC0061','WEST','Lagos','LAGOS','Ojota'),
('LOC0062','WEST','Lagos','LAGOS','Agege'),
('LOC0063','WEST','Lagos','LAGOS','Ogudu'),
('LOC0064','WEST','Lagos','LAGOS','Magodo'),
('LOC0065','WEST','Lagos','LAGOS','Ogba'),
('LOC0066','WEST','Lagos','LAGOS','Mile 2'),
('LOC0067','WEST','Lagos','LAGOS','Opebi'),
('LOC0068','WEST','Lagos','LAGOS','Isolo'),
('LOC0069','WEST','Lagos','LAGOS','Ilupeju'),
('LOC0070','WEST','Lagos','LAGOS','Surulere'),
('LOC0071','SOUTH','Abia','ABA','Umuahia '),
('LOC0072','SOUTH','Abia','ABA','Osisioma'),
('LOC0073','SOUTH','Abia','ABA','Obingwa'),
('LOC0074','SOUTH','Abia','ABA','ukwa'),
('LOC0075','SOUTH','Abia','ABA','Ugwuamgbo'),
('LOC0076','WEST','Oyo','IBADAN','Ibadan'),
('LOC0077','WEST','Ekiti','IBADAN','Ekiti'),
('LOC0078','WEST','Oyo','IBADAN','Agbeni'),
('LOC0079','WEST','Oyo','IBADAN','Sango'),
('LOC0080','WEST','Osun','IBADAN','Osogbo'),
('LOC0081','WEST','Ondo','IBADAN','Akure'),
('LOC0082','WEST','Osun','IBADAN','Ilesha'),
('LOC0083','WEST','Osun','IBADAN','Ile Ife '),
('LOC0084','SOUTH','Rivers','PORT HARCOUT','Agip'),
('LOC0085','SOUTH','Rivers','PORT HARCOUT','Trans Amadi'),
('LOC0086','SOUTH','Rivers','PORT HARCOUT','Rumuigbo'),
('LOC0087','SOUTH','Rivers','PORT HARCOUT','New Gra'),
('LOC0088','SOUTH','Rivers','PORT HARCOUT','Nkpogu'),
('LOC0089','SOUTH','Rivers','PORT HARCOUT','Ikwere'),
('LOC0090','SOUTH','Rivers','PORT HARCOUT','Etche'),
('LOC0091','SOUTH','Rivers','PORT HARCOUT','Okrika'),
('LOC0092','SOUTH','Rivers','PORT HARCOUT','Oyigbo'),
('LOC0093','NORTH','Kaduna','KADUNA','Kaduna'),
('LOC0094','NORTH','Kaduna','KADUNA','Lokoja'),
('LOC0095','NORTH','Kaduna','KADUNA','Sabon Gari'),
('LOC0096','NORTH','Kaduna','KADUNA','Kachia'),
('LOC0097','NORTH','Kaduna','KADUNA','Ikara'),
('LOC0098','NORTH','Kaduna','KADUNA','Zaria'),
('LOC0099','NORTH','Kaduna','KADUNA','Kajuru'),
('LOC0100','NORTH','Kaduna','KADUNA','Kaura'),
('LOC0101','NORTH','Kaduna','KADUNA','Makarfi'),
('LOC0102','NORTH','Kwara','ILORIN','Ilorin'),
('LOC0103','NORTH','Kwara','ILORIN','Omu-Aran'),
('LOC0104','NORTH','Kwara','ILORIN','Gaa Akanbi'),
('LOC0105','NORTH','Kwara','ILORIN','Kangile'),
('LOC0106','NORTH','Kwara','ILORIN','Tanke'),
('LOC0107','NORTH','Kwara','ILORIN','Ipata'),
('LOC0108','NORTH','Kwara','ILORIN','Muritala Road'),
('LOC0109','NORTH','Kano','YOLA','Kano'),
('LOC0110','NORTH','Yola','YOLA','Yola'),
('LOC0111','NORTH','Taraba','YOLA','Jalingo'),
('LOC0112','NORTH','Kano','YOLA','Takum'),
('LOC0113','NORTH','Borno','YOLA','Maiduguri'),
('LOC0114','NORTH','Yola','YOLA','Michika'),
('LOC0115','NORTH','Yola','YOLA','Song'),
('LOC0116','NORTH','Yola','YOLA','Mubi'),
('LOC0117','NORTH','Yola','YOLA','Madagali'),
('LOC0118','NORTH','Plateau','JOS','Bukuru'),
('LOC0119','NORTH','Plateau','JOS','Zangan'),
('LOC0120','NORTH','Plateau','JOS','Lafia'),
('LOC0121','NORTH','Plateau','JOS','Wase'),
('LOC0122','NORTH','Plateau','JOS','Kanam'),
('LOC0123','NORTH','Plateau','JOS','Bokos'),
('LOC0124','NORTH','Plateau','JOS','Kanke'),
('LOC0125','NORTH','Plateau','JOS','Langtang'),
('LOC0126','NORTH','Plateau','JOS','Mangu'),
('LOC0127','NORTH','Plateau','JOS','Mikang'),
('LOC0128','NORTH','Plateau','JOS','Pankshin'),
('LOC0129','NORTH','Plateau','JOS','Riyom'),
('LOC0130','WEST','Ogun','ABEOKUTA','Ewekoro'),
('LOC0131','WEST','Ogun','ABEOKUTA','Ifo'),
('LOC0132','WEST','Ogun','ABEOKUTA','Obafemi Owode'),
('LOC0133','WEST','Ogun','ABEOKUTA','Ipokia'),
('LOC0134','WEST','Ogun','ABEOKUTA','Imeko Afon'),
('LOC0135','WEST','Ogun','ABEOKUTA','Shagamu'),
('LOC0136','WEST','Ogun','ABEOKUTA','Yewa'),
('LOC0137','WEST','Ogun','ABEOKUTA','Ijebu'),
('LOC0138','WEST','Ogun','ABEOKUTA','Ikenne'),
('LOC0139','WEST','Ogun','ABEOKUTA','Ado-odo'),
('LOC0140','WEST','Ogun','ABEOKUTA','Remo')
GO

-- 4. Insert shipper details into the shipper Table
INSERT INTO shipper
VALUES ('LOC0001','Kolapo','Olaosebikan','09061568725'),
('LOC0002','Kolapo','Olaosebikan','09061568725'),
('LOC0003','Kolapo','Olaosebikan','09061568725'),
('LOC0004','Kolapo','Olaosebikan','09061568725'),
('LOC0005','Kolapo','Olaosebikan','09061568725'),
('LOC0006','Kolapo','Olaosebikan','09061568725'),
('LOC0007','Kolapo','Olaosebikan','09061568725'),
('LOC0008','Kolapo','Olaosebikan','09061568725'),
('LOC0009','Kolapo','Olaosebikan','09061568725'),
('LOC0010','Kolapo','Olaosebikan','09061568725'),
('LOC0011','Kolapo','Olaosebikan','09061568725'),
('LOC0012','Jinadu','Ewele','09091657871'),
('LOC0013','Jinadu','Ewele','09091657871'),
('LOC0014','Jinadu','Ewele','09091657871'),
('LOC0015','Jinadu','Ewele','09091657871'),
('LOC0016','Jinadu','Ewele','09091657871'),
('LOC0017','Jinadu','Ewele','09091657871'),
('LOC0018','Jinadu','Ewele','09091657871'),
('LOC0019','Jinadu','Ewele','09091657871'),
('LOC0020','Jinadu','Ewele','09091657871'),
('LOC0021','Jinadu','Ewele','09091657871'),
('LOC0022','Jinadu','Ewele','09091657871'),
('LOC0023','Jinadu','Ewele','09091657871'),
('LOC0024','Jinadu','Ewele','09091657871'),
('LOC0025','Jinadu','Ewele','09091657871'),
('LOC0026','Jinadu','Ewele','09091657871'),
('LOC0027','Jinadu','Ewele','09091657871'),
('LOC0028','Jinadu','Ewele','09091657871'),
('LOC0029','Jinadu','Ewele','09091657871'),
('LOC0030','Jinadu','Ewele','09091657871'),
('LOC0031','Nureni','Abdsallam','07063320967'),
('LOC0032','Nureni','Abdsallam','07063320967'),
('LOC0033','Nureni','Abdsallam','07063320967'),
('LOC0034','Nureni','Abdsallam','07063320967'),
('LOC0035','Nureni','Abdsallam','07063320967'),
('LOC0036','Nureni','Abdsallam','07063320967'),
('LOC0037','Nureni','Abdsallam','07063320967'),
('LOC0038','Nureni','Abdsallam','07063320967'),
('LOC0039','Nureni','Abdsallam','07063320967'),
('LOC0040','Nureni','Abdsallam','07063320967'),
('LOC0041','Nureni','Abdsallam','07063320967'),
('LOC0042','Nureni','Abdsallam','07063320967'),
('LOC0043','Nureni','Abdsallam','07063320967'),
('LOC0044','Nureni','Abdsallam','07063320967'),
('LOC0045','Nureni','Abdsallam','07063320967'),
('LOC0046','Nureni','Abdsallam','07063320967'),
('LOC0047','Nureni','Abdsallam','07063320967'),
('LOC0048','Kolapo','Olaosebikan','09061568725'),
('LOC0049','Kolapo','Olaosebikan','09061568725'),
('LOC0050','Kolapo','Olaosebikan','09061568725'),
('LOC0051','Kolapo','Olaosebikan','09061568725'),
('LOC0052','Kolapo','Olaosebikan','09061568725'),
('LOC0053','Kolapo','Olaosebikan','09061568725'),
('LOC0054','Sule','Abore','08086532044'),
('LOC0055','Sule','Abore','08086532044'),
('LOC0056','Sule','Abore','08086532044'),
('LOC0057','Sule','Abore','08086532044'),
('LOC0058','Sule','Abore','08086532044'),
('LOC0059','Sule','Abore','08086532044'),
('LOC0060','Sule','Abore','08086532044'),
('LOC0061','Sule','Abore','08086532044'),
('LOC0062','Sule','Abore','08086532044'),
('LOC0063','Sule','Abore','08086532044'),
('LOC0064','Sule','Abore','08086532044'),
('LOC0065','Sule','Abore','08086532044'),
('LOC0066','Sule','Abore','08086532044'),
('LOC0067','Sule','Abore','08086532044'),
('LOC0068','Sule','Abore','08086532044'),
('LOC0069','Sule','Abore','08086532044'),
('LOC0070','Sule','Abore','08086532044'),
('LOC0071','Kolapo','Olaosebikan','09061568725'),
('LOC0072','Kolapo','Olaosebikan','09061568725'),
('LOC0073','Kolapo','Olaosebikan','09061568725'),
('LOC0074','Kolapo','Olaosebikan','09061568725'),
('LOC0075','Kolapo','Olaosebikan','09061568725'),
('LOC0076','Sule','Abore','08086532044'),
('LOC0077','Sule','Abore','08086532044'),
('LOC0078','Sule','Abore','08086532044'),
('LOC0079','Sule','Abore','08086532044'),
('LOC0080','Sule','Abore','08086532044'),
('LOC0081','Sule','Abore','08086532044'),
('LOC0082','Sule','Abore','08086532044'),
('LOC0083','Sule','Abore','08086532044'),
('LOC0084','Kolapo','Olaosebikan','09061568725'),
('LOC0085','Kolapo','Olaosebikan','09061568725'),
('LOC0086','Kolapo','Olaosebikan','09061568725'),
('LOC0087','Kolapo','Olaosebikan','09061568725'),
('LOC0088','Kolapo','Olaosebikan','09061568725'),
('LOC0089','Kolapo','Olaosebikan','09061568725'),
('LOC0090','Kolapo','Olaosebikan','09061568725'),
('LOC0091','Kolapo','Olaosebikan','09061568725'),
('LOC0092','Kolapo','Olaosebikan','09061568725'),
('LOC0093','Jinadu','Ewele','09091657871'),
('LOC0094','Jinadu','Ewele','09091657871'),
('LOC0095','Jinadu','Ewele','09091657871'),
('LOC0096','Jinadu','Ewele','09091657871'),
('LOC0097','Jinadu','Ewele','09091657871'),
('LOC0098','Jinadu','Ewele','09091657871'),
('LOC0099','Jinadu','Ewele','09091657871'),
('LOC0100','Jinadu','Ewele','09091657871'),
('LOC0101','Jinadu','Ewele','09091657871'),
('LOC0102','Jinadu','Ewele','09091657871'),
('LOC0103','Jinadu','Ewele','09091657871'),
('LOC0104','Jinadu','Ewele','09091657871'),
('LOC0105','Jinadu','Ewele','09091657871'),
('LOC0106','Jinadu','Ewele','09091657871'),
('LOC0107','Jinadu','Ewele','09091657871'),
('LOC0108','Jinadu','Ewele','09091657871'),
('LOC0109','Jinadu','Ewele','09091657871'),
('LOC0110','Jinadu','Ewele','09091657871'),
('LOC0111','Jinadu','Ewele','09091657871'),
('LOC0112','Jinadu','Ewele','09091657871'),
('LOC0113','Jinadu','Ewele','09091657871'),
('LOC0114','Jinadu','Ewele','09091657871'),
('LOC0115','Jinadu','Ewele','09091657871'),
('LOC0116','Jinadu','Ewele','09091657871'),
('LOC0117','Jinadu','Ewele','09091657871'),
('LOC0118','Jinadu','Ewele','09091657871'),
('LOC0119','Jinadu','Ewele','09091657871'),
('LOC0120','Jinadu','Ewele','09091657871'),
('LOC0121','Jinadu','Ewele','09091657871'),
('LOC0122','Jinadu','Ewele','09091657871'),
('LOC0123','Jinadu','Ewele','09091657871'),
('LOC0124','Jinadu','Ewele','09091657871'),
('LOC0125','Jinadu','Ewele','09091657871'),
('LOC0126','Jinadu','Ewele','09091657871'),
('LOC0127','Jinadu','Ewele','09091657871'),
('LOC0128','Jinadu','Ewele','09091657871'),
('LOC0129','Jinadu','Ewele','09091657871'),
('LOC0130','Sule','Abore','08086532044'),
('LOC0131','Sule','Abore','08086532044'),
('LOC0132','Sule','Abore','08086532044'),
('LOC0133','Sule','Abore','08086532044'),
('LOC0134','Sule','Abore','08086532044'),
('LOC0135','Sule','Abore','08086532044'),
('LOC0136','Sule','Abore','08086532044'),
('LOC0137','Sule','Abore','08086532044'),
('LOC0138','Sule','Abore','08086532044'),
('LOC0139','Sule','Abore','08086532044'),
('LOC0140','Sule','Abore','08086532044')
GO


-- 5. Insert details about Type of customer into the CustomerType Table
INSERT INTO CustomerType
VALUES (1,'General'),(2,'Modern'),(3,'Ecommerce')
GO

-- 6. Insert details about the customers into the customer Table
INSERT INTO Customer(CustomerID,CustomerName,CustomerTypeID,EmailAddress,LocationID)
VALUES ('CSTD0001', 'BLESSED S.O NWADIKE GLOBAL', 3,'blessed s.o nwadike global@co.ng','LOC0001'), 
('CSTD0002', 'ZUKKY ASSOCIATES NIG LTD', 2,'zukky ASsociates nig ltd@co.ng','LOC0003'), 
('CSTD0003', '4RIVERS', 1,'4rivers@co.ng','LOC0002'), 
('CSTD0004', '7 ELEVEN WINE', 3,'7 eleven wine@co.ng','LOC0028'), 
('CSTD0005', 'ANYI PASS ENTERPRICES', 2,'anyi pASs enterprices@co.ng','LOC0122'), 
('CSTD0006', 'A.C AZUKA', 1,'a.c azuka@co.ng','LOC0068'), 
('CSTD0007', 'A.E. CHRIS ( SHOPPERS GATE)', 3,'a.e. chris ( shoppers gate)@co.ng','LOC0083'), 
('CSTD0008', 'AB AND SONS', 2,'ab and sons@co.ng','LOC0031'), 
('CSTD0009', 'CAPTAIN''S LOUNGE', 3,'captain''s lounge@co.ng','LOC0068'), 
('CSTD0010','CHUKWUAJULU NIG INTERPRIZ', 2,'chukwuajulu nig INTerpriz@co.ng','LOC0108'), 
('CSTD0011', 'AC MADUABUCHI', 2,'ac maduabuchi@co.ng','LOC0095'), 
('CSTD0012', 'ADADANT', 3,'adadant@co.ng','LOC0010'), 
('CSTD0013', 'ADD MORE VENTURE', 3,'add more venture@co.ng','LOC0095'), 
('CSTD0014', 'LOUNGE 95', 1,'lounge 95@co.ng','LOC0116'), 
('CSTD0015', 'ADOTRACO', 2,'adotraco@co.ng','LOC0012'), 
('CSTD0016', 'AFAMENT', 2,'afament@co.ng','LOC0015'), 
('CSTD0017', 'AFOKAN GLOBAL', 3,'afokan global@co.ng','LOC0084'), 
('CSTD0018', 'AJA MOTORS', 3,'aja motors@co.ng','LOC0105'), 
('CSTD0019', 'SMALL DANGOTE', 1,'small dangote@co.ng','LOC0071'), 
('CSTD0020', 'ALARAPE ENTERPRISE', 2,'alarape enterprise@co.ng','LOC0140'), 
('CSTD0021', 'ALHAJA M.O.T.K', 2,'alhaja m.o.t.k@co.ng','LOC0009'), 
('CSTD0022', 'ALHAJA RAMON AGBENI', 1,'alhaja ramon agbeni@co.ng','LOC0138'), 
('CSTD0023', 'ALPINE', 1,'alpine@co.ng','LOC0087'), 
('CSTD0024', 'AMANDIS', 3,'amandis@co.ng','LOC0044'), 
('CSTD0025', 'AMBASSADOR', 2,'ambASsador@co.ng','LOC0112'), 
('CSTD0026', 'ANBSOLITE', 2,'anbsolite@co.ng','LOC0091'), 
('CSTD0027', 'ANDERSON VENTURES', 1,'anderson ventures@co.ng','LOC0131'), 
('CSTD0028', 'ANDY YUWA', 2,'andy yuwa@co.ng','LOC0034'), 
('CSTD0029', 'GLOVO ONLINE', 2,'glovo online@co.ng','LOC0009'), 
('CSTD0030', 'ANNYWEST', 3,'annywest@co.ng','LOC0027'), 
('CSTD0031', 'ANUOLUWA STORE', 3,'anuoluwa store@co.ng','LOC0010'), 
('CSTD0032', 'ANYITEX', 3,'anyitex@co.ng','LOC0024'), 
('CSTD0033', 'ARK DESIANCE', 2,'ark desiance@co.ng','LOC0030'), 
('CSTD0034', 'ASTORIA WINE', 2,'AStoria wine@co.ng','LOC0003'), 
('CSTD0035', 'TAJMART SUPERMARKET', 1,'tajmart supermarket@co.ng','LOC0123'), 
('CSTD0036', 'AUSTINS OSAS', 3,'austins osAS@co.ng','LOC0135'), 
('CSTD0037', 'BAABA WINE SHOP', 1,'baaba wine shop@co.ng','LOC0007'), 
('CSTD0038', 'BABA IBEJI AGBENI', 2,'baba ibeji agbeni@co.ng','LOC0015'), 
('CSTD0039', 'BADE ENTERPRISE', 3,'bade enterprise@co.ng','LOC0129'), 
('CSTD0040', 'BAMBOO LOUNGE', 1,'bamboo lounge@co.ng','LOC0099'), 
('CSTD0041', 'BARRELS.NG', 2,'barrels.ng@co.ng','LOC0007'), 
('CSTD0042', 'BEEN/BLISS', 1,'been/bliss@co.ng','LOC0071'), 
('CSTD0043', 'BELT OF TRUTH', 1,'belt of truth@co.ng','LOC0078'), 
('CSTD0044', 'BENDALA EXCLUSIVE', 1,'bENDala exclusive@co.ng','LOC0070'), 
('CSTD0045', 'BENEVOLENCE', 3,'benevolence@co.ng','LOC0090'), 
('CSTD0046', 'BEN GOLD', 2,'ben gold@co.ng','LOC0094'), 
('CSTD0047', 'STRENEAGLES MART', 1,'streneagles mart@co.ng','LOC0122'), 
('CSTD0048', 'BENIK E COMPANY', 1,'benik e company@co.ng','LOC0016'), 
('CSTD0049', 'BENZOLIN VENTURES', 1,'benzolin ventures@co.ng','LOC0071'), 
('CSTD0050', 'BEST MORNIG STAR', 1,'best mornig star@co.ng','LOC0075')

GO
SET NOCOUNT OFF

-- ========================================================================================================
--  Here, we will introduce some procedures, and triggers that will automate the OMS process
-- ========================================================================================================
go
-- 1. Create an auxilliary function for left-padding Table IDs
CREATE FUNCTION dbo.LPAD (@string CHAR(4))
RETURNS CHAR(4)
AS
BEGIN
-- Left-pad 0s to ID passsed as a string
RETURN SUBSTRING('0000',1,4 -LEN(@string))+@string
END
GO

-- 1. Create sequences for Lodgement IDs
CREATE SEQUENCE UniqueIDDebit
    START WITH 1
    INCREMENT BY 1;

CREATE SEQUENCE UniqueIDCredit
    START WITH 1
    INCREMENT BY 1;
GO

-- 1. Create procedure for the Next OrderID
CREATE PROCEDURE NextOrderID
AS
BEGIN

DECLARE @NextID CHAR(13)

-- if we have existing IDs, give me the next ID
IF EXISTS(SELECT 1 FROM Invoice)
	BEGIN
		SET @NextID  = FORMAT(CURRENT_TIMESTAMP,'yyyyMMdd')+'-'+dbo.LPAD(right((SELECT MAX(OrderID) FROM Invoice),4)+1)
	END
ELSE
	BEGIN
		SET @NextID  = FORMAT(CURRENT_TIMESTAMP,'yyyyMMdd')+'-0000'
	END
PRINT ' The Next Order ID is: '+ @NextID
END
GO

-- 2. Create procedure for adding new location to the location Table
CREATE PROCEDURE AddNewLocation
@region VARCHAR(20),
@territory VARCHAR(20),
@state VARCHAR(40),
@city VARCHAR(20)

AS
BEGIN
SET NOCOUNT ON
DECLARE @CurrentID CHAR(7)
DECLARE @newID CHAR(7)

SET @CurrentID  = (SELECT MAX(LocationID) FROM location)
SET @newID = 'LOC'+dbo.LPAD(right(@CurrentID,4)+1)

INSERT INTO location (LocationID,Region,Territory,State,City)
VALUES (@newID,@region,@territory,@state,@city)

SET NOCOUNT OFF;
END
GO

-- 3. Create procedure for updating existing location
CREATE PROCEDURE UpdateLocation

@LocationID CHAR(7),
@Newname VARCHAR(20),
@identifier VARCHAR(20)

AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT 1 FROM location WHERE LocationID=@LocationID)
	BEGIN
			RAISERROR('The location does not exist',16,1);
			RETURN;
	END
	IF LEFT(@Newname,1) NOT LIKE '%[a-zA-Z]%'
	BEGIN
			RAISERROR('Invalid New Name Provided',16,1);
			RETURN;
	END

	IF @identifier NOT IN ('Region','Territory')
	BEGIN
		DECLARE @message VARCHAR(150) = 'You can only specify either region or territory but : '''+@identifier+''' was caught'
		RAISERROR(@message,16,1)
		RETURN;
	END

	-- Update the specified field
	IF @identifier = 'Region'
		BEGIN
			UPDATE location
			SET Region = @NewName
			WHERE LocationID = @LocationID;
		END
	ELSE IF @identifier = 'Territory'
		BEGIN
			UPDATE location
			SET Territory = @NewName
			WHERE LocationID = @LocationID;
		END
	SET NOCOUNT OFF;
END

GO

-- 4. Create procedure for adding/updating shippers
CREATE PROCEDURE AddNewShipper
@LocationID CHAR(7),
@ShipperFirstName VARCHAR(30),
@ShipperLastName VARCHAR(30),
@PhoneNumber CHAR(11)

AS 
BEGIN

SET NOCOUNT ON;

IF LEN(@LocationID) <> 7 OR LEFT(@LocationID, 3) <> 'LOC' OR ISNUMERIC(RIGHT(@LocationID, 4)) <> 1
BEGIN
	RAISERROR('Invalid location detected',16,1);
	RETURN;
END

ELSE IF LEFT(@PhoneNumber,3) NOT IN ('090','080','070','081','091') or LEN(@PhoneNumber)<>11
	RAISERROR('Invalid Phone Number detected',16,1);
	RETURN;

-- Check if Shipper already exists for the LocationID
IF EXISTS(SELECT 1 FROM shipper WHERE locationID = @LocationID)
	UPDATE shipper
	SET ShipperFirstName = @ShipperFirstName,
		ShipperLastName= @ShipperLastName,
		PhoneNumber = @PhoneNumber
	WHERE locationID = @LocationID;

ELSE
INSERT INTO shipper
VALUES (@LocationID,@ShipperFirstName,@ShipperLastName,@PhoneNumber);

SET NOCOUNT OFF;
END
GO

-- 5. Create procedure for adding/updating new managers to the manager Table
CREATE PROCEDURE UpdateManager
@FirstName VARCHAR(30),
@LastName VARCHAR(30),
@DateofBirth DATE,
@Territory VARCHAR(20)
AS
BEGIN
SET NOCOUNT ON;

 -- Check if Manager for Territory exists
IF EXISTS(SELECT 1 FROM Manager WHERE Territory=@Territory)
BEGIN
	-- Update existing Manager
	UPDATE manager
	SET firstName=@FirstName,LAStName=@LAStName,Dateofbirth=@DateofBirth,DateJoined=CURRENT_TIMESTAMP
	WHERE territory = @Territory;
END
ELSE
BEGIN
-- Insert new Manager
	INSERT INTO manager
	VALUES (@Territory,@FirstName,@LastName,@DateofBirth,DEFAULT);
END

SET NOCOUNT OFF;
END

GO

-- 6. Create procedure for adding new products to the product Table
CREATE PROCEDURE AddNewProduct
@ProductDescription VARCHAR(50),
@Brand VARCHAR(20),
@PricePerCase DECIMAL(18,2),
@UnitCost DECIMAL(18,2),
@InitialQTY INT

AS
BEGIN

SET NOCOUNT ON;

IF @PricePerCase<=0
BEGIN
	RAISERROR('Invalid Price Provided',16,1);
	RETURN;
END;

IF @UnitCost<=0
BEGIN
	RAISERROR('Invalid Cost Provided',16,1);
	RETURN;
END;

IF @InitialQTY<0
BEGIN
	RAISERROR('Quantity can not be negative',16,1);
	RETURN;
END;

DECLARE @CurrentID CHAR(7) = (SELECT max(ProductID) FROM product)
DECLARE @newID CHAR(7) = 'PRD'+dbo.LPAD(right(@CurrentID,4)+1);

INSERT INTO product (ProductID,[Product Description],Brand,PricePerCase,UnitCost,QTY)
VALUES (@newID,@ProductDescription,@Brand,@PricePerCase,@UnitCost,@InitialQTY);

SET NOCOUNT OFF;
END
GO

-- 7. Create procedure for updating product prices in the product Table
CREATE PROCEDURE UPdatePrice
@productID CHAR(20),
@NewPrice DECIMAL(18,2)

AS
BEGIN
	SET NOCOUNT ON;

IF @NewPrice<0
BEGIN
	RAISERROR('The new price for the product can not be negative',16,1);
	RETURN;
END;

IF EXISTS(SELECT 1 FROM product WHERE productID = @productID)
	BEGIN
		UPDATE product
		SET PricePerCase = @NewPrice
		WHERE productID = @productID;
	END
ELSE
	BEGIN
		RAISERROR('The product you entered does not exist',16,1);
		RETURN;
	END
SET NOCOUNT OFF
END
GO

-- 8. Create procedure for updating product cost in the inventory Table
CREATE PROCEDURE UPdateCost
@productID CHAR(7),
@NewCost DECIMAL(18,2)

AS
BEGIN

SET NOCOUNT ON;

IF @NewCost<0
BEGIN
	RAISERROR('The cost can not be negative',16,1);
	RETURN;
END;
IF EXISTS(SELECT 1 FROM product WHERE productID = @productID)
BEGIN
	UPDATE product
	SET UnitCost = @NewCost
	WHERE productID = @productID;
END
ELSE
BEGIN
	RAISERROR('The product you entered does not exist',16,1);
	RETURN;
END
SET NOCOUNT OFF;
END
GO

-- 9. Create procedure for updating product quantity in the inventory Table
CREATE PROCEDURE NewQuantity
@productID CHAR(20),
@NewQty INT

AS
BEGIN

SET NOCOUNT ON;

IF @NewQty<0
BEGIN
	RAISERROR('Quantity provided is invalid',16,1);
	RETURN;
END;

IF EXISTS(SELECT 1 FROM product WHERE productID = @productID)
	BEGIN
		UPDATE product
		SET QTY = QTY+@NewQty
		WHERE productID = @productID;
	END
ELSE
	BEGIN
		RAISERROR('We do not have such product',16,1);
		RETURN;
	END
SET NOCOUNT OFF;
END
GO

-- 10. CREATE procedure for adding new customer to the customer TABLE
CREATE PROCEDURE AddNewCustomer
@Name VARCHAR(50),
@cstypeID INT,
@LocationID VARCHAR(20),
@EmailAddress VARCHAR(50)

AS
BEGIN
SET NOCOUNT ON;

IF LEN(@LocationID) <> 7 OR LEFT(@LocationID, 3) <> 'LOC' OR ISNUMERIC(RIGHT(@LocationID, 4)) <> 1
BEGIN
	RAISERROR('Invalid location detected',16,1);
	RETURN;
END;

DECLARE @CurrentID CHAR(8)
DECLARE @newID CHAR(8)

SET @CurrentID  = (SELECT max(CustomerID) FROM Customer)
SET @newID = 'CSTD'+dbo.LPAD(right(@CurrentID,4)+1)

INSERT INTO customer (CustomerID,CustomerName,CustomerTypeID,EmailAddress,LocationID)
VALUES (@newID,@Name,@cstypeID,@EmailAddress,@LocationID);

SET NOCOUNT OFF;
END
GO

-- 11. Create procedure for removing customers (inactive/problematic) From the customer Table
CREATE PROCEDURE DeListCustomer
@CustomerID CHAR(8)
AS
BEGIN
SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM Customer WHERE CustomerID=@CustomerID)
	BEGIN
		DELETE FROM Customer
		WHERE CustomerID = @customerID
	END
ELSE 
	BEGIN
	RAISERROR('We do not have information about this customer',16,1)
	RETURN;
	END
SET NOCOUNT OFF;
END
GO

-- 12. Create a procedure for raising orders
CREATE PROCEDURE RaiseOrder
    @OrderID VARCHAR(20),
    @CustomerID VARCHAR(20),
    @LocationID VARCHAR(20),
    @ProductCode VARCHAR(20),
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Amount DECIMAL(18,2);
    SELECT @Amount = PricePerCase * @Quantity
    FROM Product
    WHERE ProductID = @ProductCode;

    -- Check if the order ID has been used for raising a different order before
    IF EXISTS(SELECT 1 FROM Orders WHERE OrderID = @OrderID AND CustomerID <> @CustomerID)
    BEGIN
        DECLARE @ErrorMessage VARCHAR(100) = CONCAT('The orderID: ', @OrderID, ' has been used for another order');
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END

	-- Check if the order is valid
    IF LEN(@OrderID) <> 13 OR ISDATE(LEFT(@OrderID, 8)) <> 1
    BEGIN
        RAISERROR('Invalid Order ID detected', 16, 1);
        RETURN;
    END;

	-- Check if the customer code is valid
    IF LEN(@CustomerID) <> 8 OR LEFT(@CustomerID,4)<>'CSTD' OR ISNUMERIC(RIGHT(@CustomerID,4))<>1
    BEGIN
        RAISERROR('Invalid customer code detected', 16, 1);
        RETURN;
    END;

	-- Check if the product code is valid
    IF LEN(@ProductCode) <> 7 OR LEFT(@ProductCode,3)<>'PRD' OR ISNUMERIC(RIGHT(@ProductCode,4))<>1
    BEGIN
        RAISERROR('Invalid product code detected', 16, 1);
        RETURN;
    END;

	IF LEN(@LocationID) <> 7 OR LEFT(@LocationID, 3) <> 'LOC' OR ISNUMERIC(RIGHT(@LocationID, 4)) <> 1
	BEGIN
		RAISERROR('Invalid Location detected',16,1);
		RETURN;
	END;

    -- Check if the Quantity is valid
    IF @Quantity < 0
    BEGIN
        RAISERROR('Invalid quantity supplied', 16, 1);
        RETURN;
    END;

    -- Check if the Customer exists at the specified location
    IF NOT EXISTS(SELECT 1 FROM Customer WHERE CustomerID = @CustomerID AND LocationID = @LocationID)
    BEGIN
        RAISERROR('You need to register the customer for the location before raising the order', 16, 1);
        RETURN;
    END;

    -- Check if the product already exists on the order
    IF EXISTS(SELECT 1 FROM Orders WHERE OrderID = @OrderID AND ProductID = @ProductCode AND CustomerID = @CustomerID)
    BEGIN
        UPDATE Orders
        SET Qty = @Quantity, Amount = @Amount,
            DateofOrder = (SELECT MIN(DateofOrder) FROM Orders WHERE OrderID = @OrderID AND ProductID = @ProductCode)
        WHERE OrderID = @OrderID AND ProductID = @ProductCode;
    END
    ELSE
    BEGIN
        INSERT INTO Orders (OrderID, CustomerID, LocationID, ProductID, Qty, Amount)
        VALUES (@OrderID, @CustomerID, @LocationID, @ProductCode, @Quantity, @Amount);

        -- Then, document the orderID
        IF NOT EXISTS(SELECT 1 FROM Invoice WHERE OrderID = @OrderID)
        BEGIN
            INSERT INTO Invoice(OrderID)
            VALUES (@OrderID);
        END;
    END;

    SET NOCOUNT OFF;
END;
GO

-- 13. Create a procedure for Canceling orders
CREATE PROCEDURE CancelOrder
@orderID VARCHAR(20)

AS
BEGIN

SET NOCOUNT ON;
-- Check if the order is valid
IF LEN(@OrderID) <> 13 OR ISDATE(LEFT(@OrderID, 8)) <> 1
BEGIN
	RAISERROR('Invalid Order ID detected', 16, 1);
	RETURN;
END;

-- Check if the order is outstanding
IF EXISTS(SELECT 1 FROM Invoice WHERE OrderID=@orderID and Status<>'Billed')
BEGIN
	-- Delete the order from the Orders table
	DELETE FROM orders
	WHERE OrderID=@orderID;
END
ELSE
	BEGIN
	RAISERROR('This order has already been billed or does not exist',16,1);
	RETURN;

END
SET NOCOUNT OFF;
END
GO

-- 14. CREATE procedure for Approving credit limit to customers
CREATE PROCEDURE CreditLimitApprover
@CustomerID CHAR(8),
@Amount DECIMAL(18,2)

AS 
BEGIN
SET NOCOUNT ON;
	
	-- Check if the customer exists
	IF NOT EXISTS(SELECT 1 FROM Customer WHERE CustomerID=@CustomerID)
	BEGIN
		RAISERROR('Information about this customer is not found',16,1);
		RETURN;
	END

	-- Check if the amount is non-negative
	ELSE IF @Amount<0
	BEGIN
		RAISERROR('Amount can not be negative',16,1);
		RETURN;
	END
	ELSE
	BEGIN
		-- Update the customer's credit limit
		UPDATE Customer
		SET CreditLimit = @Amount
		WHERE CustomerID = @customerID;
	END

SET NOCOUNT OFF;
END

GO

-- 15. Create procedure for storing customer payments
CREATE PROCEDURE CustomerPayment
@CustomerID CHAR(8),
@Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the amount is non-negative
    IF @Amount < 0
    BEGIN
        RAISERROR('Amount cannot be negative', 16, 1);
        RETURN;
    END
    ELSE
    BEGIN
        -- Insert payment record
        INSERT INTO payment (CustomerID, AmountPaid)
        VALUES (@CustomerID, -1*@Amount);
		PRINT 'Payment Succesful'
    END

    SET NOCOUNT OFF;
END
GO

-- 16. Create an auxiliary procedure for updating customer balance
CREATE PROCEDURE UpdateBalance
@CustomerID CHAR(8),
@Amount DECIMAL (18,2)

AS
BEGIN

SET NOCOUNT ON;

-- Update customer Account using the Amount
UPDATE Customer
SET AccountBalance =AccountBalance+ @Amount
WHERE CustomerID = @customerID;

SET NOCOUNT OFF;
END
GO

--17. Create a procedure for Billing order

CREATE PROCEDURE BillOrder
@orderID CHAR(13)

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerID CHAR(8),@TotalAmount DECIMAL(18, 2), @AllAvailable BIT = 1,@balance DECIMAL (18,2),
	@approvablebalance DECIMAL(18,2), @creditlimit DECIMAL(18,2)

    -- Calculate total amount and check product availability on the order
    SELECT @TotalAmount = SUM(o.Qty * p.PricePerCase),
           @AllAvailable = CASE WHEN MIN(p.Qty - o.Qty) < 0 THEN 0 ELSE 1 END
    FROM orders o
    JOIN product p ON o.ProductID = p.ProductID
    WHERE o.OrderID = @orderID;

	-- Check if the order ID is valid
	IF LEN(@OrderID)<>13 OR ISDATE(LEFT(@OrderID,8))<>1
	BEGIN
		RAISERROR('Invalid OrderID',16,1);
		RETURN;
	END

    -- Check if the order exists or has been billed
    IF EXISTS (SELECT 1 FROM Invoice WHERE OrderID = @orderID AND Status ='Billed')
    BEGIN
        RAISERROR('This order has already been billed', 16, 1);
        RETURN;
    END
	--Check if the order is not in the outsanding list
	IF NOT EXISTS (SELECT 1 FROM orders WHERE OrderID = @orderID)
    BEGIN
        RAISERROR('This order has not been raised for billing', 16, 1);
        RETURN;
    END

    -- Check if any of the products is not available
    IF @AllAvailable = 0
    BEGIN
        UPDATE Invoice 
		SET status = 'On hold due to OOS', Amount = @TotalAmount
		WHERE OrderID = @orderID;

		RAISERROR('Some of the products are currently out of stock.', 16, 1);
        RETURN;
    END

    -- Obtain customer balance and credit status
    SELECT @CustomerID = CustomerID,
           @balance = AccountBalance,
           @creditlimit = CreditLimit
    FROM Customer
    WHERE CustomerID = (SELECT DISTINCT CustomerID FROM orders WHERE orderID = @orderID);

    SET @approvablebalance = @creditlimit - @balance - @TotalAmount;

    -- Process the order if all products are available
    BEGIN TRANSACTION;

    -- Insert sales data and update product quantities
    INSERT INTO sales (orderid, productid, CustomerID, [Qty Sold], [Qty Net], [Avalaible Qty], [Unit Price], [Selling Amount], VAT, [Unit Cost], [Total Cost], [Profit Margin], [%Profit])
    SELECT @orderID, o.ProductID, @CustomerID, o.Qty, o.Qty, p.Qty - o.Qty, p.PricePerCase,
           o.Qty * p.PricePerCase, 0.075 * (o.Qty * p.PricePerCase), p.UnitCost, o.Qty * p.UnitCost,
           ((o.Qty * p.PricePerCase - o.Qty * p.UnitCost) / (o.Qty * p.PricePerCase)),
           ((o.Qty * p.PricePerCase - o.Qty * p.UnitCost) / (o.Qty * p.UnitCost))
    FROM orders o
    JOIN product p ON o.ProductID = p.ProductID
    WHERE o.OrderID = @orderID;

    -- Update product QTYs
    UPDATE p
    SET p.Qty = p.Qty - o.Qty
    FROM product p
    JOIN orders o ON o.ProductID = p.ProductID
    WHERE o.OrderID = @orderID;

    -- Confirm if the order can go through using the available balance
    IF @balance <= -1 * @TotalAmount OR @approvablebalance >= 0
    BEGIN
        COMMIT TRANSACTION;

        UPDATE Invoice 
		SET status = 'Billed',
		Amount = @TotalAmount 
		WHERE OrderID = @orderID;

        EXEC UpdateBalance @CustomerID, @TotalAmount;

        DECLARE @desc VARCHAR(15);
        SET @desc = 'Sale: ' + dbo.LPAD(cast(NEXT VALUE FOR UniqueIDDebit AS CHAR(4)));
		SET @balance = (SELECT AccountBalance FROM Customer WHERE CustomerID=@CustomerID)
        INSERT INTO Lodgement (CustomerID, Debit, AccountBalance, Description)
        VALUES (@CustomerID, @TotalAmount, @balance, @desc);

        PRINT 'Successful!';
    END
    ELSE
    BEGIN

        ROLLBACK TRANSACTION;

		UPDATE invoice
        SET status = 'On hold due to insufficient balance',
		Amount = @TotalAmount 
		WHERE OrderID = @orderID;

		RAISERROR('The customer does not have sufficient balance to invoice this order', 16, 1);
		RETURN
    END

    SET NOCOUNT OFF;
END;
GO

-- 18. Create a procedure for returned orders
CREATE PROCEDURE ReversalProc
@orderID CHAR(13),
@prodcode CHAR(7),
@returnedQty INT,
@reasonforreversal VARCHAR(100)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @custcode CHAR(8),@returnedamount DECIMAL(18,2),@unitprice DECIMAL(18,2),
            @unitcost DECIMAL(18,2),@productQty INT,@prodbalance INT,@orderQTY INT,
            @Qtynet INT,@amount DECIMAL(18,2);

    -- Check if the order has been billed
    IF EXISTS(SELECT 1 FROM invoice WHERE orderid = @orderID AND status = 'Billed')
    BEGIN

        -- Get necessary data for calculations
        SELECT @custcode = CustomerID,
               @unitcost = s.[Unit Cost],
               @unitprice = s.[Unit Price],
               @orderQTY = s.[Qty Net],
               @productQty = p.QTY
        FROM sales s
        INNER JOIN product p ON s.ProductID = p.ProductID
        WHERE s.orderID = @orderID AND s.ProductID = @prodcode;

        -- Calculate reversal details
        SET @Qtynet = @orderQTY - @returnedQty;
        SET @returnedamount = @returnedQty * @unitprice;
        SET @prodbalance = @productQty + @returnedQty;
		SET @amount = @Qtynet*@unitprice

		BEGIN TRANSACTION;
        -- Returned the amount into customer balance
		BEGIN TRY
        UPDATE Customer
        SET AccountBalance -= @returnedamount
        WHERE CustomerID = @custcode;

        -- Update sales table
        UPDATE sales
        SET [Qty Returned] += @returnedQty,
            [Qty Net] = @Qtynet,
            [Avalaible Qty] = @prodbalance,
            [Selling Amount] = CASE WHEN @amount > 0 THEN @amount ELSE 0 END,
            VAT = CASE WHEN @amount > 0 THEN 0.075 * @amount ELSE 0 END,
            [Total Cost] = CASE WHEN @amount > 0 THEN @Qtynet * @unitcost ELSE 0 END,
            [Profit Margin] = CASE WHEN @amount > 0 THEN (@amount - @Qtynet * @unitcost) * 100 / @amount ELSE 0 END,
            [%Profit] = CASE WHEN @amount > 0 THEN (@amount - @Qtynet * @unitcost) * 100 / (@Qtynet * @unitcost) ELSE 0 END
        WHERE orderid = @orderID AND ProductID = @prodcode;

        -- Update the product table
        UPDATE product
        SET QTY = @prodbalance
        WHERE ProductID = @prodcode;

		-- Update Invoice Amount
        UPDATE Invoice
        SET Amount -= @returnedamount
        WHERE OrderID = @orderID;

        -- Insert into Lodgement Table
        INSERT INTO Lodgement (CustomerID, Credit, AccountBalance, Description)
        VALUES (@custcode, -1 * @returnedamount, (SELECT AccountBalance FROM Customer WHERE CustomerID = @custcode), 'Reversal on ' + @orderID);

        -- Insert into Reversal Table
        INSERT INTO Reversal (OrderID, Prodcode, [QTY returned], Amount, Reason)
        VALUES (@orderID, @prodcode, @returnedQty, @returnedamount, @reasonforreversal);
		END TRY

		BEGIN CATCH
        -- Rollback the transaction if total QTY is negative (Bad Transaction)
        IF @Qtynet < 0 OR @@ERROR<>0
		BEGIN
			RAISERROR('Invalid Transaction', 16, 1);
            ROLLBACK TRANSACTION;
			RETURN;
		END
		END CATCH;
        COMMIT TRANSACTION;
		
    END
    ELSE
    BEGIN
        RAISERROR('Reversal failed. Order has not been billed yet.', 16, 1);
    END

    SET NOCOUNT OFF;
END
GO

-- 19. CREATE a procedure for writing off customers Debts
CREATE PROCEDURE CalculateRebate
AS
BEGIN
    SET NOCOUNT ON;
	
    DECLARE @CustomerID CHAR(8),@TotalPurchases DECIMAL(18, 2),@RebateRate DECIMAL(18, 2),@RebateAmount DECIMAL(18, 2),
    @TotalQty INT,@balance DECIMAL(18, 2),@StartofPreviousMonth DATE,@EndofPreviousMonth DATE;

	--Obtain Start and end of the previous month
	SET @StartofPreviousMonth = DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())-1,0)
	SET @EndofPreviousMonth = DATEADD(DAY,-1,DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),0))

    -- Create a cursor to loop through all customers that purchased in the previous month
    DECLARE customerCursor CURSOR FOR
        SELECT DISTINCT CustomerID
        FROM sales
        WHERE TransactionDate BETWEEN @StartofPreviousMonth AND @EndofPreviousMonth;

    -- Open the cursor
    OPEN customerCursor;

    -- Fetch the first row from the cursor
    FETCH NEXT FROM customerCursor INTO @CustomerID;

    -- Start looping through each customer
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Retrieve total QTY for the current customer
        SELECT @TotalQty = SUM([Qty Net]),
               @TotalPurchases = SUM([Selling Amount])
        FROM sales
        WHERE CustomerID = @CustomerID
        AND TransactionDate BETWEEN @StartofPreviousMonth AND @EndofPreviousMonth

        -- Determine rebate rate based on total QTY
        SET @RebateRate = CASE
            WHEN @TotalQty >= 1000 THEN 0.05 -- 5% rebate for total QTY >= 1000
            ELSE 0 -- No rebate if total QTY < 1000
        END;

        -- Calculate rebate amount if it has not been computed for each customer
        IF NOT EXISTS (
            SELECT 1
            FROM RebateDetail
            WHERE CustomerID = @CustomerID
            AND PurchaseMonth BETWEEN @StartofPreviousMonth AND @EndofPreviousMonth
            AND RebateStatus = 'processed'
        )
        BEGIN
            SET @RebateAmount = @TotalPurchases * @RebateRate;

            SET @balance = (SELECT AccountBalance FROM customer WHERE customerID = @CustomerID) - @RebateAmount;

            -- Store rebate amount for the current customer
            INSERT INTO RebateDetail(CustomerID,PurchASeMonth, [Total Purchase], [Total Qty], RebateAmount, RebateStatus)
            VALUES (@CustomerID,@StartofPreviousMonth, @TotalPurchases, @TotalQty, @RebateAmount, 'processed');

            IF @RebateAmount > 0
            BEGIN
                -- Update customer balance with the rebate amount
                UPDATE customer
                SET AccountBalance = @balance
                WHERE CustomerID = @CustomerID;

                -- Log the transaction into the Lodgement table
                INSERT INTO Lodgement (CustomerID, Credit, AccountBalance, Description)
                VALUES (@CustomerID, -1*@RebateAmount, @balance, 'Rebate for the month: ' + DATENAME(MONTH,@StartofPreviousMonth));
            END
        END;

        -- Fetch the next row from the cursor
        FETCH NEXT FROM customerCursor INTO @CustomerID;
    END;

    -- Close and deallocate the cursor
    CLOSE customerCursor;
    DEALLOCATE customerCursor;

    SET NOCOUNT OFF;
END;
GO

-- 20. Create a procedure for writing off customers Debts
CREATE PROCEDURE WriteOffDebt
@CustomerID CHAR(8),
@Amount DECIMAL(18,2)

AS
BEGIN

SET NOCOUNT ON;
-- Check if the amount is non-negative
IF @Amount < 0
BEGIN
    RAISERROR('Amount cannot be negative', 16, 1);
    RETURN;
END

DECLARE @balance DECIMAL(18,2)
SET @balance = (SELECT AccountBalance FROM customer WHERE customerID = @CustomerID) - @Amount

IF @balance>=0
BEGIN
	UPDATE Customer
	SET AccountBalance = @balance
	WHERE CustomerID = @customerID;

	INSERT INTO Lodgement (CustomerID,Credit,AccountBalance, Description)
	VALUES (@CustomerID,-1*@amount,@balance,'Write-Off');
END
ELSE
BEGIN
RAISERROR('The customer is not owing',16,1);
RETURN;
END

SET NOCOUNT OFF;
END
GO

-----------------------------------------------------------------------=================================
-- 1. Create a Trigger for documenting removed customers
CREATE TRIGGER CustomerDelete
    ON Customer
    AFTER DELETE
    AS
    BEGIN

	INSERT INTO customer_audit(CustomerID,CustomerName,CustomerTypeID,EmailAddress,
	DateRegistered,LocationID,CreditLimit,AccountBalance)
	SELECT * FROM deleted

    END
GO

-- 2. Create a Trigger for updating customer balance upon receiving payment
CREATE TRIGGER BalanceUpdate
ON payment
AFTER INSERT
AS
BEGIN

DECLARE @CustomerID CHAR(8)
DECLARE @amount DECIMAL(18,2)

SET @customerID=(SELECT customerID FROM inserted)
SET @amount=(SELECT AmountPaid FROM inserted)

EXEC UpdateBalance @customerID,@amount

END
GO

-- 3. Create a Trigger for logging customer balance upon receiving payment

CREATE TRIGGER UpdateLogPayment
ON payment
AFTER INSERT
AS
BEGIN
    INSERT INTO Lodgement (CustomerID, Credit, AccountBalance, Description)
    SELECT
        ins.customerID,
        ins.AmountPaid,
        cus.AccountBalance,
        'Receipt: ' + dbo.LPAD(cast(NEXT VALUE FOR UniqueIDCredit as varchar(4))) AS Description
    FROM
        inserted ins
    INNER JOIN
        customer cus ON ins.customerID = cus.customerID;
END
GO


-- 4. Create a Trigger for logging deleted orders
CREATE TRIGGER OrderDelete
    ON orders
    AFTER DELETE

    AS
    BEGIN
		SET NOCOUNT ON
		INSERT INTO orders_audit(OrderID,CustomerID,LocationID,DateofOrder,ProductID,Qty,Amount)
		SELECT * FROM deleted;
		SET NOCOUNT OFF
    END

GO
--Create a procedure for the pending Order

CREATE PROCEDURE PendingOrdersList
AS
BEGIN

    -- This returns orders that have not been billed yet
    SELECT o.OrderID, c.customerID, c.CustomerName,l.City AS Location,o.DateofOrder,p.[Product Description],o.QTY,o.Amount, SUM(o.Amount) OVER(PARTITION BY o.OrderID) TotalAmount,
	SUM(o.Qty) OVER(PARTITION BY o.OrderID) TotalQty,i.Status
    FROM dbo.Orders AS o
	JOIN Customer c
	ON o.CustomerID = c.CustomerID
    JOIN Invoice i ON o.OrderID = i.OrderID
	JOIN location l
	ON l.LocationID=o.LocationID
	JOIN product p
	ON p.ProductID= o.ProductID
    WHERE i.Status <> 'Billed'
	ORDER BY o.OrderID

END

GO


-- Create a procedure for the Aging Analysis
CREATE PROCEDURE AgingReport

AS
BEGIN

WITH AgingBuckets AS (
    SELECT
        c.CustomerID,
        SUM(CASE WHEN DATEDIFF(day, l.ValueDate, GETDATE()) <= 30 THEN l.Credit + l.Debit ELSE 0 END) AS [0-30 days],
        SUM(CASE WHEN DATEDIFF(day, l.ValueDate, GETDATE()) > 30 AND DATEDIFF(day, l.ValueDate, GETDATE()) <= 60 THEN l.Credit + l.Debit ELSE 0 END) AS [31-60 days],
        SUM(CASE WHEN DATEDIFF(day, l.ValueDate, GETDATE()) > 60 AND DATEDIFF(day, l.ValueDate, GETDATE()) <= 90 THEN l.Credit + l.Debit ELSE 0 END) AS [61-90 days],
        SUM(CASE WHEN DATEDIFF(day, l.ValueDate, GETDATE()) > 90 AND DATEDIFF(day, l.ValueDate, GETDATE()) <= 180 THEN l.Credit + l.Debit ELSE 0 END) AS [91-180 days],
        SUM(CASE WHEN DATEDIFF(day, l.ValueDate, GETDATE()) > 180 THEN l.Credit + l.Debit ELSE 0 END) AS [>180 days]
    FROM Customer c
	LEFT JOIN Lodgement l
	ON l.CustomerID= c.CustomerID
    GROUP BY c.CustomerID
)

SELECT c.CustomerID, c.CustomerName, ct.Description AS Channel, lo.Region,m.Territory,
    m.FirstName + ' ' + m.LastName AS [Territory Manager],c.CreditLimit,c.AccountBalance AS Balance,
    ab.[0-30 days],ab.[31-60 days],ab.[61-90 days],ab.[91-180 days],ab.[>180 days]
FROM Customer c
JOIN AgingBuckets ab ON c.CustomerID = ab.CustomerID
JOIN Location lo ON c.LocationID = lo.LocationID
JOIN CustomerType ct ON c.CustomerTypeID = ct.CustomerTypeID
JOIN Manager m ON m.Territory = lo.Territory

END

GO

-- First Create an Index on the PurchaseMonth column
CREATE INDEX RebateDetail_PurchaseMonth ON RebateDetail (PurchaseMonth);
GO

-- Create a function for Report on Rebate

CREATE PROCEDURE RebateReport 
@Year CHAR(4),@Month VARCHAR(20)

AS
BEGIN
	-- Check if the input month is valid
	IF @Month NOT IN ('January','February', 'March', 'April', 'May', 'June',
					'July', 'August', 'September', 'October', 'November', 'December')
	BEGIN
		--If @Month is not in the correct format, return error
		RAISERROR('Month Name is invalid',16,1)
        RETURN;
	END

	-- Check if the input year is valid
	IF NOT ISNUMERIC(@Year) = 1 OR LEN(@Year) <>4
	BEGIN
		--If @Year is not in the correct format, return error
		RAISERROR('Year entered is invalid',16,1)
        RETURN;
	END

	-- Check if the period specified corresponds to valid data in the RebateDetail table
    IF NOT EXISTS (SELECT 1 FROM RebateDetail WHERE DATENAME(MONTH,PurchaseMonth) = @Month AND YEAR(PurchaseMonth)=@Year)
    BEGIN
    -- If @Month does not correspond to valid data, return an empty result set
	RAISERROR('There is no data for this period',16,1);
        RETURN;
    END

    -- If the period is valid, proceed with the query

	SELECT * FROM RebateDetail
	WHERE DATENAME(MONTH,PurchaseMonth) = @Month AND YEAR(PurchaseMonth)=@Year

END

Go

-- Compute Sales Report for the Manager

CREATE PROCEDURE SalesReport
@From DATE, @To DATE

AS
BEGIN

	-- Validate @To is not less than @From
	IF @From > @To
	BEGIN
		RAISERROR('The order of the dates is not correct',16,1)
		RETURN;
	END
	ELSE
	BEGIN

SELECT 
    s.TransactionDate,
    c.CustomerID,
    c.CustomerName,
    ct.Description AS Channel,
    l.Territory,
    l.Region,
    m.FirstName + ' ' + m.LastName AS Manager,
    p.[Product Description],
    p.Brand,
    s.[Qty Returned],
    s.[Qty Sold],
    s.[Qty Net],
    s.[Avalaible Qty],
    s.[Unit Price],
    s.[Selling Amount],
    s.VAT,
    s.[Unit Cost],
    s.[Total Cost],
    s.[Profit Margin],
    s.[%Profit]
FROM sales s
JOIN orders o ON s.OrderID = o.OrderID AND s.ProductID=o.ProductID
JOIN Customer c ON c.CustomerID = o.CustomerID
JOIN CustomerType ct ON ct.CustomerTypeID = c.CustomerTypeID
JOIN location l ON l.LocationID = o.LocationID
JOIN manager m ON m.Territory = l.Territory
JOIN  product p ON p.ProductID = s.ProductID
WHERE s.TransactionDate BETWEEN '2024-04-25' AND DATEADD(DAY, 1, '2024-04-27')
ORDER BY  c.CustomerID;

	END

END

Go

CREATE PROCEDURE ReversalReport

AS
BEGIN
		SELECT c.CustomerName,p.[Product Description],r.[QTY returned],r.Amount,r.DateReturned,r.Reason,ct.Description as Channel,
		l.Territory,l.Region,m.FirstName+' '+m.LastName AS Manager
		FROM Reversal r
		JOIN orders o ON r.OrderID = o.OrderID AND o.ProductID=r.Prodcode
		JOIN Customer c ON c.LocationID = o.LocationID
		JOIN location l ON l.LocationID = c.LocationID
		JOIN manager m ON m.Territory= l.Territory
		JOIN CustomerType ct ON ct.CustomerTypeID = c.CustomerTypeID
		JOIN product p ON p.ProductID = o.ProductID

END

Go


CREATE PROCEDURE GetInventory
AS
BEGIN

DECLARE @StartOfDay DATETIME = DATEADD(HOUR, 6,CAST(CONVERT(DATE, SYSUTCDATETIME()) AS DATETIME));
SELECT 
    p.ProductID,
    p.[product description],
    p.QTy AS CurrentBalance,
    ISNULL(inv.QTY, 0) AS OpeningBalance,
    CASE 
        WHEN ISNULL(inv.QTY, 0) = 0 THEN 0 
        ELSE ISNULL(inv.QTY, 0) - p.QTy 
    END AS QuantitySoldToday 
FROM 
    product p
LEFT JOIN 
    (SELECT ProductID, QTY FROM product FOR SYSTEM_TIME AS OF @StartOfDay) AS inv
ON 
    inv.ProductID = p.ProductID;



END

GO

--Create a procedure for generating Invoice

CREATE PROCEDURE GetInvoice @CustomerID CHAR(8),@From DATE, @To DATE
AS
BEGIN

	-- Validate @To is not less than @From
	IF @From > @To
	BEGIN
		RAISERROR('The order of the dates is not correct',16,1)
		RETURN;
	END
	IF NOT EXISTS(SELECT 1 FROM Customer WHERE CustomerID=@CustomerID)
	BEGIN
	RAISERROR('We do not have such custormer in our database',16,1)
		RETURN;
	END
	ELSE
	BEGIN
		-- Return the invoice for the customer
	   SELECT c.CustomerName,l.ValueDate,l.Debit,l.Credit,l.AccountBalance,l.Description FROM Lodgement l
	   JOIN Customer c
	   ON l.CustomerID=c.CustomerID
		WHERE l.CustomerID=@CustomerID 
		AND l.ValueDate BETWEEN @From AND DATEADD(DAY,1,@To)
	END

END

GO