# 🛒 Fresh Grocery - Flutter MAD Assignment

A comprehensive **Mobile Application Development (MAD)** project built with Flutter, featuring a complete grocery store mobile application with modern UI/UX, state management, and device capabilities integration.

## 📱 Features

### 🏪 **Core E-commerce Features**
- **Product Browsing**: Grid and list views with detailed product information
- **Category Management**: Horizontal category cards with filtering capabilities  
- **Shopping Cart**: Real-time cart with quantity controls and persistent storage
- **Search & Filter**: Advanced search with category, price, and rating filters
- **Product Details**: Comprehensive product views with nutrition info and reviews

### 🔐 **Authentication System**
- **Local Authentication**: SQLite-based user management (primary)
- **User Registration**: Form validation with email and password
- **User Login**: Secure authentication with state persistence
- **Profile Management**: User profile with order history and preferences
- **Hybrid Data**: Users stored locally, products fetched from Railway API

### 🎨 **Modern UI/UX Design**
- **Material Design 3**: Latest Flutter design principles
- **Bottom Navigation**: Professional 4-tab navigation structure
- **Hero Animations**: Smooth product image transitions
- **Loading States**: Progress indicators and skeleton screens
- **Error Handling**: Graceful fallbacks and user-friendly error messages

### 📱 **Device Capabilities Integration**
- **Battery Monitoring**: Real-time battery level display
- **Connectivity Status**: WiFi/Mobile data indicators
- **Location Services**: GPS positioning for store locator
- **Responsive Design**: Adaptive layouts for different screen sizes

### 🛍️ **Enhanced Shopping Experience**
- **Featured Products**: Curated product recommendations
- **Product Reviews**: User ratings and review system
- **Stock Management**: Real-time inventory status
- **Checkout Flow**: Complete order processing workflow

## 🏗️ **Technical Architecture**

### **State Management**
- **Provider Pattern**: Clean and scalable state management
- **AuthProvider**: User authentication state
- **CartProvider**: Shopping cart state with persistence
- **DataProvider**: Product and category data management
- **DeviceCapabilitiesProvider**: Device feature integration

### **Project Structure**
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── models.dart          # Unified data models (Product, User, CartItem, etc.)
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   ├── data_provider.dart
│   └── device_capabilities_provider.dart
├── screens/                 # UI screens
│   ├── main_navigation_screen.dart
│   ├── home_screen.dart
│   ├── categories_screen.dart
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── search_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── profile_screen.dart
├── widgets/                 # Reusable components
│   ├── product_card.dart
│   ├── category_card.dart
│   └── common_widgets.dart
├── services/                # External services
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── product_api_service.dart
├── database/                # Local storage
│   └── database_helper.dart
└── utils/                   # Utilities
    └── constants.dart
```

## 🏗️ **Architecture Overview**

### **Hybrid Local-Cloud Design**
Fresh Grocery implements a **hybrid architecture** combining local storage with cloud API integration:

**Local Components (SQLite):**
- ✅ User Authentication (Register/Login)
- ✅ User Profiles & Preferences  
- ✅ Shopping Cart Persistence
- ✅ Order History
- ✅ App Settings

**Cloud Components (Railway API):**
- ✅ Product Catalog (`/api/products`)
- ✅ Category Data (`/api/categories`) 
- ✅ Real-time Inventory
- ✅ Demo/Testing Features

**Why This Design?**
- **Fast Performance**: Instant login/registration without network dependency
- **Offline Capability**: Core app functions work without internet
- **Scalability**: Easy to add full backend authentication later
- **Development Speed**: Focus on app features rather than backend setup
- **Data Freshness**: Products always up-to-date from live API

### **Database Schema**
- **SQLite Integration**: Local data persistence
- **Unified Models**: Product, User, CartItem, Category, Order
- **Data Relationships**: Proper foreign key relationships
- **Migration Support**: Database versioning and updates

## 🚀 **Getting Started**

### **Prerequisites**
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK / iOS SDK

### **Installation**
1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd assignment
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the Application**
   ```bash
   flutter run
   ```

### **Building for Production**
```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release
```

## 📦 **Dependencies**

### **Core Dependencies**
- `flutter: ^3.24.4` - Flutter framework
- `provider: ^6.1.2` - State management
- `sqflite: ^2.3.3+1` - Local database
- `shared_preferences: ^2.3.2` - Simple data persistence

### **UI Components**
- `cupertino_icons: ^1.0.8` - iOS-style icons
- Material Design 3 components

### **Device Capabilities**
- `geolocator: ^13.0.1` - Location services
- `battery_plus: ^6.0.2` - Battery monitoring
- `connectivity_plus: ^6.0.5` - Network connectivity
- `permission_handler: ^11.3.1` - Runtime permissions

### **Authentication & Storage**
- `firebase_core: ^3.6.0` - Firebase core
- `firebase_auth: ^5.3.1` - Authentication
- `path_provider: ^2.1.4` - File system access

## 🎯 **Key Features Implemented**

### ✅ **Completed Features**
- [x] **Bottom Navigation Structure** - Professional 4-tab navigation
- [x] **Model Integration** - Unified data architecture  
- [x] **Home Screen** - Featured products, categories, search
- [x] **Authentication Screens** - Login, register, profile
- [x] **Cart Management** - Add/remove items, quantity control
- [x] **Product Screens** - Details, nutrition, reviews
- [x] **Search & Filtering** - Advanced product discovery
- [x] **Device Capabilities** - Battery, connectivity, location

### 🎨 **UI/UX Excellence**
- Modern Material Design 3 interface
- Responsive layouts for all screen sizes
- Smooth animations and transitions
- Intuitive navigation patterns
- Accessibility considerations

### ⚡ **Performance Optimizations**
- Efficient list rendering with lazy loading
- Image caching and optimization
- State management best practices
- Memory leak prevention

## 🧪 **Testing**

### **Code Quality**
```bash
# Run static analysis
flutter analyze

# Check for issues
flutter doctor
```

### **Build Verification**
```bash
# Test debug build
flutter build apk --debug

# Test release build
flutter build apk --release
```

## 📚 **Learning Outcomes**

This project demonstrates proficiency in:

1. **Flutter Development**
   - Widget composition and state management
   - Navigation and routing
   - Form handling and validation
   - Async programming and futures

2. **Mobile App Architecture**
   - Provider pattern implementation
   - Service layer architecture
   - Data persistence strategies
   - Error handling patterns

3. **UI/UX Design**
   - Material Design principles
   - Responsive design patterns
   - Animation and micro-interactions
   - Accessibility best practices

4. **Device Integration**
   - Native platform features
   - Permission handling
   - Device capability detection
   - Platform-specific optimizations

## 👨‍💻 **Development Notes**

### **Code Quality Standards**
- Zero compilation errors
- Modern Flutter syntax (no deprecated APIs)
- Proper null safety implementation
- Comprehensive error handling

### **Performance Considerations**
- Optimized image loading with fallbacks
- Efficient state updates with Provider
- Lazy loading for large datasets
- Memory management best practices

## 🔄 **Version History**

- **v1.0.0** - Initial implementation with core features
- **v1.1.0** - Enhanced UI/UX and performance optimizations
- **v1.2.0** - Device capabilities integration
- **v1.3.0** - Final polish and documentation

## 📄 **License**

This project is created for educational purposes as part of the Mobile Application Development course.

---

**Built with ❤️ using Flutter**

*A comprehensive demonstration of modern mobile app development practices and Flutter framework capabilities.*
