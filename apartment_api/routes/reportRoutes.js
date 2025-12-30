const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });

// Binago mula /submit -> /add para mag-match sa Flutter ApiService
router.post('/add', upload.single('image'), reportController.submitReport);

// Kunin lahat ng reports (Landlord view)
router.get('/all', reportController.getAllReports);

// DAGDAG ITO: Para sa listahan ni Tenant ('My Reports' screen)
// Ito ang tinatawag ng ApiService.getTenantReports(id)
router.get('/tenant/:id', reportController.getReportsByTenant);

// Para sa update button ng Landlord
router.post('/update-status', reportController.updateReportStatus);

module.exports = router;