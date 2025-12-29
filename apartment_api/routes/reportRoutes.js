const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });

router.post('/submit', upload.single('image'), reportController.submitReport);
router.get('/all', reportController.getAllReports);

// DAGDAG MO ITO: Para gumana ang update button sa Landlord app
router.post('/update-status', reportController.updateReportStatus);

module.exports = router;