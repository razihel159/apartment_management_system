const db = require('../config/db');
const bcrypt = require('bcrypt'); // Siguraduhing na-install ito: npm install bcrypt

// 1. Kunin lahat ng tenants (may JOIN para makuha ang room_number)
exports.getTenants = async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT tenants.*, rooms.room_number 
            FROM tenants 
            LEFT JOIN rooms ON tenants.room_id = rooms.id
        `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 2. Mag-add ng bagong Tenant (ito ang tinatawag ng /register at /add)
exports.addTenant = async (req, res) => {
    const { name, contact, email, password, room_id } = req.body;
    try {
        // Hashing the password before saving for security
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // I-save ang tenant sa database gamit ang hashed password
        await db.query(
            'INSERT INTO tenants (name, contact, email, password, room_id, date_started) VALUES (?, ?, ?, ?, ?, NOW())',
            [name, contact, email, hashedPassword, room_id]
        );

        // Kapag may tenant na, i-update ang status ng kwarto sa 'occupied'
        await db.query('UPDATE rooms SET status = "occupied" WHERE id = ?', [room_id]);

        res.json({ success: true, message: "Tenant registered and room updated!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 3. Kunin ang detalye ng isang specific na tenant
exports.getTenantDetails = async (req, res) => {
    const { id } = req.params;
    try {
        const [rows] = await db.query('SELECT * FROM tenants WHERE id = ?', [id]);
        if (rows.length === 0) return res.status(404).json({ message: "Tenant not found" });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 4. Update Tenant (UPDATED: Support for Profile Edit & Password Hashing)
exports.updateTenant = async (req, res) => {
    const { id } = req.params;
    const { name, contact, email, password, room_id } = req.body;

    try {
        // Build dynamic query para hindi ma-overwrite ang fields na hindi binago
        let query = "UPDATE tenants SET contact = ?, email = ?";
        let params = [contact, email];

        // Isasama lang ang name kung galing sa Admin update
        if (name) {
            query += ", name = ?";
            params.push(name);
        }
        
        // Isasama lang ang room_id kung galing sa Admin update
        if (room_id) {
            query += ", room_id = ?";
            params.push(room_id);
        }

        // CHECK: Kung may pinadalang bagong password, i-hash natin bago i-save
        if (password && password.trim() !== "") {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            
            query += ", password = ?";
            params.push(hashedPassword);
        }

        query += " WHERE id = ?";
        params.push(id);

        const [result] = await db.query(query, params);

        if (result.affectedRows === 0) {
            return res.status(404).json({ success: false, message: "Tenant not found" });
        }

        res.json({ success: true, message: "Profile updated successfully!" });
    } catch (err) {
        console.error("Update Error:", err);
        res.status(500).json({ success: false, error: err.message });
    }
};

// 5. Delete Tenant
exports.deleteTenant = async (req, res) => {
    const { id } = req.params;
    try {
        // Bago i-delete, alamin muna ang room_id para maibalik sa 'available' ang status
        const [tenant] = await db.query('SELECT room_id FROM tenants WHERE id = ?', [id]);
        
        if (tenant.length > 0 && tenant[0].room_id) {
            await db.query('UPDATE rooms SET status = "available" WHERE id = ?', [tenant[0].room_id]);
        }

        await db.query('DELETE FROM tenants WHERE id = ?', [id]);
        res.json({ success: true, message: "Tenant deleted and room set to available!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};