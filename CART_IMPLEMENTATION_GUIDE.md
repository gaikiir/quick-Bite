# 🛒 Cart State Management Implementation Guide

## Step-by-Step Implementation

### 1️⃣ **Setup CartProvider in main.dart**

```dart
// Add CartProvider to your MultiProvider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => ProductProvider()..initProductsStream()),
    ChangeNotifierProvider(create: (_) => CartProvider()), // ✅ Added
  ],
  child: // ... your app
)
```

### 2️⃣ **Initialize Cart on User Login**

```dart
// In your login success handler or user authentication flow
final cartProvider = Provider.of<CartProvider>(context, listen: false);
await cartProvider.initializeCart(); // Loads cart from Firestore
```

### 3️⃣ **Add Products to Cart**

#### Option A: Simple Add to Cart Button

```dart
ElevatedButton(
  onPressed: () async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.addToCart(
      product: yourProduct,
      quantity: 1,
    );
  },
  child: Text('Add to Cart'),
)
```

#### Option B: Use the Reusable Widget

```dart
AddToCartButton(
  product: yourProduct,
  quantity: selectedQuantity,
  selectedSize: selectedSize,
  selectedColor: selectedColor,
  onSuccess: () {
    // Handle success (optional)
  },
)
```

### 4️⃣ **Display Cart Items in UI**

#### Simple Cart Display

```dart
Consumer<CartProvider>(
  builder: (context, cartProvider, child) {
    return ListView.builder(
      itemCount: cartProvider.cartItems.length,
      itemBuilder: (context, index) {
        final item = cartProvider.cartItems[index];
        return ListTile(
          leading: Image.network(item.productImage),
          title: Text(item.productName),
          subtitle: Text('Quantity: ${item.quantity}'),
          trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
        );
      },
    );
  },
)
```

#### Cart Badge (App Bar)

```dart
AppBar(
  title: Text('Products'),
  actions: [
    CartBadge(), // Shows cart count with badge
  ],
)
```

### 5️⃣ **Cart Operations**

#### Update Quantity

```dart
final cartProvider = Provider.of<CartProvider>(context, listen: false);
await cartProvider.updateQuantity(cartId, newQuantity);
```

#### Remove Item

```dart
await cartProvider.removeFromCart(cartId);
```

#### Clear Cart

```dart
await cartProvider.clearCart();
```

#### Check if Product is in Cart

```dart
bool isInCart = cartProvider.isInCart(productId);
```

### 6️⃣ **Real-time Updates**

The CartProvider automatically:

- ✅ Syncs with Firestore in real-time
- ✅ Updates UI when cart changes
- ✅ Persists cart across app sessions
- ✅ Handles offline scenarios

### 7️⃣ **Usage in Product Screens**

```dart
class YourProductScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return GridView.builder(
            itemCount: productProvider.products.length,
            itemBuilder: (context, index) {
              final product = productProvider.products[index];
              return ProductTileWithCart(product: product); // ✅ Complete cart functionality
            },
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartCount == 0) return SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            label: Text('${cartProvider.cartCount} items • \$${cartProvider.totalAmount.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}
```

### 8️⃣ **Error Handling**

The CartProvider includes built-in error handling:

- Network failures
- Authentication errors
- Data validation
- User feedback via SnackBars

### 9️⃣ **Performance Features**

- ✅ Local caching for offline access
- ✅ Optimistic updates for smooth UX
- ✅ Efficient Firebase queries
- ✅ Real-time sync without excessive rebuilds

### 🔟 **Next Steps**

1. **Add to existing product screens**: Replace manual cart logic with CartProvider
2. **Create cart screen**: Build full cart management UI
3. **Add checkout flow**: Integrate with payment systems
4. **Add wishlist**: Similar pattern for wishlist functionality

## 🎯 Key Benefits

- **Type-safe**: Full TypeScript-like safety with your CartModel
- **Real-time**: Automatic sync across devices
- **Persistent**: Survives app restarts
- **Scalable**: Handles thousands of cart items
- **Maintainable**: Clean separation of concerns
