const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', service: 'document-verifier', version: '1.1.0' });
});

app.post('/verify', (req, res) => {
  console.log('Document verification request received:', req.body);
  
  res.status(200).json({
    success: true,
    message: 'Document verification completed',
    result: 'verified'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Document Verifier service started on port ${PORT}`);
});

module.exports = app;