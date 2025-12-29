const db = require('../config/db');

// Submit ng bagong report mula sa Tenant
exports.submitReport = async (req, res) => {
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
    } catch (err) { res.status(500).json({ error: err.message }); }
};

// Kunin lahat ng reports (para sa Admin)
exports.getAllReports = async (req, res) => {
    try {
        const [results] = await db.query(`
            SELECT r.*, t.name as tenant_name, rm.room_number 
            FROM reports r LEFT JOIN tenants t ON r.tenant_id = t.id 
            LEFT JOIN rooms rm ON t.room_id = rm.id ORDER BY r.created_at DESC`);
        res.json(results);
    } catch (err) { res.status(500).json({ error: err.message }); }
};
// Idagdag ito sa pinaka-baba ng reportController.js mo:

exports.updateReportStatus = async (req, res) => {
    const { report_id, status } = req.body;
    try {
        await db.query(
            'UPDATE reports SET status = ? WHERE id = ?',
            [status, report_id]
        );
        res.json({ success: true, message: "Report status updated!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};