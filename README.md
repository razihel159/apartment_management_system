# 🏢 Apartment Management System

A comprehensive full-stack solution designed to streamline apartment rentals, tenant management, and payment tracking.

---

## ✨ Features

### 👨‍💼 Landlord / Admin Portal
* **Tenant Management**: Full CRUD operations (Create, Read, Update, Delete) for tenant records.
* **Room Inventory**: Real-time status tracking (Occupied/Available) and room assignment.
* **Payment Oversight**: View payment histories and verify digital receipts submitted by tenants.
* **Issue Tracking**: Monitor maintenance reports sent by tenants.

### 👤 Tenant Mobile App
* **Profile Control**: Update contact information and secure password management.
* **Digital Payments**: Upload proof of payment (receipts) directly from the mobile gallery.
* **Service Requests**: File maintenance reports for room issues.
* **Rent Status**: Real-time view of monthly dues and payment history.

---

## 🛠 Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Node.js (Express.js)
- **Database:** MySQL
- **Security:** BCrypt Password Hashing

---

## 📂 Folder Structure

```text
Apartment Management System/
├── apartment_api/          # Backend REST API
│   ├── controllers/        # Business logic & Database operations
│   ├── routes/             # API Endpoints definition
│   ├── config/             # DB Connection settings
│   └── uploads/            # Storage for tenant receipts
├── lib/                    # Flutter Frontend
│   ├── screens/            # UI for Admin and Tenant modules
│   ├── services/           # API Service layer (HTTP)
│   └── widgets/            # Reusable UI components
└── .gitignore              # Git exclusion rules

🚀 Installation & Setup
Backend
Navigate to the api folder: cd apartment_api
Install dependencies: npm install
Configure your MySQL credentials in config/db.js.
Start the server: node server.js

Frontend
Fetch Flutter packages: flutter pub get.
Ensure the API URL in api_service.dart matches your server's IP.
Run the app: flutter run.

🔒 Security
This system prioritizes data security by hashing user passwords using BCrypt. It employs a hybrid authentication logic to support the transition of legacy data to a secure hashed format without service interruption.

📝 Future Plans
[ ] Admin Approval/Rejection logic for payments.
[ ] Automated PDF Invoice generation.
[ ] Revenue analytics dashboard with charts.
