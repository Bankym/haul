-- Haul Demo Data: Users and Delivery Modes
-- Insert sample records for testing

-- =====================================================================
-- INSERT DELIVERY MODES
-- =====================================================================

INSERT INTO delivery_modes (mode_name, description, base_rate, min_weight, max_weight, min_volume, max_volume, is_active) VALUES
('car', 'Standard car delivery for small packages and documents', 5.00, 0.5, 50, 0.1, 2, TRUE),
('bike', 'Motorcycle courier service for urgent small items', 8.00, 0.1, 10, 0.05, 0.5, TRUE),
('van', 'Van delivery for medium-sized shipments', 12.00, 50, 500, 2, 10, TRUE),
('truck', 'Large truck for heavy commercial shipments', 25.00, 500, 3000, 10, 30, TRUE),
('lorry', 'Heavy-duty lorry for oversized cargo', 40.00, 3000, 10000, 30, 100, TRUE),
('leg_work', 'On-foot courier service for local areas', 3.00, 0.1, 5, 0.05, 0.5, TRUE),
('courier', 'Premium express courier service', 15.00, 1, 100, 0.5, 5, TRUE);

-- =====================================================================
-- INSERT DEMO USERS
-- =====================================================================

-- Admin User
INSERT INTO users (email, phone, password_hash, user_type, account_type, first_name, last_name, company_name, timezone, region, status) 
VALUES 
('admin@haul.com', '+1-202-555-0100', '$2y$10$abc123xyz789...', 'admin', 'business', 'Admin', 'User', 'Haul Inc.', 'America/New_York', 'US', 'active');

-- Shippers (Business and Individual)
INSERT INTO users (email, phone, password_hash, user_type, account_type, first_name, last_name, company_name, timezone, region, status) 
VALUES 
('shipper1@business.com', '+1-202-555-0101', '$2y$10$def456uvw123...', 'shipper', 'business', 'John', 'Smith', 'Smith Logistics Ltd.', 'America/New_York', 'US', 'active'),
('shipper2@business.com', '+1-202-555-0102', '$2y$10$ghi789rst456...', 'shipper', 'business', 'Sarah', 'Johnson', 'Johnson Distribution', 'America/Los_Angeles', 'US', 'active'),
('individual_shipper@email.com', '+1-202-555-0103', '$2y$10$jkl012uxy789...', 'shipper', 'individual', 'Michael', 'Brown', NULL, 'America/Chicago', 'US', 'active');

-- Carriers (Business)
INSERT INTO users (email, phone, password_hash, user_type, account_type, first_name, last_name, company_name, timezone, region, status) 
VALUES 
('carrier1@haul.com', '+1-202-555-0201', '$2y$10$mno345vwx012...', 'carrier', 'business', 'David', 'Wilson', 'Express Carriers Inc.', 'America/New_York', 'US', 'active'),
('carrier2@haul.com', '+1-202-555-0202', '$2y$10$pqr678yz1234...', 'carrier', 'business', 'Emma', 'Davis', 'Global Freight Solutions', 'America/Los_Angeles', 'US', 'active');

-- Drivers (Individual)
INSERT INTO users (email, phone, password_hash, user_type, account_type, first_name, last_name, timezone, region, status) 
VALUES 
('driver1@haul.com', '+1-202-555-0301', '$2y$10$stu901abc234...', 'driver', 'individual', 'James', 'Martinez', 'America/New_York', 'US', 'active'),
('driver2@haul.com', '+1-202-555-0302', '$2y$10$vwx234def567...', 'driver', 'individual', 'Robert', 'Garcia', 'America/Los_Angeles', 'US', 'active'),
('driver3@haul.com', '+1-202-555-0303', '$2y$10$yza567ghi890...', 'driver', 'individual', 'Christopher', 'Rodriguez', 'America/Chicago', 'US', 'active'),
('driver4@haul.com', '+1-202-555-0304', '$2y$10$bcd890jkl123...', 'driver', 'individual', 'Daniel', 'Lee', 'America/Denver', 'US', 'active');

-- Dispatchers
INSERT INTO users (email, phone, password_hash, user_type, account_type, first_name, last_name, company_name, timezone, region, status) 
VALUES 
('dispatcher1@haul.com', '+1-202-555-0401', '$2y$10$efg123klm456...', 'dispatcher', 'business', 'Lisa', 'Anderson', 'Haul Dispatch Team', 'America/New_York', 'US', 'active'),
('dispatcher2@haul.com', '+1-202-555-0402', '$2y$10$hij456nop789...', 'dispatcher', 'business', 'Patricia', 'Taylor', 'Haul Dispatch Team', 'America/Los_Angeles', 'US', 'active');

-- =====================================================================
-- INSERT USER PROFILES FOR DEMO USERS
-- =====================================================================

INSERT INTO user_profiles (user_id, bio, avg_rating, total_trips, verified_status, kyc_status) 
SELECT user_id, CONCAT(first_name, ' ', last_name, ' - Active user on Haul'), 
  ROUND(RAND() * 5, 2), 
  FLOOR(RAND() * 150),
  'verified',
  'approved'
FROM users 
WHERE user_type IN ('driver', 'carrier', 'shipper')
LIMIT 10;

-- =====================================================================
-- INSERT USER ADDRESSES
-- =====================================================================

