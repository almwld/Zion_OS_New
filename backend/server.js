require('dotenv').config();
const express = require('express');
const cors = require('cors');
const otpRoutes = require('./routes/otp');

const app = express();
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/otp', otpRoutes);

// Auth mock routes (للتطبيق يشتغل)
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  res.json({
    success: true,
    token: 'test_token_123',
    user: {
      id: '1',
      full_name: 'مستخدم صحتك',
      email: email,
      phone: email
    }
  });
});

app.post('/api/auth/register', (req, res) => {
  res.json({
    success: true,
    token: 'test_token_123'
  });
});

app.get('/api/auth/profile', (req, res) => {
  res.json({
    success: true,
    data: {
      id: '1',
      full_name: 'مستخدم صحتك',
      email: 'test@sehatak.com',
      phone: '770123456'
    }
  });
});

app.get('/api/doctors', (req, res) => {
  res.json([
    { id: '1', full_name: 'د. محمد العبادي', specialization: 'قلبية', rating: 4.8, price: 5000 },
    { id: '2', full_name: 'د. أحمد الريمي', specialization: 'أطفال', rating: 4.6, price: 3000 },
    { id: '3', full_name: 'د. سارة الحضرمي', specialization: 'نسائية', rating: 4.9, price: 4000 }
  ]);
});

app.get('/api/doctors/:id', (req, res) => {
  res.json({
    id: req.params.id,
    full_name: 'د. محمد العبادي',
    specialization: 'قلبية',
    rating: 4.8,
    price: 5000,
    experience: 15,
    about: 'استشاري أمراض قلبية'
  });
});

app.post('/api/consultations', (req, res) => {
  res.json({ success: true, message: 'تم حجز الاستشارة' });
});

app.post('/api/orders', (req, res) => {
  res.json({ success: true, order_id: '12345' });
});

app.get('/api/notifications', (req, res) => {
  res.json([]);
});

app.get('/health', (req, res) => res.json({ status: 'UP' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 API on ${PORT}`));
