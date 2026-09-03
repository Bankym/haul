-- Haul Pickup & Delivery Service Database Schema
-- MySQL Database
-- Created for comprehensive pickup and delivery management system

-- Drop existing tables (in reverse order of creation due to foreign keys)
DROP TABLE IF EXISTS compliances;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS payment_wallets;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS shipment_trans_shipment;
DROP TABLE IF EXISTS shipment_tracking;
DROP TABLE IF EXISTS shipment_pricing;
DROP TABLE IF EXISTS shipment_items;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS service_rates;
DROP TABLE IF EXISTS delivery_modes;
DROP TABLE IF EXISTS vehicle_maintenance;
DROP TABLE IF EXISTS vehicle_insurance;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS references;
DROP TABLE IF EXISTS proof_of_ownership;
DROP TABLE IF EXISTS proof_of_address;
DROP TABLE IF EXISTS vehicle_registrations;
DROP TABLE IF EXISTS driver_licenses;
DROP TABLE IF EXISTS email_verifications;
DROP TABLE IF EXISTS phone_verifications;
DROP TABLE IF EXISTS user_addresses;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS users;

-- =====================================================================
-- CORE USER TABLES
-- =====================================================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type ENUM('driver', 'carrier', 'shipper', 'dispatcher', 'admin') NOT NULL,
    account_type ENUM('individual', 'business') NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    company_name VARCHAR(255),
    profile_image_url VARCHAR(500),
    timezone VARCHAR(50),
    region VARCHAR(100),
    status ENUM('active', 'suspended', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_phone (phone),
    INDEX idx_user_type (user_type),
    INDEX idx_status (status)
);

CREATE TABLE user_profiles (
    profile_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    bio TEXT,
    avg_rating DECIMAL(3, 2) DEFAULT 0.00,
    total_trips INT DEFAULT 0,
    verified_status ENUM('unverified', 'verified', 'super_verified') DEFAULT 'unverified',
    kyc_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE user_addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address_type ENUM('home', 'office', 'business', 'warehouse') NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state_region VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_coordinates (latitude, longitude)
);

-- =====================================================================
-- AUTHENTICATION & VERIFICATION TABLES
-- =====================================================================

CREATE TABLE phone_verifications (
    verification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    otp_code VARCHAR(10),
    otp_expires_at TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    attempt_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_phone_number (phone_number)
);

CREATE TABLE email_verifications (
    verification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    verification_token VARCHAR(255) UNIQUE,
    token_expires_at TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_email (email)
);

-- =====================================================================
-- LICENSING & DOCUMENTATION TABLES
-- =====================================================================

CREATE TABLE driver_licenses (
    license_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_type VARCHAR(10) NOT NULL,
    issue_country VARCHAR(100) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    document_url VARCHAR(500),
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    verified_by INT,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_license_number (license_number),
    INDEX idx_expiry_date (expiry_date)
);

CREATE TABLE vehicle_registrations (
    registration_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_id INT,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    registration_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    document_url VARCHAR(500),
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_registration_number (registration_number),
    INDEX idx_expiry_date (expiry_date)
);

CREATE TABLE proof_of_address (
    proof_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    document_type ENUM('utility_bill', 'lease', 'mortgage', 'govt_letter') NOT NULL,
    document_url VARCHAR(500),
    issue_date DATE NOT NULL,
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_verification_status (verification_status)
);

CREATE TABLE proof_of_ownership (
    ownership_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_id INT,
    document_type ENUM('title_deed', 'purchase_agreement', 'registration') NOT NULL,
    document_url VARCHAR(500),
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_verification_status (verification_status)
);

CREATE TABLE references (
    reference_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    reference_name VARCHAR(100) NOT NULL,
    reference_phone VARCHAR(20),
    reference_email VARCHAR(255),
    reference_type ENUM('employer', 'business_partner', 'personal') NOT NULL,
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_verification_status (verification_status)
);

-- =====================================================================
-- VEHICLE & EQUIPMENT TABLES
-- =====================================================================

CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_type ENUM('car', 'van', 'truck', 'lorry', 'bike') NOT NULL,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    color VARCHAR(50),
    license_plate VARCHAR(50) UNIQUE NOT NULL,
    vin VARCHAR(100) UNIQUE,
    capacity_weight DECIMAL(10, 2),
    capacity_volume DECIMAL(10, 2),
    insurance_provider VARCHAR(255),
    insurance_expiry_date DATE,
    photo_url VARCHAR(500),
    status ENUM('active', 'maintenance', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_vehicle_type (vehicle_type),
    INDEX idx_license_plate (license_plate),
    INDEX idx_status (status)
);

CREATE TABLE vehicle_insurance (
    insurance_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    insurance_provider VARCHAR(255) NOT NULL,
    policy_number VARCHAR(100) UNIQUE NOT NULL,
    coverage_type ENUM('third_party', 'comprehensive', 'goods_in_transit') NOT NULL,
    coverage_amount DECIMAL(12, 2),
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    document_url VARCHAR(500),
    status ENUM('active', 'expired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    INDEX idx_vehicle_id (vehicle_id),
    INDEX idx_expiry_date (expiry_date),
    INDEX idx_status (status)
);

CREATE TABLE vehicle_maintenance (
    maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    maintenance_type ENUM('oil_change', 'inspection', 'repair', 'cleaning') NOT NULL,
    service_date DATE NOT NULL,
    next_service_date DATE,
    cost DECIMAL(10, 2),
    service_provider VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    INDEX idx_vehicle_id (vehicle_id),
    INDEX idx_service_date (service_date),
    INDEX idx_next_service_date (next_service_date)
);

-- =====================================================================
-- DELIVERY MODE & SERVICE TABLES
-- =====================================================================

CREATE TABLE delivery_modes (
    mode_id INT AUTO_INCREMENT PRIMARY KEY,
    mode_name ENUM('car', 'van', 'truck', 'lorry', 'leg_work', 'bike', 'courier') UNIQUE NOT NULL,
    description TEXT,
    base_rate DECIMAL(10, 2),
    min_weight DECIMAL(10, 2),
    max_weight DECIMAL(10, 2),
    min_volume DECIMAL(10, 2),
    max_volume DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_is_active (is_active)
);

CREATE TABLE service_rates (
    rate_id INT AUTO_INCREMENT PRIMARY KEY,
    delivery_mode_id INT NOT NULL,
    base_rate_per_km DECIMAL(10, 2) NOT NULL,
    rate_per_kg DECIMAL(10, 2),
    rate_per_cbm DECIMAL(10, 2),
    minimum_charge DECIMAL(10, 2),
    emergency_surcharge_percent DECIMAL(5, 2) DEFAULT 0.00,
    fragile_surcharge_percent DECIMAL(5, 2) DEFAULT 0.00,
    trans_shipment_surcharge_percent DECIMAL(5, 2) DEFAULT 0.00,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (delivery_mode_id) REFERENCES delivery_modes(mode_id) ON DELETE CASCADE,
    INDEX idx_delivery_mode_id (delivery_mode_id),
    INDEX idx_effective_from (effective_from)
);

-- =====================================================================
-- SHIPMENT/ORDER TABLES
-- =====================================================================

CREATE TABLE shipments (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    shipper_id INT NOT NULL,
    carrier_id INT,
    driver_id INT,
    dispatcher_id INT,
    pickup_address_id INT NOT NULL,
    delivery_address_id INT NOT NULL,
    delivery_mode_id INT NOT NULL,
    shipment_status ENUM('created', 'accepted', 'in_transit', 'delivered', 'failed', 'cancelled') DEFAULT 'created',
    pickup_scheduled_at TIMESTAMP,
    delivery_scheduled_at TIMESTAMP,
    actual_pickup_at TIMESTAMP,
    actual_delivery_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (shipper_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (carrier_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (driver_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (dispatcher_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (pickup_address_id) REFERENCES user_addresses(address_id) ON DELETE RESTRICT,
    FOREIGN KEY (delivery_address_id) REFERENCES user_addresses(address_id) ON DELETE RESTRICT,
    FOREIGN KEY (delivery_mode_id) REFERENCES delivery_modes(mode_id) ON DELETE RESTRICT,
    INDEX idx_shipper_id (shipper_id),
    INDEX idx_carrier_id (carrier_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_shipment_status (shipment_status),
    INDEX idx_created_at (created_at),
    INDEX idx_pickup_scheduled_at (pickup_scheduled_at)
);

CREATE TABLE shipment_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    item_description VARCHAR(500) NOT NULL,
    quantity INT DEFAULT 1,
    weight DECIMAL(10, 2),
    length DECIMAL(10, 2),
    width DECIMAL(10, 2),
    height DECIMAL(10, 2),
    volume DECIMAL(10, 2),
    fragility ENUM('fragile', 'non-fragile') DEFAULT 'non-fragile',
    urgency ENUM('routine', 'standard', 'urgent', 'emergency') DEFAULT 'standard',
    allow_trans_shipment BOOLEAN DEFAULT TRUE,
    special_handling_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_fragility (fragility),
    INDEX idx_urgency (urgency)
);

CREATE TABLE shipment_pricing (
    pricing_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT UNIQUE NOT NULL,
    base_rate DECIMAL(12, 2),
    weight_surcharge DECIMAL(12, 2),
    fragile_surcharge DECIMAL(12, 2),
    urgency_surcharge DECIMAL(12, 2),
    trans_shipment_surcharge DECIMAL(12, 2),
    distance_km DECIMAL(10, 2),
    total_amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_status ENUM('pending', 'paid', 'refunded') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_payment_status (payment_status)
);

CREATE TABLE shipment_tracking (
    tracking_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    status ENUM('pickup_scheduled', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'failed') NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_coordinates (latitude, longitude)
);

CREATE TABLE shipment_trans_shipment (
    trans_shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    original_vehicle_id INT NOT NULL,
    new_vehicle_id INT NOT NULL,
    reason ENUM('breakdown', 'delay', 'route_optimization') NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    FOREIGN KEY (original_vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE RESTRICT,
    FOREIGN KEY (new_vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE RESTRICT,
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_created_at (created_at)
);

-- =====================================================================
-- RATING & REVIEW TABLES
-- =====================================================================

CREATE TABLE ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    rater_id INT NOT NULL,
    rated_user_id INT NOT NULL,
    rating_score INT NOT NULL CHECK (rating_score >= 1 AND rating_score <= 5),
    comment TEXT,
    categories JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    FOREIGN KEY (rater_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (rated_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_rated_user_id (rated_user_id),
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_rating_score (rating_score)
);

CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    reviewer_id INT NOT NULL,
    reviewed_user_id INT NOT NULL,
    review_text TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_reviewed_user_id (reviewed_user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- =====================================================================
-- PAYMENT TABLES
-- =====================================================================

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method ENUM('card', 'bank_transfer', 'wallet', 'cash') NOT NULL,
    transaction_id VARCHAR(255),
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_payment_status (payment_status),
    INDEX idx_created_at (created_at)
);

CREATE TABLE payment_wallets (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    balance DECIMAL(12, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    last_transaction_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_balance (balance)
);

-- =====================================================================
-- SUPPORT & COMMUNICATION TABLES
-- =====================================================================

CREATE TABLE support_tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    shipment_id INT,
    subject VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    status ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
    assigned_to INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_created_at (created_at)
);

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('shipment_update', 'payment', 'review', 'system') NOT NULL,
    title VARCHAR(500) NOT NULL,
    message TEXT NOT NULL,
    related_id INT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- =====================================================================
-- AUDIT & COMPLIANCE TABLES
-- =====================================================================

CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100),
    entity_id INT,
    changes JSON,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_timestamp (timestamp),
    INDEX idx_entity (entity_type, entity_id)
);

CREATE TABLE compliances (
    compliance_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    compliance_type ENUM('insurance', 'license', 'background_check', 'safety_training') NOT NULL,
    status ENUM('pending', 'approved', 'rejected', 'expired') DEFAULT 'pending',
    document_url VARCHAR(500),
    expiry_date DATE,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_compliance_type (compliance_type),
    INDEX idx_status (status),
    INDEX idx_expiry_date (expiry_date)
);

-- =====================================================================
-- END OF SCHEMA
-- =====================================================================
