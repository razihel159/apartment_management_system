const db = require('../config/db');

// Ito yung dating logic mo sa login na nawala
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
                // Status update logic here
            }
        }
        console.log("Overdue check completed.");
    } catch (err) {
        console.error("Overdue Logic Error:", err.message);
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;
    try {
        await updateOverdueStatus(); // Tinatawag pa rin natin dito
        const [admin] = await db.query('SELECT *, "admin" as role FROM users WHERE email = ? AND password = ?', [email, password]);
        if (admin.length > 0) return res.json({ success: true, role: 'admin', user: admin[0] });

        const [tenant] = await db.query('SELECT *, "tenant" as role FROM tenants WHERE email = ? AND password = ?', [email, password]);
        if (tenant.length > 0) return res.json({ success: true, role: 'tenant', user: tenant[0] });

        res.status(401).json({ success: false, message: "Invalid email or password" });
    } catch (err) { res.status(500).json({ error: err.message }); }
};