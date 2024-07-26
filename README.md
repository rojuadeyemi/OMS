# Order Management System (OMS)

In this project, an OMS was designed, to manage and streamline the tracking of orders from inception to fulfillment and managing the people, processes and data connected to the order as it moves through its lifecycle, utilizing T-SQL for database operations and automation.

## Schema Diagram 
![schema](images/OMS_Diagram.png)

## Key Features 
* Stored Procedures and Functions for order processing, including order entry, updates, cancellations, and inventory management
* Triggers to enforce business rules and maintain data integrity, such as automatic inventory updates and order status tracking
* Reporting
  * Sales Reports: Detailed analysis of daily, weekly, and monthly sales.
  * Inventory Reports: Real-time inventory levels, and stock valuation.
  * Customer Reports: Customer order history, Monthly Rebate Report, and credit aging report.
  * Reversal Analysis
  * Outstanding Orders
* Payment processing
* Order to Cash Management
* Returns and Refunds
* Database Auditing


## Technologies Used
* Microsoft SQL Server
* T-SQL
* Microsoft SQL Server Management Studio
* SQL Server Agent for job scheduling and automation.

## Installation and Setup
 To run this project on your machine you need to install the latest Microsoft SQL Server then follow the steps below.
 * Open and run the script [OMS Query](scripts/OMS%20Query.sql)

**Note**: The script creates the database, the Tables and programatic functionalities, so there is no need to recreate the Tables.


## Usage
After the Installation, Open the script [OMS Modules](scripts/OMS%20Modules.sql).
* Run the modules by first supply the parameters specified

For example, for Order to Cash Management module
* Generate Order ID by running
  ```
  EXEC NextOrderID
  ```
* Then raise an order using
  ```
  EXEC RaiseOrder
  @OrderID= '',
  @CustomerID='',
  @LocationID='',
  @productcode='',                
  @Quantity=
  ```

Note:
 1. @OrderID is gotten from the first step. other information are as defined in the [dataset](/datasets)
 2. For subsequent ordered items, only `@productcode` and `@Quantity` should be changed

* Order Cancellation can be done by running
  ```
  EXEC CancelOrder
  @orderID =''
  ```
  * Invoicing can be done by running
    ```
    EXEC BillOrder 
    @orderID =''
    ```
  Note:
   1. If the customer does not have enough balance, running the above will not be successful and will send the order back to the que list. See [Process Flow](Process%20Flow.xlsx) for how it works.


## Future Enhancements
As I continue to develop and enhance the OMS, the following features are under consideration:
* User Interface (UI) for Input Collection
* Enhanced Security Features
* API Integration to provide an interface for integrating with other systems, such as e-commerce platforms, ERP systems, or third-party analytics tools

## Contribution
Contributions are welcome! If you're interested in helping build the UI, improve the system's functionality, or add new features, please refer to the [Contribution Guidelines](CONTRIBUTING.md) for more details.

### Contact
For any inquiries or feedback, please contact rojuadeyemi@yahoo.com.
