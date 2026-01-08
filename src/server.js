const express = require('express');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({
    contentSecurityPolicy: false
}));
app.use(compression());
app.use(express.static(path.join(__dirname, 'public')));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Sample product data
const products = [
    {
        id: 1,
        name: "Premium Wireless Headphones",
        price: 299.99,
        originalPrice: 399.99,
        image: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400",
        description: "Experience crystal-clear audio with our premium wireless headphones.",
        category: "Electronics",
        rating: 4.8,
        reviews: 1234,
        features: ["Active Noise Cancellation", "30-Hour Battery", "Premium Comfort", "Bluetooth 5.0"]
    },
    {
        id: 2,
        name: "Smart Watch Pro",
        price: 449.99,
        originalPrice: 549.99,
        image: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400",
        description: "Stay connected and track your fitness with our Smart Watch Pro.",
        category: "Electronics",
        rating: 4.6,
        reviews: 892,
        features: ["GPS Tracking", "Heart Rate Monitor", "Water Resistant", "7-Day Battery"]
    },
    {
        id: 3,
        name: "Leather Messenger Bag",
        price: 189.99,
        originalPrice: 249.99,
        image: "https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400",
        description: "Handcrafted genuine leather messenger bag for work or travel.",
        category: "Fashion",
        rating: 4.9,
        reviews: 567,
        features: ["Genuine Leather", "Laptop Sleeve", "Multiple Compartments", "Adjustable Strap"]
    },
    {
        id: 4,
        name: "Minimalist Desk Lamp",
        price: 79.99,
        originalPrice: 99.99,
        image: "https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400",
        description: "Modern minimalist desk lamp with adjustable brightness.",
        category: "Home",
        rating: 4.5,
        reviews: 345,
        features: ["Adjustable Brightness", "Color Temperature Control", "USB Charging", "Touch Controls"]
    },
    {
        id: 5,
        name: "Portable Bluetooth Speaker",
        price: 129.99,
        originalPrice: 179.99,
        image: "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400",
        description: "Waterproof portable Bluetooth speaker with 360 sound.",
        category: "Electronics",
        rating: 4.7,
        reviews: 789,
        features: ["Waterproof IPX7", "360 Sound", "20-Hour Playtime", "Built-in Mic"]
    },
    {
        id: 6,
        name: "Organic Coffee Beans",
        price: 24.99,
        originalPrice: 34.99,
        image: "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400",
        description: "Premium organic coffee beans from sustainable farms.",
        category: "Food",
        rating: 4.8,
        reviews: 1567,
        features: ["Organic Certified", "Fair Trade", "Medium Roast", "Sustainable"]
    }
];

// Health check for Kubernetes
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || '1.0.0'
    });
});

app.get('/ready', (req, res) => {
    res.status(200).json({ status: 'ready', timestamp: new Date().toISOString() });
});

// Landing page
app.get('/', (req, res) => {
    res.render('index', { products: products, title: 'ShopEase - Your Favorite Online Store' });
});

// Product detail page
app.get('/product/:id', (req, res) => {
    const productId = parseInt(req.params.id);
    const product = products.find(p => p.id === productId);
    
    if (!product) {
        return res.status(404).render('404', { title: 'Product Not Found' });
    }
    
    const relatedProducts = products
        .filter(p => p.category === product.category && p.id !== product.id)
        .slice(0, 3);
    
    res.render('product', { product, relatedProducts, title: product.name + ' - ShopEase' });
});

// API endpoints
app.get('/api/products', (req, res) => res.json(products));

app.get('/api/products/:id', (req, res) => {
    const product = products.find(p => p.id === parseInt(req.params.id));
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json(product);
});

// 404 handler
app.use((req, res) => res.status(404).render('404', { title: 'Page Not Found' }));

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log('Server running on http://0.0.0.0:' + PORT);
    console.log('Version: ' + (process.env.APP_VERSION || '1.0.0'));
});

module.exports = app;