INSERT INTO user_addresses (user_id, address_type, street_address, city, state_region, postal_code, country, latitude, longitude, is_default) 
SELECT 
  user_id,
  'home',
  CONCAT(FLOOR(RAND() * 9999) + 1, ' ', 
    CASE FLOOR(RAND() * 5)
      WHEN 0 THEN 'Main Street'
      WHEN 1 THEN 'Oak Avenue'
      WHEN 2 THEN 'Pine Road'
      WHEN 3 THEN 'Elm Street'
      ELSE 'Cedar Lane'
    END
  ),
  CASE region
    WHEN 'US' THEN CASE FLOOR(RAND() * 4)
      WHEN 0 THEN 'New York'
      WHEN 1 THEN 'Los Angeles'
      WHEN 2 THEN 'Chicago'
      ELSE 'Denver'
    END
    ELSE 'Unknown'
  END,
  region,
  CONCAT(FLOOR(RAND() * 90000) + 10000),
  'United States',
  ROUND(RAND() * (49.383 - 24.521) + 24.521, 8),
  ROUND(RAND() * (-66.946 - (-125.242)) + (-125.242), 8),
  TRUE
FROM users 
WHERE user_type IN ('driver', 'carrier', 'shipper');

-- =====================================================================
-- INSERT VEHICLES FOR DRIVERS AND CARRIERS
-- =====================================================================

INSERT INTO vehicles (user_id, vehicle_type, make, model, year, color, license_plate, vin, capacity_weight, capacity_volume, insurance_provider, insurance_expiry_date, status) 
VALUES
-- Driver 1 vehicles
((SELECT user_id FROM users WHERE email = 'driver1@haul.com'), 'car', 'Toyota', 'Camry', 2021, 'Silver', 'NYH-1234', 'JT2BF18K9M0015634', 200, 2.5, 'State Insurance Co.', '2025-12-31', 'active'),
((SELECT user_id FROM users WHERE email = 'driver1@haul.com'), 'van', 'Ford', 'Transit', 2020, 'White', 'NYH-5678', '1FTYE24H43FB09144', 1000, 12, 'State Insurance Co.', '2025-12-31', 'active'),

-- Driver 2 vehicles
((SELECT user_id FROM users WHERE email = 'driver2@haul.com'), 'car', 'Honda', 'Civic', 2022, 'Black', 'LAH-9012', 'JHLRP5H24MC009887', 200, 2.5, 'Pacific Insurance', '2026-06-30', 'active'),
((SELECT user_id FROM users WHERE email = 'driver2@haul.com'), 'truck', 'Chevrolet', 'Silverado', 2019, 'Red', 'LAH-3456', '3GCUYHF75KG526518', 2000, 25, 'Pacific Insurance', '2026-06-30', 'active'),

-- Driver 3 vehicles
((SELECT user_id FROM users WHERE email = 'driver3@haul.com'), 'bike', 'Harley-Davidson', 'Street 750', 2023, 'Blue', 'CHH-7890', '5Y4XX9150000048903', 50, 0.3, 'Midwest Riders', '2025-09-30', 'active'),

-- Driver 4 vehicles
((SELECT user_id FROM users WHERE email = 'driver4@haul.com'), 'van', 'Mercedes', 'Sprinter', 2021, 'White', 'DEN-2468', 'WDB9061721X123456', 1500, 18, 'Mile High Insurance', '2026-03-31', 'active'),

-- Carrier 1 vehicles
((SELECT user_id FROM users WHERE email = 'carrier1@haul.com'), 'truck', 'Volvo', 'FH16', 2020, 'Blue', 'NYH-1111', '4V2NC91L041197814', 3000, 35, 'Commercial Fleet Insurance', '2026-12-31', 'active'),
((SELECT user_id FROM users WHERE email = 'carrier1@haul.com'), 'lorry', 'MAN', 'TGX', 2019, 'White', 'NYH-2222', 'WMA00000000000001', 5000, 50, 'Commercial Fleet Insurance', '2026-12-31', 'active'),

-- Carrier 2 vehicles
((SELECT user_id FROM users WHERE email = 'carrier2@haul.com'), 'truck', 'Peterbilt', '389', 2021, 'Red', 'LAH-5555', '1XKWDB0X21J136407', 3000, 38, 'West Coast Logistics', '2026-09-30', 'active'),
((SELECT user_id FROM users WHERE email = 'carrier2@haul.com'), 'van', 'Isuzu', 'NPR', 2020, 'Gray', 'LAH-6666', 'JALC4B16RL006542', 1200, 15, 'West Coast Logistics', '2026-09-30', 'active');

-- =====================================================================
-- INSERT PHONE VERIFICATIONS
-- =====================================================================

INSERT INTO phone_verifications (user_id, phone_number, is_verified, verified_at) 
SELECT user_id, phone, TRUE, NOW() 
FROM users;

-- =====================================================================
-- INSERT EMAIL VERIFICATIONS
-- =====================================================================

INSERT INTO email_verifications (user_id, email, is_verified, verified_at) 
SELECT user_id, email, TRUE, NOW() 
FROM users;

-- =====================================================================
-- INSERT PAYMENT WALLETS
-- =====================================================================

INSERT INTO payment_wallets (user_id, balance, currency) 
SELECT user_id, 
  CASE user_type
    WHEN 'shipper' THEN ROUND(RAND() * 5000, 2)
    WHEN 'driver' THEN ROUND(RAND() * 2000, 2)
    WHEN 'carrier' THEN ROUND(RAND() * 10000, 2)
    ELSE 0
  END,
  'USD'
FROM users 
WHERE user_type IN ('driver', 'carrier', 'shipper');

-- =====================================================================
-- Summary of Demo Data Inserted
-- =====================================================================
-- Delivery Modes: 7 records
-- Users: 13 records (1 admin, 3 shippers, 2 carriers, 4 drivers, 2 dispatchers)
-- User Profiles: 10 records
-- User Addresses: ~13 records
-- Vehicles: 9 records
-- Phone Verifications: 13 records
-- Email Verifications: 13 records
-- Payment Wallets: 10 records
-- =====================================================================
