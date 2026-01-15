require("dotenv").config();

const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { z } = require("zod");

const { prisma } = require("./db");

const PORT = Number(process.env.PORT || 3000);
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  throw new Error("JWT_SECRET is required in backend/.env");
}

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/", (req, res) => {
  res.type("html").send(`<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Food Delivery API</title>
    <style>
      body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; padding: 24px; line-height: 1.4; }
      code { background: #f3f4f6; padding: 2px 6px; border-radius: 6px; }
      a { color: #2563eb; text-decoration: none; }
      a:hover { text-decoration: underline; }
      ul { padding-left: 18px; }
    </style>
  </head>
  <body>
    <h2>Food Delivery API</h2>
    <p>This is a REST API server. Try these endpoints:</p>
    <ul>
      <li><a href="/health">/health</a> (server status)</li>
      <li><a href="/restaurants">/restaurants</a> (seeded restaurants)</li>
      <li><code>POST /auth/login</code> (use JSON body)</li>
    </ul>
    <p>If you see <code>Cannot GET /</code>, it just means the server had no homepage.</p>
  </body>
</html>`);
});

function signToken(user) {
  return jwt.sign(
    { sub: String(user.userId), email: user.email, name: user.name },
    JWT_SECRET,
    { expiresIn: "7d" }
  );
}

function authRequired(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing Bearer token" });
  }

  const token = header.slice("Bearer ".length);
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = { userId: Number(payload.sub), email: payload.email, name: payload.name };
    return next();
  } catch {
    return res.status(401).json({ error: "Invalid token" });
  }
}

app.get("/health", (req, res) => {
  res.json({ ok: true, service: "food-delivery-api" });
});

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(6).optional(),
  password: z.string().min(6),
  address: z.string().min(5).optional(),
});

app.post("/auth/register", async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid input", details: parsed.error.flatten() });
  }

  const { name, email, phone, password, address } = parsed.data;
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return res.status(409).json({ error: "Email already registered" });

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: { name, email, phone, passwordHash, address },
    select: { userId: true, name: true, email: true, phone: true, address: true, createdAt: true },
  });

  const token = signToken(user);
  res.status(201).json({ token, user });
});

const loginSchema = z.object({
  username: z.string().min(3),
  password: z.string().min(1),
});

app.post("/auth/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid input", details: parsed.error.flatten() });
  }

  const { username, password } = parsed.data;

  // For this assignment we treat "username" as the email field.
  const userRow = await prisma.user.findUnique({ where: { email: username } });
  if (!userRow) return res.status(401).json({ error: "Invalid credentials" });

  const ok = await bcrypt.compare(password, userRow.passwordHash);
  if (!ok) return res.status(401).json({ error: "Invalid credentials" });

  const user = {
    userId: userRow.userId,
    name: userRow.name,
    email: userRow.email,
    phone: userRow.phone,
    address: userRow.address,
    createdAt: userRow.createdAt,
  };

  const token = signToken(user);
  res.json({ token, user });
});

app.get("/restaurants", async (req, res) => {
  const restaurants = await prisma.restaurant.findMany({
    orderBy: { rating: "desc" },
  });
  res.json(restaurants);
});

app.get("/restaurants/:id/menus", async (req, res) => {
  const restaurantId = Number(req.params.id);
  if (!Number.isFinite(restaurantId)) return res.status(400).json({ error: "Invalid restaurant id" });

  const menus = await prisma.menu.findMany({
    where: { restaurantId },
    orderBy: { itemName: "asc" },
  });
  res.json(menus);
});

const createOrderSchema = z.object({
  restaurantId: z.number().int().positive(),
  items: z
    .array(
      z.object({
        menuId: z.number().int().positive(),
        quantity: z.number().int().positive().max(50),
      })
    )
    .min(1),
  paymentMethod: z.enum(["card", "PayPal", "cash"]),
  address: z.string().min(5),
});

async function pickDriverId() {
  const driver = await prisma.driver.findFirst({
    where: { availabilityStatus: "available" },
    orderBy: { driverId: "asc" },
  });
  return driver ? driver.driverId : null;
}

// in-memory tracking simulation per order
const orderTrackingState = new Map();

function getOrInitTracking(orderId) {
  if (orderTrackingState.has(orderId)) return orderTrackingState.get(orderId);
  const state = {
    lat: 33.5138,
    lng: 36.2765,
    step: 0,
  };
  orderTrackingState.set(orderId, state);
  return state;
}

app.post("/orders", authRequired, async (req, res) => {
  const parsed = createOrderSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid input", details: parsed.error.flatten() });
  }

  const { restaurantId, items, paymentMethod, address } = parsed.data;

  const restaurant = await prisma.restaurant.findUnique({ where: { restaurantId } });
  if (!restaurant) return res.status(404).json({ error: "Restaurant not found" });

  // Update user's address (since the table provides address on Users).
  await prisma.user.update({
    where: { userId: req.user.userId },
    data: { address },
  });

  const menuIds = items.map((i) => i.menuId);
  const menus = await prisma.menu.findMany({
    where: { menuId: { in: menuIds }, restaurantId },
  });

  if (menus.length !== menuIds.length) {
    return res.status(400).json({ error: "One or more menu items not found for this restaurant" });
  }

  const menuById = new Map(menus.map((m) => [m.menuId, m]));

  let total = 0;
  const orderItemsData = items.map((i) => {
    const menu = menuById.get(i.menuId);
    const priceNumber = Number(menu.price);
    total += priceNumber * i.quantity;

    return {
      menuId: menu.menuId,
      quantity: i.quantity,
      price: menu.price,
    };
  });

  const driverId = await pickDriverId();
  if (!driverId) return res.status(503).json({ error: "No drivers available right now" });

  const estimatedTime = new Date(Date.now() + 35 * 60 * 1000);

  const order = await prisma.order.create({
    data: {
      userId: req.user.userId,
      restaurantId,
      orderStatus: "pending",
      totalAmount: String(total.toFixed(2)),
      orderItems: { create: orderItemsData },
      payments: {
        create: {
          paymentMethod,
          paymentStatus: "pending",
          transactionId: null,
          amount: String(total.toFixed(2)),
          paidAt: null,
        },
      },
      delivery: {
        create: {
          driverId,
          deliveryStatus: "assigned",
          estimatedTime,
          actualTime: null,
        },
      },
    },
    include: {
      orderItems: { include: { menu: true } },
      payments: true,
      delivery: { include: { driver: true } },
      restaurant: true,
    },
  });

  await prisma.driver.update({ where: { driverId }, data: { availabilityStatus: "unavailable" } });

  res.status(201).json(order);
});

