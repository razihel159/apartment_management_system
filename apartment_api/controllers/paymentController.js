const db = require('../config/db');

// 1. Listahan ng mga dapat magbayad (To Collect - Admin)
// paymentController.js - UPDATED getPaymentList
exports.getPaymentList = async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT 
                t.id as tenant_id, 
                t.name as fullname, 
                r.room_number, 
                r.rate as monthly_rate,
                p.id as payment_id,
                p.status as payment_status,
                p.proof_image,
                -- UPDATE: Kung NULL ang payment amount, ipakita ang monthly rate ng room
                COALESCE(p.amount, r.rate) as paid_amount
            FROM tenants t 
            JOIN rooms r ON t.room_id = r.id 
            LEFT JOIN payments p ON t.id = p.tenant_id 
                AND MONTH(p.payment_date) = MONTH(CURRENT_DATE()) 
                AND YEAR(p.payment_date) = YEAR(CURRENT_DATE())
            -- Isama ang mga 'pending' at yung mga wala pang record (NULL) para sa buwan na ito
            WHERE p.status IS NULL OR p.status = 'pending'
        `);
        res.json(results);
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 2. Approval ng Online Payment (Admin)
exports.approvePayment = async (req, res) => {
    const { payment_id } = req.body;
    try {
        await db.query("UPDATE payments SET status = 'paid' WHERE id = ?", [payment_id]);
        res.json({ success: true, message: "Payment approved!" });
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 3. Submission ng Proof (Tenant App)
exports.submitProof = async (req, res) => {
    const { tenant_id, amount, reference_number } = req.body;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    try {
        const sql = `INSERT INTO payments (tenant_id, amount, payment_date, status, proof_image, reference_no) 
                     VALUES (?, ?, NOW(), 'pending', ?, ?)`;
        await db.query(sql, [tenant_id, amount, imageUrl, reference_number]);
        res.json({ success: true, message: "Proof submitted successfully!" });
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 4. Tenant Stats (Para sa Home/Profile ng Tenant)
// 4. Tenant Stats (Para sa Home/Profile ng Tenant) - UPDATED VERSION
exports.getTenantStats = async (req, res) => {
    const tenantId = req.params.id;
    try {
        // Kumuha ng Room Number at Rate direkta mula sa table ng rooms gamit ang JOIN
        const [roomInfo] = await db.query(`
            SELECT r.room_number, r.rate 
            FROM tenants t 
            JOIN rooms r ON t.room_id = r.id 
            WHERE t.id = ?`, [tenantId]);

        const [totalPaid] = await db.query('SELECT SUM(amount) as total FROM payments WHERE tenant_id = ? AND status = "paid"', [tenantId]);
        const [lastPayment] = await db.query('SELECT amount, payment_date FROM payments WHERE tenant_id = ? AND status = "paid" ORDER BY payment_date DESC LIMIT 1', [tenantId]);
        const [reportsCount] = await db.query('SELECT COUNT(*) as count FROM reports WHERE tenant_id = ?', [tenantId]);

        res.json({
            success: true,
            // Ito ang mga fields na kailangan ng Flutter app:
            room_number: roomInfo.length > 0 ? roomInfo[0].room_number : "---",
            monthly_rent: roomInfo.length > 0 ? roomInfo[0].rate : 0,
            totalPaid: totalPaid[0].total || 0,
            lastPaymentAmount: lastPayment.length > 0 ? lastPayment[0].amount : 0,
            lastPaymentDate: lastPayment.length > 0 ? lastPayment[0].payment_date : "No records",
            totalReports: reportsCount[0].count
        });
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 5. My Payments (History ng isang specific na Tenant)
exports.getMyPayments = async (req, res) => {
    try {
        const [results] = await db.query("SELECT * FROM payments WHERE tenant_id = ? ORDER BY payment_date DESC", [req.params.id]);
        res.json({ success: true, data: results });
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 6. Payment History (Admin - Lahat ng bayad na 'paid')
// paymentController.js - UPDATED getMyPayments
exports.getMyPayments = async (req, res) => {
    try {
        // Nagdagdag ng JOIN sa rooms para makita ni tenant kung anong room ang binayaran niya
        const [results] = await db.query(`
            SELECT p.*, r.room_number 
            FROM payments p
            JOIN tenants t ON p.tenant_id = t.id
            JOIN rooms r ON t.room_id = r.id
            WHERE p.tenant_id = ? 
            ORDER BY p.payment_date DESC
        `, [req.params.id]);
        
        res.json({ success: true, data: results });
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 7. Tenant Balances / Overdue Logic (Dashboard & Rent Monitoring)
// 7. Tenant Balances / Overdue Logic (Dashboard & Rent Monitoring)
exports.getOverdueTenants = async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT 
                t.name, 
                r.room_number, 
                r.rate as balance,
                CASE 
                    WHEN p.status = 'pending' THEN 'Pending'
                    ELSE 'Overdue'
                END as status
            FROM tenants t
            JOIN rooms r ON t.room_id = r.id
            LEFT JOIN payments p ON t.id = p.tenant_id 
                AND MONTH(p.payment_date) = MONTH(CURRENT_DATE()) 
                AND YEAR(p.payment_date) = YEAR(CURRENT_DATE())
            -- Ito ang nagpapalabas sa 4th tenant: Isama lahat ng walang bayad O hindi pa 'paid' ang status
            WHERE p.id IS NULL OR p.status != 'paid'
        `);
        res.json(results);
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 8. Walk-in/Cash Payment Recording (Admin)
exports.payRent = async (req, res) => {
    const { tenant_id, amount } = req.body;
    try {
        await db.query(
            "INSERT INTO payments (tenant_id, amount, payment_date, status) VALUES (?, ?, NOW(), 'paid')",
            [tenant_id, amount]
        );
        res.json({ success: true, message: "Cash payment recorded!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 9. Payment History (Admin - Lahat ng bayad na 'paid')
exports.getAllPaymentHistory = async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT p.*, t.name as fullname, r.room_number 
            FROM payments p 
            JOIN tenants t ON p.tenant_id = t.id 
            JOIN rooms r ON t.room_id = r.id 
            WHERE p.status = 'paid'
            ORDER BY p.payment_date DESC
        `);
        res.json(results);
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};