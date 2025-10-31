-- Smart Parking Management and Ticketing System
-- PostgreSQL SQL script for creating schema, sample data, queries, view, and trigger
-- Database: parkingticketingsystem
-- Author: Generated for assignment

-- 1. Create extension for UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create tables with PK, FK, and CHECK constraints

-- 2.1 ParkingLot table
-- Stores parking lot metadata and capacity information
CREATE TABLE IF NOT EXISTS ParkingLot (
    LotID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    Name VARCHAR(100) NOT NULL,
    Location VARCHAR(150) NOT NULL,
    Capacity INT NOT NULL CHECK (Capacity > 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (Status IN ('Open', 'Closed'))
);

-- 2.2 Space table
-- Represents individual parking spaces within a lot
CREATE TABLE IF NOT EXISTS Space (
    SpaceID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    LotID UUID NOT NULL REFERENCES ParkingLot(LotID) ON DELETE CASCADE,
    SpaceNo VARCHAR(20) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Available' CHECK (Status IN ('Available', 'Occupied')),
    Type VARCHAR(20) CHECK (Type IN ('Compact', 'Large', 'Electric', 'Handicap'))
);

-- 2.3 Vehicle table
-- Stores vehicle information
CREATE TABLE IF NOT EXISTS Vehicle (
    VehicleID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    PlateNo VARCHAR(20) UNIQUE NOT NULL,
    Type VARCHAR(20) CHECK (Type IN ('Car', 'Motorcycle', 'Truck', 'Bus')),
    OwnerName VARCHAR(100) NOT NULL,
    Contact VARCHAR(20)
);

-- 2.4 Staff table
-- Staff members who manage tickets and operations
CREATE TABLE IF NOT EXISTS Staff (
    StaffID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    FullName VARCHAR(100) NOT NULL,
    Role VARCHAR(50) CHECK (Role IN ('Attendant', 'Supervisor', 'Manager')),
    Contact VARCHAR(20),
    Shift VARCHAR(20) CHECK (Shift IN ('Morning', 'Evening', 'Night'))
);

-- 2.5 Ticket table
-- Represents parking ticket issued when a vehicle occupies a space
CREATE TABLE IF NOT EXISTS Ticket (
    TicketID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    SpaceID UUID NOT NULL REFERENCES Space(SpaceID) ON DELETE CASCADE,
    VehicleID UUID NOT NULL REFERENCES Vehicle(VehicleID) ON DELETE CASCADE,
    StaffID UUID REFERENCES Staff(StaffID),
    EntryTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ExitTime TIMESTAMP,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active', 'Closed'))
);

-- 2.6 Payment table
-- Payment for a ticket. Enforce 1:1 by making TicketID UNIQUE and apply CASCADE DELETE from Ticket -> Payment
CREATE TABLE IF NOT EXISTS Payment (
    PaymentID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    TicketID UUID UNIQUE NOT NULL REFERENCES Ticket(TicketID) ON DELETE CASCADE,
    Amount NUMERIC(10,2) NOT NULL CHECK (Amount >= 0),
    PaymentDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Method VARCHAR(20) CHECK (Method IN ('Cash', 'Card', 'Mobile'))
);

-- 3. Insert sample data: 5 parking lots and 10 vehicles (plus some spaces, staff, tickets)
-- Insert Parking Lots
INSERT INTO ParkingLot (Name, Location, Capacity, Status)
VALUES
('Lot A', 'Downtown', 50, 'Open'),
('Lot B', 'Airport Road', 100, 'Open'),
('Lot C', 'City Mall', 80, 'Open'),
('Lot D', 'University Campus', 70, 'Open'),
('Lot E', 'Hospital', 60, 'Open')
ON CONFLICT DO NOTHING;

-- Insert Vehicles (10)
INSERT INTO Vehicle (PlateNo, Type, OwnerName, Contact) VALUES
('RBC-101', 'Bus', 'John Doe', '0788000001'),
('RBC-102', 'Car', 'Jane Smith', '0788000002'),
('RBC-103', 'Truck', 'Paul Adams', '0788000003'),
('RBC-104', 'Motorcycle', 'Alice Brown', '0788000004'),
('RBC-105', 'Car', 'Kevin White', '0788000005'),
('RBC-106', 'Car', 'Maria Green', '0788000006'),
('RBC-107', 'Bus', 'Robert Black', '0788000007'),
('RBC-108', 'Truck', 'David Lee', '0788000008'),
('RBC-109', 'Car', 'Linda Young', '0788000009'),
('RBC-110', 'Motorcycle', 'Chris Hall', '0788000010')
ON CONFLICT DO NOTHING;

-- Insert some Spaces (create 10 example spaces across lots)
WITH lots AS (SELECT LotID FROM ParkingLot ORDER BY Name LIMIT 5)
INSERT INTO Space (LotID, SpaceNo, Status, Type)
SELECT LotID, 'S' || gs, 'Available', 'Compact'
FROM lots, generate_series(1,10) gs
ON CONFLICT DO NOTHING;

-- Insert Staff
INSERT INTO Staff (FullName, Role, Contact, Shift) VALUES
('Eric Ndayisaba', 'Attendant', '0788000101', 'Morning'),
('Martha Uwimana', 'Supervisor', '0788000102', 'Evening')
ON CONFLICT DO NOTHING;

-- Create 5 Tickets assigning first 5 spaces to first 5 vehicles
INSERT INTO Ticket (SpaceID, VehicleID, StaffID, EntryTime, Status)
SELECT s.SpaceID, v.VehicleID, st.StaffID, NOW() - (INTERVAL '1 hour' * row_number() OVER (ORDER BY s.spaceid)), 'Active'
FROM Space s
JOIN (SELECT VehicleID FROM Vehicle ORDER BY PlateNo LIMIT 5) v ON TRUE
CROSS JOIN LATERAL (SELECT StaffID FROM Staff ORDER BY FullName LIMIT 1) st
LIMIT 5
ON CONFLICT DO NOTHING;

-- Mark corresponding spaces as Occupied for those tickets
UPDATE Space
SET Status = 'Occupied'
WHERE SpaceID IN (SELECT SpaceID FROM Ticket WHERE Status = 'Active');

-- 4. Query: Retrieve all occupied spaces with vehicle details
-- Shows occupied space number, type, plate number, owner, entry time
-- Example query (for user to run and inspect results)
-- SELECT s.SpaceNo, s.Type, v.PlateNo, v.OwnerName, t.EntryTime
-- FROM Space s
-- JOIN Ticket t ON s.SpaceID = t.SpaceID
-- JOIN Vehicle v ON t.VehicleID = v.VehicleID
-- WHERE s.Status = 'Occupied';

-- 5. Update payment status upon vehicle exit (example function and sample update)
-- This is an example flow: Close ticket, insert payment, and trigger will set space available
-- Example closing a ticket (replace <ticket_uuid> with actual TicketID)
-- UPDATE Ticket SET ExitTime = NOW(), Status = 'Closed' WHERE TicketID = '<ticket_uuid>';

-- Example insert payment (replace <ticket_uuid> and amount)
-- INSERT INTO Payment (TicketID, Amount, Method) VALUES ('<ticket_uuid>', 5000.00, 'Card');

-- 6. Identify parking lots nearing full capacity (occupancy >= 80%)
-- Example query to run:
-- SELECT pl.Name, pl.Capacity, COUNT(s.SpaceID) AS OccupiedSpaces,
--       ROUND((COUNT(s.SpaceID)::DECIMAL / pl.Capacity) * 100, 2) AS OccupancyRate
-- FROM ParkingLot pl
-- JOIN Space s ON pl.LotID = s.LotID
-- WHERE s.Status = 'Occupied'
-- GROUP BY pl.LotID, pl.Name, pl.Capacity
-- HAVING (COUNT(s.SpaceID)::DECIMAL / pl.Capacity) * 100 >= 80;

-- 7. Create a view showing total revenue per lot
CREATE OR REPLACE VIEW LotRevenue AS
SELECT pl.LotID, pl.Name AS LotName, COALESCE(SUM(p.Amount),0) AS TotalRevenue
FROM Payment p
JOIN Ticket t ON p.TicketID = t.TicketID
JOIN Space s ON t.SpaceID = s.SpaceID
JOIN ParkingLot pl ON s.LotID = pl.LotID
GROUP BY pl.LotID, pl.Name;

-- 8. Implement trigger to mark space as available after payment completion

-- 8.1 Function: update space status to 'Available' when payment inserted
CREATE OR REPLACE FUNCTION update_space_status_after_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- Set the space corresponding to the ticket to Available
    UPDATE Space
    SET Status = 'Available'
    WHERE SpaceID = (SELECT SpaceID FROM Ticket WHERE TicketID = NEW.TicketID);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8.2 Trigger: call function after insert on Payment
CREATE TRIGGER trg_update_space_after_payment
AFTER INSERT ON Payment
FOR EACH ROW
EXECUTE FUNCTION update_space_status_after_payment();

-- End of script
