const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const bodyParser = require('body-parser');

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(bodyParser.json());

app.post('/midtrans-webhook', async (req, res) => {
  try {
    const { order_id, transaction_status } = req.body;

    let status = 'Menunggu Pembayaran';
    if (transaction_status === 'settlement') {
      status = 'Diproses';
    } else if (transaction_status === 'expire' || transaction_status === 'cancel' || transaction_status === 'deny') {
      status = 'Dibatalkan';
    }

    await db.collection('orders').doc(order_id).update({
      status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return res.status(200).send('OK');
  } catch (e) {
    console.error('❌ Error handling webhook:', e);
    return res.status(500).send('Webhook Error');
  }
});

exports.midtransWebhook = functions.https.onRequest(app);
