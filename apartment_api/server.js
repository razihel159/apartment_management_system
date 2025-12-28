const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bodyParser = require('body-parser');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Siguraduhing existing ang uploads folder
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)){
    fs.mkdirSync(uploadDir);
}
app.use('/uploads', express.static('uploads'));

// Database Connection Pool
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',      
    password: '',      
    database: 'apartment_db',
    waitForConnections: true,
    connectionLimit: 10
});

// Multer Setup para sa Image Attachments
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage: storage });

// ================= NEW: AUTOMATIC OVERDUE LOGIC =================
const updateOverdueStatus = async () => {
    try {
        const today = new Date();
        const currentDay = today.getDate();

        const [tenants] = await db.query("SELECT id, name FROM tenants");
        
        for (let tenant of tenants) {
            const [payments] = await db.query(`
                SELECT * FROM payments 
                WHERE tenant_id = ? 
                AND MONTH(payment_date) = MONTH(CURRENT_DATE()) 
                AND YEAR(payment_date) = YEAR(CURRENT_DATE())
            `, [tenant.id]);

            if (payments.length === 0 && currentDay > 5) {
                // Update status logic dito
            }
        }
        console.log("Overdue check completed.");
    } catch (err) {
        console.error("Overdue Logic Error:", err.message);
    }
};

