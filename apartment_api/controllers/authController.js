const db = require('../config/db');
const bcrypt = require('bcrypt');

exports.login = async (req, res) => {
    const { email, password } = req.body;

    try {
        // 1. TENANT CHECK
        const [rows] = await db.query('SELECT * FROM tenants WHERE email = ?', [email]);

        if (rows.length > 0) {
            const user = rows[0];
            let isMatch = false;

            // FLEXIBLE PASSWORD CHECK
            try {
                // Una: Subukan ang Bcrypt (para sa bagong/updated accounts)
                isMatch = await bcrypt.compare(password, user.password);
            } catch (e) {
                isMatch = false;
            }

            // Pangalawa: Kung hindi match sa bcrypt, i-check kung plain text match 
            // Ito ang papayag sa 'password123' na nasa screenshot mo
            if (!isMatch && password === user.password) {
                isMatch = true;
            }

            if (isMatch) {
                const { password: _, ...userData } = user;
                return res.json({
                    success: true,
                    message: "Login successful!",
                    user: userData,
                    role: 'tenant'
                });
            } else {
                return res.status(401).json({ success: false, message: "Invalid email or password" });
            }
        }

        // 2. ADMIN CHECK (Fixed for 'users' table without 'role' column)
        const [adminRows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
        
        if (adminRows.length > 0) {
            const admin = adminRows[0];
            let isAdminMatch = false;

            if (password === admin.password) {
                isAdminMatch = true;
            } else {
                try {
                    isAdminMatch = await bcrypt.compare(password, admin.password);
                } catch (e) {
                    isAdminMatch = false;
                }
            }

            if (isAdminMatch) {
                const { password: _, ...adminData } = admin;
                return res.json({
                    success: true,
                    message: "Admin login successful!",
                    user: adminData,
                    role: 'admin'
                });
            }
        }

        res.status(401).json({ success: false, message: "Invalid email or password" });

    } catch (err) {
        console.error("Login Error:", err);
        res.status(500).json({ success: false, error: err.message });
    }
};