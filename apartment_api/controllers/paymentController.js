const db = require('../config/db');

// 1. Listahan ng mga dapat magbayad (To Collect - Admin)
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
exports.getTenantStats = async (req, res) => {
    const tenantId = req.params.id;
    try {
        const [totalPaid] = await db.query('SELECT SUM(amount) as total FROM payments WHERE tenant_id = ? AND status = "paid"', [tenantId]);
        const [lastPayment] = await db.query('SELECT amount, payment_date FROM payments WHERE tenant_id = ? AND status = "paid" ORDER BY payment_date DESC LIMIT 1', [tenantId]);
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
exports.getAllPaymentHistory = async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT p.*, t.name as fullname, r.room_number 
            FROM payments p 
            JOIN tenants t ON p.tenant_id = t.id 
            JOIN rooms r ON t.room_id = r.id 
            WHERE p.status = 'paid'
            ORDER BY p.payment_date DESC`);
        res.json(results);
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 7. Tenant Balances / Overdue Logic (Dashboard & Rent Monitoring)
exports.getOverdueTenants = async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT 
                t.name, 
                r.room_number, 
                r.rate as balance,
                CASE 
                    WHEN (SELECT COUNT(*) FROM payments p2 WHERE p2.tenant_id = t.id AND MONTH(p2.payment_date) = MONTH(CURRENT_DATE()) AND p2.status = 'paid') > 0 THEN 'Paid'
                    ELSE 'Overdue'
                END as status
            FROM tenants t
            JOIN rooms r ON t.room_id = r.id
            WHERE t.id NOT IN (
                SELECT tenant_id FROM payments 
                WHERE MONTH(payment_date) = MONTH(CURRENT_DATE()) 
                AND YEAR(payment_date) = YEAR(CURRENT_DATE())
                AND status = 'paid'
            )
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