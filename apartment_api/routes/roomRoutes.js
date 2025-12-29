const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');

// Lahat ng ito ay dapat naka-export sa roomController.js
router.get('/', roomController.getRooms); 
router.post('/add', roomController.addRoom); 
router.get('/dashboard-stats', roomController.getDashboardStats); 

// Route para sa dropdown sa Flutter
router.get('/available', roomController.getAvailableRooms); 

router.put('/update/:id', roomController.updateRoom); 
router.delete('/delete/:id', roomController.deleteRoom); 

module.exports = router;