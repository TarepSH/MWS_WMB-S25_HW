// End-to-end API smoke test (no Flutter required)
// Runs: login -> restaurants -> menus -> create order -> pay -> tracking -> delivered -> review
// Usage: node scripts/smoke-test.js

require('dotenv').config();

const BASE_URL = process.env.API_BASE_URL || `http://localhost:${process.env.PORT || 3001}`;

async function http(method, path, { token, body } = {}) {
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { _nonJson: text };
  }

  if (!res.ok) {
    const err = new Error(`${method} ${path} failed: ${res.status}`);
    err.status = res.status;
    err.body = json;
    throw err;
  }

  return json;
}

function assert(cond, msg) {
  if (!cond) throw new Error(`Assertion failed: ${msg}`);
}

(async () => {
  console.log(`Base URL: ${BASE_URL}`);

  const health = await http('GET', '/health');
  assert(health && health.ok === true, 'health.ok');
  console.log('Health OK');

  const login = await http('POST', '/auth/login', {
    body: { username: 'demo@svu.com', password: 'password123' },
  });

  assert(typeof login.token === 'string' && login.token.length > 10, 'login.token');
  const token = login.token;
  console.log('Login OK');

  const restaurants = await http('GET', '/restaurants');
  assert(Array.isArray(restaurants) && restaurants.length >= 1, 'restaurants');
  const restaurantId = restaurants[0].restaurantId;
  console.log(`Restaurants OK (using restaurantId=${restaurantId})`);

  const menus = await http('GET', `/restaurants/${restaurantId}/menus`);
  assert(Array.isArray(menus) && menus.length >= 1, 'menus');
  const firstMenuId = menus[0].menuId;
  console.log(`Menus OK (using menuId=${firstMenuId})`);

  const order = await http('POST', '/orders', {
    token,
    body: {
      restaurantId,
      items: [{ menuId: firstMenuId, quantity: 2 }],
      paymentMethod: 'card',
      address: 'Damascus, Syria',
    },
  });

  assert(typeof order.orderId === 'number', 'order.orderId');
  const orderId = order.orderId;
  console.log(`Order created OK (orderId=${orderId})`);

  await http('POST', `/orders/${orderId}/pay`, { token });
  console.log('Payment OK');

  const tracking = await http('GET', `/orders/${orderId}/tracking`, { token });
  assert(tracking && tracking.orderId === orderId, 'tracking.orderId');
  assert(tracking.driver && tracking.driver.name, 'tracking.driver');
  console.log(`Tracking OK (ETA=${tracking.etaMinutes} min)`);

  await http('POST', `/orders/${orderId}/mark-delivered`, { token });
  console.log('Delivered OK');

  const review = await http('POST', '/reviews', {
    token,
    body: { orderId, rating: 5, comment: 'Great delivery (demo)' },
  });

  assert(review && review.orderId === orderId, 'review.orderId');
  console.log('Review OK');

  console.log('SMOKE TEST PASSED');
})().catch((e) => {
  console.error('SMOKE TEST FAILED');
  console.error(e && e.message ? e.message : e);
  if (e && e.body) console.error('Response body:', JSON.stringify(e.body, null, 2));
  process.exit(1);
});
