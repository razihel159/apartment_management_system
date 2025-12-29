const db = require('../config/db');

// 1. Kunin lahat ng Rooms
exports.getRooms = async (req, res) => {
    try {
        const [r] = await db.query('SELECT * FROM rooms');
        res.json(r);
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 2. Kunin ang mga Bakanteng Kwarto
exports.getAvailableRooms = async (req, res) => {
    try {
        const [available] = await db.query('SELECT * FROM rooms WHERE status = "available"');
        res.json(available);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 3. Mag-add ng bagong Room
exports.addRoom = async (req, res) => {
    const { room_number, rate, status } = req.body;
    try {
        await db.query('INSERT INTO rooms (room_number, rate, status) VALUES (?, ?, ?)', 
            [room_number, rate, status || 'available']
        );
        res.json({ success: true, message: "Room added!" });
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 4. Dashboard Statistics
exports.getDashboardStats = async (req, res) => {
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
    } catch (err) { 
        res.status(500).json({ error: err.message }); 
    }
};

// 5. Update Room
exports.updateRoom = async (req, res) => {
    const { id } = req.params;
    const { room_number, rate, status } = req.body;
    try {
        await db.query(
            'UPDATE rooms SET room_number = ?, rate = ?, status = ? WHERE id = ?',
            [room_number, rate, status, id]
        );
        res.json({ success: true, message: "Room updated!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 6. Delete Room
exports.deleteRoom = async (req, res) => {
    const { id } = req.params;
    try {
        await db.query('DELETE FROM rooms WHERE id = ?', [id]);
        res.json({ success: true, message: "Room deleted!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};