app.get("/orders/:id", authRequired, async (req, res) => {
  const orderId = Number(req.params.id);
  if (!Number.isFinite(orderId)) return res.status(400).json({ error: "Invalid order id" });

  const order = await prisma.order.findUnique({
    where: { orderId },
    include: {
      orderItems: { include: { menu: true } },
      payments: true,
      delivery: { include: { driver: true } },
      restaurant: true,
    },
  });

  if (!order || order.userId !== req.user.userId) return res.status(404).json({ error: "Order not found" });
  res.json(order);
});

app.post("/orders/:id/pay", authRequired, async (req, res) => {
  const orderId = Number(req.params.id);
  if (!Number.isFinite(orderId)) return res.status(400).json({ error: "Invalid order id" });

  const order = await prisma.order.findUnique({ where: { orderId } });
  if (!order || order.userId !== req.user.userId) return res.status(404).json({ error: "Order not found" });

  await prisma.payment.updateMany({
    where: { orderId, paymentStatus: "pending" },
    data: { paymentStatus: "paid", paidAt: new Date(), transactionId: `TX-${Date.now()}` },
  });

  const updated = await prisma.order.update({
    where: { orderId },
    data: { orderStatus: "confirmed" },
    include: { payments: true },
  });

  res.json(updated);
});

app.get("/orders/:id/tracking", authRequired, async (req, res) => {
  const orderId = Number(req.params.id);
  if (!Number.isFinite(orderId)) return res.status(400).json({ error: "Invalid order id" });

  const order = await prisma.order.findUnique({
    where: { orderId },
    include: { delivery: { include: { driver: true } } },
  });

  if (!order || order.userId !== req.user.userId) return res.status(404).json({ error: "Order not found" });
  if (!order.delivery) return res.status(404).json({ error: "Delivery not found" });

  const state = getOrInitTracking(orderId);
  state.step += 1;

  // Move a little each call.
  state.lat += 0.0006;
  state.lng += 0.0004;

  const etaMinutes = Math.max(2, 35 - state.step * 2);

  res.json({
    orderId: order.orderId,
    orderStatus: order.orderStatus,
    deliveryStatus: order.delivery.deliveryStatus,
    driver: {
      driverId: order.delivery.driver.driverId,
      name: order.delivery.driver.name,
      phone: order.delivery.driver.phone,
      vehicleType: order.delivery.driver.vehicleType,
    },
    driverLocation: { lat: state.lat, lng: state.lng },
    etaMinutes,
    estimatedTime: order.delivery.estimatedTime,
  });
});

app.post("/orders/:id/mark-delivered", authRequired, async (req, res) => {
  const orderId = Number(req.params.id);
  if (!Number.isFinite(orderId)) return res.status(400).json({ error: "Invalid order id" });

  const order = await prisma.order.findUnique({ where: { orderId }, include: { delivery: true } });
  if (!order || order.userId !== req.user.userId) return res.status(404).json({ error: "Order not found" });

  const delivery = await prisma.delivery.update({
    where: { orderId },
    data: { deliveryStatus: "delivered", actualTime: new Date() },
  });

  const updatedOrder = await prisma.order.update({
    where: { orderId },
    data: { orderStatus: "delivered" },
  });

  await prisma.driver.update({ where: { driverId: delivery.driverId }, data: { availabilityStatus: "available" } });

  res.json({ order: updatedOrder, delivery });
});

const reviewSchema = z.object({
  orderId: z.number().int().positive(),
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(500).optional(),
});

app.post("/reviews", authRequired, async (req, res) => {
  const parsed = reviewSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid input", details: parsed.error.flatten() });
  }

  const { orderId, rating, comment } = parsed.data;

  const order = await prisma.order.findUnique({
    where: { orderId },
    include: { delivery: true },
  });

  if (!order || order.userId !== req.user.userId) return res.status(404).json({ error: "Order not found" });
  if (order.orderStatus !== "delivered") return res.status(400).json({ error: "You can review only after delivery" });

  const existing = await prisma.review.findUnique({ where: { orderId } });
  if (existing) return res.status(409).json({ error: "Order already reviewed" });

  const review = await prisma.review.create({
    data: {
      userId: order.userId,
      restaurantId: order.restaurantId,
      orderId,
      rating,
      comment: comment || null,
    },
  });

  // Recalculate restaurant rating (simple average).
  const agg = await prisma.review.aggregate({
    where: { restaurantId: order.restaurantId },
    _avg: { rating: true },
  });

  const avg = agg._avg.rating || 0;
  await prisma.restaurant.update({ where: { restaurantId: order.restaurantId }, data: { rating: avg } });

  res.status(201).json(review);
});

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`API listening on http://localhost:${PORT}`);
});
