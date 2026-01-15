require("dotenv").config();

const bcrypt = require("bcryptjs");
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

async function main() {
  const demoEmail = "demo@svu.com";
  const demoPassword = "password123";

  // Reset DB content for a predictable demo.
  await prisma.review.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.delivery.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.menu.deleteMany();
  await prisma.driver.deleteMany();
  await prisma.restaurant.deleteMany();

  const passwordHash = await bcrypt.hash(demoPassword, 10);

  await prisma.user.upsert({
    where: { email: demoEmail },
    update: {},
    create: {
      name: "Demo User",
      email: demoEmail,
      phone: "+963999000111",
      passwordHash,
      address: "Damascus, Syria",
    },
  });

  const r1 = await prisma.restaurant.upsert({
    where: { restaurantId: 1 },
    update: {},
    create: {
      name: "Damascus Bites",
      address: "Al Hamra Street, Damascus",
      phone: "+96311222333",
      rating: 4.6,
      cuisineType: "Syrian",
    },
  });

  const r2 = await prisma.restaurant.upsert({
    where: { restaurantId: 2 },
    update: {},
    create: {
      name: "Pizza Corner",
      address: "Mezzeh Highway, Damascus",
      phone: "+96311444555",
      rating: 4.3,
      cuisineType: "Italian",
    },
  });

  const r3 = await prisma.restaurant.upsert({
    where: { restaurantId: 3 },
    update: {},
    create: {
      name: "Healthy Bowl",
      address: "Abu Rummaneh, Damascus",
      phone: "+96311666777",
      rating: 4.1,
      cuisineType: "Healthy",
    },
  });

  const menus = [
    {
      restaurantId: r1.restaurantId,
      itemName: "Shawarma Wrap",
      description: "Chicken shawarma with garlic sauce and pickles.",
      price: "4.50",
      imageUrl: "https://images.unsplash.com/photo-1604908176997-125f25cc500a?auto=format&fit=crop&w=800&q=60",
      availabilityStatus: "available",
    },
    {
      restaurantId: r1.restaurantId,
      itemName: "Falafel Plate",
      description: "Crispy falafel with hummus and salad.",
      price: "3.75",
      imageUrl: "https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?auto=format&fit=crop&w=800&q=60",
      availabilityStatus: "available",
    },
    {
      restaurantId: r2.restaurantId,
      itemName: "Margherita Pizza",
      description: "Classic pizza with tomato, mozzarella, basil.",
      price: "7.90",
      imageUrl: "https://images.unsplash.com/photo-1601924638867-3ec9a6d8e4f7?auto=format&fit=crop&w=800&q=60",
      availabilityStatus: "available",
    },
    {
      restaurantId: r2.restaurantId,
      itemName: "Pepperoni Pizza",
      description: "Pepperoni, cheese, tomato sauce.",
      price: "8.90",
      imageUrl: "https://images.unsplash.com/photo-1542281286-9e0a16bb7366?auto=format&fit=crop&w=800&q=60",
      availabilityStatus: "available",
    },
    {
      restaurantId: r3.restaurantId,
      itemName: "Chicken Caesar Bowl",
      description: "Grilled chicken, romaine, parmesan, light dressing.",
      price: "6.20",
      imageUrl: "https://images.unsplash.com/photo-1551892374-ecf8754cf8e1?auto=format&fit=crop&w=800&q=60",
      availabilityStatus: "available",
    },
  ];

  for (const m of menus) {
    await prisma.menu.create({ data: m });
  }

  const drivers = [
    { name: "Ahmad", phone: "+963933111222", vehicleType: "Motorbike", availabilityStatus: "available" },
    { name: "Lina", phone: "+963944333444", vehicleType: "Car", availabilityStatus: "available" },
  ];

  for (const d of drivers) {
    await prisma.driver.create({ data: d });
  }

  // eslint-disable-next-line no-console
  console.log("Seeded demo data. Login with username=demo@svu.com password=password123");
}

main()
  .catch((e) => {
    // eslint-disable-next-line no-console
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
