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
router.get('/history', paymentController.getAllPaymentHistory);  

// UPDATED: Para mag-match sa Flutter Rent Monitoring Screen
router.get('/overdue', paymentController.getOverdueTenants);     
router.get('/balances', paymentController.getOverdueTenants);    
router.get('/monitoring/overdue', paymentController.getOverdueTenants); // Dagdag path para sigurado

router.post('/approve', paymentController.approvePayment);       // Approve online proof
router.post('/pay-rent', paymentController.payRent);             // Walk-in/Cash payment recording

// --- TENANT ROUTES ---
router.get('/stats/:id', paymentController.getTenantStats);      // Dashboard stats ng tenant
router.get('/tenant/:id', paymentController.getMyPayments); 
router.get('/my-payments/:id', paymentController.getMyPayments); // Backup route
router.post('/submit-proof', upload.single('proof_image'), paymentController.submitProof); 

module.exports = router;