// ================= 1. LOGIN SYSTEM =================
app.post('/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        await updateOverdueStatus();
        const [admin] = await db.query('SELECT *, "admin" as role FROM users WHERE email = ? AND password = ?', [email, password]);
        if (admin.length > 0) return res.json({ success: true, role: 'admin', user: admin[0] });

        const [tenant] = await db.query('SELECT *, "tenant" as role FROM tenants WHERE email = ? AND password = ?', [email, password]);
        if (tenant.length > 0) return res.json({ success: true, role: 'tenant', user: tenant[0] });

        res.status(401).json({ success: false, message: "Invalid email or password" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ================= 2. ADMIN DASHBOARD STATS (UPDATED) =================
app.get('/dashboard-stats', async (req, res) => {
    try {
        const [total] = await db.query('SELECT COUNT(*) as count FROM rooms');
        const [occ] = await db.query('SELECT COUNT(*) as count FROM rooms WHERE status = "occupied"');
        const [vacant] = await db.query('SELECT COUNT(*) as count FROM rooms WHERE status = "available" OR status IS NULL');
        const [rev] = await db.query('SELECT SUM(amount) as total FROM payments');
        
        const [overdue] = await db.query(`
            SELECT COUNT(*) as count FROM tenants 
            WHERE id NOT IN (
                SELECT tenant_id FROM payments 
                WHERE MONTH(payment_date) = MONTH(CURRENT_DATE()) 
                AND YEAR(payment_date) = YEAR(CURRENT_DATE())
            )
        `);

        res.json({
            totalRooms: total[0].count,
            occupiedRooms: occ[0].count,
            vacantRooms: vacant[0].count,
            totalCollected: rev[0].total || 0,
            overdueTenants: overdue[0].count
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ================= 3. TENANT PORTAL DATA & PROFILE =================
app.get('/tenant-details/:id', async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT t.name, t.email, t.contact, t.password, IFNULL(r.room_number, 'N/A') as room_number, IFNULL(r.rate, 0) as rate 
            FROM tenants t
            LEFT JOIN rooms r ON t.room_id = r.id
            WHERE t.id = ?`, [req.params.id]);
        res.json({ success: true, data: results[0] || {} });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/update-tenant-profile/:id', async (req, res) => {
    const { contact, email, password } = req.body;
    const tenantId = req.params.id;
    try {
        await db.query("UPDATE tenants SET contact = ?, email = ?, password = ? WHERE id = ?", [contact, email, password, tenantId]);
        res.json({ success: true, message: "Profile updated successfully!" });
    } catch (err) {
        res.status(500).json({ error: "Failed to update profile" });
    }
});

app.get('/unread-reports-count/:id', async (req, res) => {
    try {
        const [results] = await db.query("SELECT COUNT(*) as count FROM reports WHERE tenant_id = ? AND status != 'Resolved'", [req.params.id]);
        res.json({ count: results[0].count });
    } catch (err) { res.json({ count: 0 }); }
});

app.get('/my-reports/:id', async (req, res) => {
    try {
        const [results] = await db.query("SELECT * FROM reports WHERE tenant_id = ? ORDER BY created_at DESC", [req.params.id]);
        res.json({ success: true, data: results });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ================= 4. ROOM MANAGEMENT =================
app.get('/rooms', async (req, res) => {
    try {
        const [r] = await db.query('SELECT * FROM rooms');
        res.json(r);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/add-room', async (req, res) => {
    const { room_number, rate, status } = req.body;
    try {
        await db.query('INSERT INTO rooms (room_number, rate, status) VALUES (?, ?, ?)', [room_number, rate, status || 'available']);
        res.json({ success: true, message: "Room added!" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/update-room/:id', async (req, res) => {
    const { room_number, rate, status } = req.body;
    try {
        await db.query('UPDATE rooms SET room_number = ?, rate = ?, status = ? WHERE id = ?', [room_number, rate, status, req.params.id]);
        res.json({ success: true, message: "Room updated!" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/delete-room/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM rooms WHERE id = ?', [req.params.id]);
        res.json({ success: true, message: "Room deleted!" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ================= 5. TENANT MANAGEMENT =================
app.get('/tenants', async (req, res) => {
    try {
        const [r] = await db.query(`
            SELECT t.*, IFNULL(rm.room_number, 'N/A') as room_number 
            FROM tenants t LEFT JOIN rooms rm ON t.room_id = rm.id`);
        res.json(r);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/add-tenant', async (req, res) => {
    const { fullname, phone, email, room_id } = req.body;
    try {
        await db.query('INSERT INTO tenants (name, contact, email, password, room_id, date_started) VALUES (?, ?, ?, "password123", ?, CURDATE())', [fullname, phone, email, room_id]);
        await db.query('UPDATE rooms SET status = "occupied" WHERE id = ?', [room_id]);
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ================= 6. REPORTS & MAINTENANCE =================
app.post('/submit-report', upload.single('image'), async (req, res) => {
    const { tenant_id, issue_type, description } = req.body;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    if (!tenant_id || tenant_id === 'undefined') {
        return res.status(400).json({ success: false, message: "Tenant ID is required" });
    }

    try {
        await db.query(
            'INSERT INTO reports (tenant_id, issue_type, description, image_url, status, created_at) VALUES (?, ?, ?, ?, "Pending", NOW())', 
            [tenant_id, issue_type, description, imageUrl]
        );
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/all-reports', async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT r.*, t.name as tenant_name, rm.room_number 
            FROM reports r LEFT JOIN tenants t ON r.tenant_id = t.id 
            LEFT JOIN rooms rm ON t.room_id = rm.id ORDER BY r.created_at DESC`);
        res.json(results);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/update-report-status', async (req, res) => {
    const { report_id, status } = req.body;
    try {
        await db.query("UPDATE reports SET status = ? WHERE id = ?", [status, report_id]);
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ================= 7. PAYMENTS & MONITORING (UPDATED) =================
app.get('/payment-list', async (req, res) => {
    try {
        // Ginagamit ang LEFT JOIN para makuha pati ang may 'pending' status
        const [results] = await db.query(`
            SELECT 
                t.id as tenant_id, 
                t.name as fullname, 
                r.room_number, 
                r.rate as monthly_rate,
                p.id as payment_id,
                p.status as payment_status,
                p.proof_image,
                p.amount as paid_amount
            FROM tenants t 
            JOIN rooms r ON t.room_id = r.id 
            LEFT JOIN payments p ON t.id = p.tenant_id 
                AND MONTH(p.payment_date) = MONTH(CURRENT_DATE()) 
                AND YEAR(p.payment_date) = YEAR(CURRENT_DATE())
            WHERE p.status IS NULL OR p.status = 'pending'
        `);
        res.json(results);
    } catch (err) { 
        console.error("Payment List Error:", err.message);
        res.status(500).json({ error: err.message }); 
    }
});

app.get('/payment-history', async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT p.*, t.name as fullname, r.room_number 
            FROM payments p 
            JOIN tenants t ON p.tenant_id = t.id 
            JOIN rooms r ON t.room_id = r.id 
            WHERE p.status = 'paid'
            ORDER BY p.payment_date DESC`);
        res.json(results);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/tenant-balances', async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT t.name, r.room_number, r.rate,
            (r.rate - IFNULL((SELECT SUM(amount) FROM payments WHERE tenant_id = t.id AND MONTH(payment_date) = MONTH(CURRENT_DATE())), 0)) as balance,
            CASE 
                WHEN (SELECT COUNT(*) FROM payments WHERE tenant_id = t.id AND MONTH(payment_date) = MONTH(CURRENT_DATE())) > 0 THEN 'Paid'
                ELSE 'Overdue'
            END as status
            FROM tenants t
            JOIN rooms r ON t.room_id = r.id`);
        res.json(results);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/pay-rent', async (req, res) => {
    const { tenant_id, amount } = req.body;
    try {
        await db.query('INSERT INTO payments (tenant_id, amount, payment_date, status) VALUES (?, ?, NOW(), "paid")', [tenant_id, amount]);
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/my-payments/:id', async (req, res) => {
    try {
        const [results] = await db.query("SELECT * FROM payments WHERE tenant_id = ? ORDER BY payment_date DESC", [req.params.id]);
        res.json({ success: true, data: results });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/tenant-stats/:id', async (req, res) => {
    const tenantId = req.params.id;
    try {
        const [totalPaid] = await db.query('SELECT SUM(amount) as total FROM payments WHERE tenant_id = ?', [tenantId]);
        const [lastPayment] = await db.query('SELECT amount, payment_date FROM payments WHERE tenant_id = ? ORDER BY payment_date DESC LIMIT 1', [tenantId]);
        const [reportsCount] = await db.query('SELECT COUNT(*) as count FROM reports WHERE tenant_id = ?', [tenantId]);

        res.json({
            success: true,
            totalPaid: totalPaid[0].total || 0,
            lastPaymentAmount: lastPayment.length > 0 ? lastPayment[0].amount : 0,
            lastPaymentDate: lastPayment.length > 0 ? lastPayment[0].payment_date : "No records",
            totalReports: reportsCount[0].count
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- DAGDAG: PARA SA PROOF OF PAYMENT ---
app.post('/submit-proof', upload.single('proof_image'), async (req, res) => {
    const { tenant_id, amount, reference_number } = req.body;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    try {
        const sql = `INSERT INTO payments (tenant_id, amount, payment_date, status, proof_image, reference_no) 
                     VALUES (?, ?, NOW(), 'pending', ?, ?)`;
        await db.query(sql, [tenant_id, amount, imageUrl, reference_number]);
        res.json({ success: true, message: "Proof submitted!" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/approve-payment', async (req, res) => {
    const { payment_id } = req.body;
    try {
        await db.query("UPDATE payments SET status = 'paid' WHERE id = ?", [payment_id]);
        res.json({ success: true, message: "Payment approved!" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.listen(3000, () => console.log('Server is running on port 3000'));