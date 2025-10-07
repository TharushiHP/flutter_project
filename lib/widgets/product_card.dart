import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool showAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.showAddToCart = true,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Card(
              elevation: _isPressed ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              ProductDetailScreen(product: widget.product),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image with Hero animation
                    Expanded(
                      flex: 4,
                      child: Hero(
                        tag: 'product-${widget.product.id}',
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  child: Image.asset(
                                    widget.product.imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color:
                                            Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Stock status badge
                                if (!widget.product.inStock)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Out of Stock',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onError,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Product Details
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Product Name with fade in animation
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: 1.0,
                              child: Text(
                                widget.product.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 1),
                            // Category
                            Text(
                              widget.product.category,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            // Price and Add to Cart
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Rs ${widget.product.price.toStringAsFixed(0)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.showAddToCart &&
                                    widget.product.inStock)
                                  Consumer<CartProvider>(
                                    builder: (context, cartProvider, child) {
                                      final isInCart = cartProvider.isInCart(
                                        widget.product.id.toString(),
                                      );
                                      final quantity = cartProvider.getQuantity(
                                        widget.product.id.toString(),
                                      );

                                      if (isInCart && quantity > 0) {
                                        // Show quantity controls if item is in cart
                                        return Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.remove,
                                                    size: 12,
                                                  ),
                                                  onPressed: () {
                                                    cartProvider.removeItem(
                                                      widget.product.id
                                                          .toString(),
                                                    );
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: Text(
                                                  quantity.toString(),
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 12,
                                                  ),
                                                  onPressed: () {
                                                    cartProvider.addItem(
                                                      widget.product,
                                                    );
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        // Show add to cart button with bounce animation
                                        return AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          scale: _isPressed ? 0.9 : 1.0,
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add_shopping_cart,
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                cartProvider.addItem(
                                                  widget.product,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${widget.product.name} added to cart',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                  ),
                                                );
                                              },
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                foregroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
