const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const multer = require('multer');
const path = require('path');

// Multer Storage Setup para sa Proof of Payment
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage: storage });

// --- ADMIN ROUTES ---
router.get('/list', paymentController.getPaymentList);           // To Collect List
router.get('/history', paymentController.getAllPaymentHistory);  // All Paid Records

// UPDATED: Idinagdag ang /overdue para mag-match sa Flutter Rent Monitoring Screen
router.get('/overdue', paymentController.getOverdueTenants);     
router.get('/balances', paymentController.getOverdueTenants);    // Backup route para sa balances

router.post('/approve', paymentController.approvePayment);       // Approve online proof
router.post('/pay-rent', paymentController.payRent);             // Walk-in/Cash payment recording

// --- TENANT ROUTES ---
router.get('/stats/:id', paymentController.getTenantStats);      // Dashboard stats ng tenant
router.get('/my-payments/:id', paymentController.getMyPayments); // Personal history ng tenant
router.post('/submit-proof', upload.single('proof_image'), paymentController.submitProof); // Mag-send ng screenshot

module.exports = router;