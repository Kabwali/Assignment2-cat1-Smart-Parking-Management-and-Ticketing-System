# SQL use case: Smart Parking Management and Ticketing System
# Module: Advanced Database Technology
# DBMS: PostgreSQL
# Database name: parkingticketingsystem

# Case Study Description 
The Parking Management System monitors parking spaces, vehicles, tickets, staff, and payments. It ensures 
efficient parking allocation, revenue management, and occupancy monitoring. This subject combines the 
concepts of managing parking spaces intelligently and handling the ticketing process, such as payments and access.

# Relationships
- ParkingLot → Space (1:N), - Space → Tickect (1:N), - Vehicle → Ticket (1:N), - Ticket → Payment (1:1), and - Staff →   Ticket (1:N)

# Tasks to Perform 
1. Define all six tables with PK, FK, CHECK constraints, 2. Apply CASCADE DELETE between Ticket and Payment, 
3. Insert 5 parking lots and 10 vehicles, 4. Retrieve all occupied spaces with vehicle details. 
5. Update payment status upon vehicle exit, 6. Identify parking lots nearing full capacity. 
7. Create a view showing total revenue per lot, 8. Implement a trigger to mark space as available after payment completion

# Instructions:
1. Create database: CREATE DATABASE parkingticketingsystem;
2. Connect to the database: \c parkingticketingsystem (psql)
3. Inspect tables and run example queries provided in the script.

# Notes:
- The script creates UUIDs using the uuid-ossp extension.
- All scripts are **pgAdmin/PLSQL compatible**
- Designed for **educational purposes** and **demonstration of key concepts** in sql dadabases
