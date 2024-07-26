-- Run the below before running any of the procedures
USE OMS;
GO
--===================================================
-- 1. Business Partner Management
--===================================================
-- Add a new business location
EXEC AddNewLocation
@region = 'SOUTH',
@territory='OWERRI',     
@state = 'Imo',
@city='Nchi Ise'
GO

-- Update a location details
EXEC UpdateLocation
@LocID='LOC',
@Newname='kkk',
@identifier = 'Region'
GO

-- Add New Shipper Details
EXEC AddNewShipper
@LocationID,
@ShipperFirstName,
@ShipperLastName,
@PhoneNumber
GO

-- Update Territory manager details
EXEC UpdateManager
@FirstName,
@LastName,
@DateofBirth,
@Territory
GO

-- Add New Customer
EXEC AddNewCustomer
@Name='02 LOUNGE',         
@cstypeID=1,
@LocationID='LOC0095',
@EmailAddress='02 lounge@co.ng'
GO

-- Remove a customer from the Database
EXEC DeListCustomer 
@CustomerID = 'CSTD0051' 
GO
--====================================================
-- 2. Order To Cash Management
--====================================================
--Generate InvoiceID/OrderID
EXEC NextOrderID

--Raise an Order
EXEC RaiseOrder
@OrderID= '20240501-0002',
@CustomerID='CSTD0022',
@LocationID='LOC0138',
@productcode='PRD0015',                      -- Working Fine
@Quantity=820
GO

-- Cancel Orders that have not been billed
EXEC CancelOrder
@orderID ='20240429-0000'    -- Working Fine
GO

-- Raise an invoice for an order
EXEC BillOrder 
@orderID ='20240501-0002'   -- Working Fine
GO

-- Record a return sales
EXEC ReversalProc
@orderID='20240501-0002',
@prodcode='PRD0015',
@returnedQty=820,                           
@reasonforreversal='Shipper had accident'
GO
--=====================================================
-- 3. Inventory Management
--=====================================================
-- Update Cost for a product
EXEC UpdateCost
@productID,
@NewCost
GO

-- Update price for a product
EXEC UpdatePrice
@productID,
@NewPrice
GO

-- Add newly introduced product details to the inventory, after production
EXEC AddNewProduct
@ProductDescription,
@Brand,
@PricePerCase,
@UnitCost,
@QTY
GO

-- Enter New Quantity for a product, after production
EXEC NewQuantity
@productID='PRD0004',   --- Working Fine
@NewQty=200
GO
--========================================================
-- 4. Financials
--========================================================
-- Show Invoices for a customer
EXEC GetInvoice
@CustomerID,
@From,
@To
Go

-- Record customer Payment
EXEC CustomerPayment
@CustomerID='CSTD0007',  
@Amount=6229550.00

-- Approve CL for customer
EXEC CreditLimitApprover
@customerID='CSTD0016',                   
@Amount=9878500.00
GO

-- Write-off debt for customer
EXEC WriteOffDebt 
@customerID='CSTD0051',@Amount=9000
GO

--=========================================================
-- 5. Reports
--=========================================================
--Inventory report
EXEC GetInventory

-- Compute Rebate for previous Month
EXEC CalculateRebate
GO

-- Rebate Report for a specific Month
EXEC RebateReport 
@Year='2024', @Month='April'
GO

-- Show Outstanding Orders
EXEC PendingOrdersList
GO

-- Credit Aging Report
EXEC AgingReport
GO

-- Sales Report
EXEC SalesReport
@From='2024-04-25', @To='2024-04-27'
GO

-- Reversal Report
EXEC ReversalReport

