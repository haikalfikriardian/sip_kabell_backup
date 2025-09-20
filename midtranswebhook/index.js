const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

const MIDTRANS_SERVER_KEY = 'Mid-server-8GZE6S_jMK0kic1AOEDAGSVK'; // sebaiknya simpan di env

exports.midtransWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const signatureKey = req.headers['x-signature-key'];
  const { order_id, status_code, gross_amount } = req.body;

  // 👇 Cek jika signature kosong (kemungkinan test webhook Midtrans)
  if (!signatureKey) {
    console.log('⚠️ Signature kosong, kemungkinan test dari Midtrans dashboard');
    return res.status(200).send('Test notification received');
  }

  // 🔐 Verifikasi Signature
  const expectedSignature = crypto
    .createHash('sha512')
    .update(order_id + status_code + gross_amount + MIDTRANS_SERVER_KEY)
    .digest('hex');

  if (signatureKey !== expectedSignature) {
    console.error('❌ Invalid signature:', signatureKey);
    return res.status(403).send('Invalid signature');
  }

  // ✅ Signature valid, lanjut update status di Firestore
  const transactionStatus = req.body.transaction_status;
  let newStatus = 'Menunggu Pembayaran';

  if (transactionStatus === 'settlement') newStatus = 'Sudah Dibayar';
  else if (transactionStatus === 'cancel' || transactionStatus === 'expire') newStatus = 'Dibatalkan';

  try {
    await db.collection('orders').doc(order_id).update({ status: newStatus });
    console.log(`✅ Order ${order_id} updated to '${newStatus}'`);
    return res.status(200).send('OK');
  } catch (error) {
    console.error('❌ Failed to update Firestore:', error);
    return res.status(500).send('Internal Server Error');
  }
});

// update dummy comment to force deploy
