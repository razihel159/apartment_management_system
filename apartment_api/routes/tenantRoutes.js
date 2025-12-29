const express = require('express');
const router = express.Router();
const tenantController = require('../controllers/tenantController');

// 1. Kunin lahat ng tenants (Admin List)
// Ginagamit sa Table view ng Tenant Management
router.get('/', tenantController.getTenants);
router.get('/list', tenantController.getTenants);

// 2. Kunin ang detalye ng isang specific na tenant
router.get('/:id', tenantController.getTenantDetails);

// 3. Update at Delete Tenant
router.put('/update/:id', tenantController.updateTenant); 
router.delete('/delete/:id', tenantController.deleteTenant);

// 4. Register o Mag-add ng Tenant
// Ito ang tinatawag ng Flutter 'registerTenant' function mo
router.post('/register', tenantController.addTenant);
router.post('/add', tenantController.addTenant); // Backup route para sa flexibility

module.exports = router;