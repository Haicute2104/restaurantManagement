const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function: onOrderCompleted
 * Triggers when an order status changes to "completed"
 * Updates daily reports and item reports
 */
exports.onOrderCompleted = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Check if order just changed to completed
    if (previousValue.status !== 'completed' && newValue.status === 'completed') {
      const orderId = context.params.orderId;
      const totalAmount = newValue.totalAmount;
      const items = newValue.items;
      const createdAt = newValue.createdAt.toDate();

      // Get date string (YYYY-MM-DD)
      const dateStr = formatDate(createdAt);
      const hour = createdAt.getHours().toString().padStart(2, '0');

      try {
        // Update daily report
        const dailyReportRef = db.collection('dailyReports').doc(dateStr);
        await db.runTransaction(async (transaction) => {
          const dailyDoc = await transaction.get(dailyReportRef);

          if (!dailyDoc.exists) {
            // Create new daily report
            transaction.set(dailyReportRef, {
              date: dateStr,
              totalRevenue: totalAmount,
              totalOrders: 1,
              itemSalesCount: createItemSalesMap(items),
              hourlyRevenue: { [hour]: totalAmount }
            });
          } else {
            // Update existing daily report
            const data = dailyDoc.data();
            const updatedItemSalesCount = { ...data.itemSalesCount };
            const updatedHourlyRevenue = { ...data.hourlyRevenue };

            // Update item sales count
            items.forEach(item => {
              const currentCount = updatedItemSalesCount[item.itemId] || 0;
              updatedItemSalesCount[item.itemId] = currentCount + item.quantity;
            });

            // Update hourly revenue
            const currentHourRevenue = updatedHourlyRevenue[hour] || 0;
            updatedHourlyRevenue[hour] = currentHourRevenue + totalAmount;

            transaction.update(dailyReportRef, {
              totalRevenue: data.totalRevenue + totalAmount,
              totalOrders: data.totalOrders + 1,
              itemSalesCount: updatedItemSalesCount,
              hourlyRevenue: updatedHourlyRevenue
            });
          }
        });

        // Update item reports
        const itemUpdatePromises = items.map(async (item) => {
          const itemReportRef = db.collection('itemReports').doc(item.itemId);
          return db.runTransaction(async (transaction) => {
            const itemDoc = await transaction.get(itemReportRef);

            if (!itemDoc.exists) {
              transaction.set(itemReportRef, {
                itemId: item.itemId,
                totalSoldAllTime: item.quantity,
                totalRevenueAllTime: item.price * item.quantity
              });
            } else {
              const data = itemDoc.data();
              transaction.update(itemReportRef, {
                totalSoldAllTime: data.totalSoldAllTime + item.quantity,
                totalRevenueAllTime: data.totalRevenueAllTime + (item.price * item.quantity)
              });
            }
          });
        });

        await Promise.all(itemUpdatePromises);

        console.log(`Successfully updated reports for order ${orderId}`);
      } catch (error) {
        console.error('Error updating reports:', error);
      }
    }
  });

/**
 * Cloud Function: onOrderReady
 * Triggers when an order status changes to "ready"
 * 
 * NOTE: Push notifications disabled (no FCM setup)
 * Customers will see status update in real-time via Firestore streams
 */
exports.onOrderReady = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Check if order just changed to ready
    if (previousValue.status !== 'ready' && newValue.status === 'ready') {
      const orderId = context.params.orderId;
      const tableNumber = newValue.tableNumber;

      // Just log it - no push notification
      console.log(`Order ${orderId} at table ${tableNumber} is now ready!`);
      
      // Customer will see status update in real-time via Firestore streams
      // No push notification needed
    }
  });

/**
 * Helper function to format date as YYYY-MM-DD
 */
function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Helper function to create item sales map from order items
 */
function createItemSalesMap(items) {
  const map = {};
  items.forEach(item => {
    map[item.itemId] = item.quantity;
  });
  return map;
}

/**
 * Cloud Function: cleanupOldOrders (Scheduled)
 * Runs daily at midnight to archive orders older than 30 days
 * This is optional - helps keep the main orders collection smaller
 */
exports.cleanupOldOrders = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Ho_Chi_Minh')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      const snapshot = await db.collection('orders')
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .where('status', 'in', ['completed', 'cancelled'])
        .get();

      if (snapshot.empty) {
        console.log('No old orders to cleanup');
        return;
      }

      const batch = db.batch();
      let count = 0;

      snapshot.forEach(doc => {
        // Move to archive collection instead of deleting
        const archiveRef = db.collection('archivedOrders').doc(doc.id);
        batch.set(archiveRef, doc.data());
        batch.delete(doc.ref);
        count++;
      });

      await batch.commit();
      console.log(`Archived ${count} old orders`);
    } catch (error) {
      console.error('Error cleaning up old orders:', error);
    }
  });

