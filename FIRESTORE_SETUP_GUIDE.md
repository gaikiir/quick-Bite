## 🔥 Quick Bite - Complete Setup Guide

### 🚨 **CRITICAL: Image Upload Issues Fixed**

The image upload functionality has been implemented! Images will now properly upload to Cloudinary and display in your app.

---

## 🖼️ **1. Cloudinary Image Upload Setup**

### **Why Cloudinary?**

- ✅ **Free tier** available (25GB storage, 25GB monthly bandwidth)
- ✅ **Global CDN** for fast image delivery
- ✅ **Automatic optimization** and format conversion
- ✅ **Easy integration** with Flutter apps

### **Setup Steps:**

1. **Create Cloudinary Account**: https://console.cloudinary.com/
2. **Get Your Credentials**:

   - **Cloud Name**: Found in your dashboard
   - **Upload Preset**: Create one in Settings > Upload
   - **API Key**: Found in Account Settings > API Keys

3. **Configure Your App**:

   - Open `lib/config/cloudinary_config.dart`
   - Replace placeholder values with your actual credentials:

   ```dart
   static const String cloudName = 'your-actual-cloud-name';
   static const String uploadPreset = 'your-actual-preset-name';
   static const String apiKey = 'your-actual-api-key';
   ```

4. **Create Upload Preset**:
   - Go to Settings > Upload in Cloudinary console
   - Click "Add upload preset"
   - Set Mode to "Unsigned" (for client-side uploads)
   - Save and copy the preset name

### **Testing Image Uploads:**

1. **Login First**: Make sure you're signed into the app
2. **Go to Admin > Add Product**
3. **Select an image** and fill in product details
4. **Submit** - Image will upload to Cloudinary and display immediately
5. **Check product list** - Images should now show properly

### **🔐 Authentication Required**

**IMPORTANT**: All Firestore operations require user authentication. The error you're seeing is because:

1. **Firestore Rules**: Require `request.auth != null` for write operations
2. **User Not Logged In**: Operations fail when no authenticated user
3. **Solution**: Always sign in before performing any database operations

### **How to Fix Authentication Errors:**

1. **Start the app** and go to Login/Register screen
2. **Create an account** or sign in with existing credentials
3. **Verify login** - Check that you're logged in before admin operations
4. **Admin Setup** - Add your user to the `admins` collection in Firestore

### **Common Authentication Issues:**

- ❌ **"You must be logged in to create products"** → Sign in first
- ❌ **Firestore permission denied** → Check authentication status
- ❌ **Network errors** → Ensure stable internet connection

---

---

## 🔧 **2. Current Status**

✅ **Firestore Rules**: Updated and deployed (development-friendly)
✅ **Image Helper**: Created to handle image loading errors
✅ **Image Upload**: Cloudinary integration implemented
⚠️ **Authentication**: Needs verification

---

## 🔐 **3. Authentication Requirements**

The app requires users to be authenticated to access Firestore. Make sure:

### **For Testing:**

1. **Sign up/Login** through the app's authentication screens
2. Verify you're logged in before accessing other features

### **For Admin Access:**

1. Create a user account first
2. Add the user to the `admins` collection in Firestore console
3. Or create an admin directly in code

---

## 🏗️ **4. Manual Admin Setup (Firebase Console)**

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: quick-bite-270f8
3. **Navigate to Firestore Database**
4. **Create/Add to `admins` collection**:
   ```
   Collection: admins
   Document ID: [your-user-uid]
   Data: {
     email: "your-email@example.com",
     role: "admin",
     createdAt: [current timestamp]
   }
   ```

---

## 🛠️ **5. Code-Based Admin Setup**

Add this code to your app for automatic admin creation:

```dart
// In your auth service or main.dart
Future<void> setupAdminUser(String email) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .set({
      'email': email,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## 📱 **5. Image Loading Issues Fixed**

Created `ImageHelper` service to handle:

- ✅ Invalid image URLs
- ✅ Network image loading errors
- ✅ Fallback placeholders
- ✅ Better error handling

**Usage Example:**

```dart
ImageHelper.buildNetworkImage(
  imageUrl: product.productImage,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)
```

---

## 🧪 **6. Testing Steps**

1. **Start the app**: `flutter run`
2. **Register/Login**: Create a test account
3. **Check Firestore**: Verify user document is created
4. **Add admin role**: Follow manual setup above
5. **Test admin features**: Category management, product management

---

## 🔒 **7. Security Notes**

**Current Rules (Development Mode):**

- ✅ Any authenticated user can read/write most collections
- ✅ Public read access for categories and products
- ⚠️ **For Production**: Replace with stricter rules

**Production Rules TODO:**

- Proper admin role checking
- User-specific data access
- Public read only for categories/products

---

## 🐛 **8. Troubleshooting**

### **Still getting permission errors?**

1. Check if user is logged in: `FirebaseAuth.instance.currentUser`
2. Verify network connection
3. Check Firebase project configuration
4. Try logout/login again

### **Image not loading?**

1. Check if URL is valid
2. Use `ImageHelper.buildNetworkImage()` instead of `Image.network()`
3. Verify CORS settings for external images

---

**🎉 Your app should now work without permission errors!**

Test the following flow:

1. Register → Login → Browse Categories → View Products → Add to Cart → Checkout → Payment
