import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onBuyPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onBuyPressed,
    this.onCallPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing based on screen dimensions
    final isSmallScreen = screenWidth < 400 || screenHeight < 700;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

    // Dynamic sizing
    final imageHeight = isSmallScreen
        ? 60.0
        : isMediumScreen
        ? 80.0
        : 90.0;
    final cardPadding = isSmallScreen ? 4.0 : 6.0;
    final spacing = isSmallScreen ? 1.0 : 2.0;
    final fontSizeMultiplier = isSmallScreen ? 1.0 : 1.2;

    return Card(
      margin: EdgeInsets.all(isSmallScreen ? 2.0 : 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            Container(
              height: imageHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Colors.grey[100],
              ),
              child: product.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      ),
                    )
                  : _buildPlaceholderImage(),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name with label
                    Row(
                      children: [
                        Text(
                          'Product: ',
                          style: TextStyle(
                            fontSize: (16 * fontSizeMultiplier)
                                .round()
                                .toDouble(),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: (18 * fontSizeMultiplier)
                                  .round()
                                  .toDouble(),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),

                    // Description with label
                    Row(
                      children: [
                        Text(
                          'Details: ',
                          style: TextStyle(
                            fontSize: (15 * fontSizeMultiplier)
                                .round()
                                .toDouble(),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            product.description,
                            style: TextStyle(
                              fontSize: (16 * fontSizeMultiplier)
                                  .round()
                                  .toDouble(),
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),

                    // Price with label
                    Row(
                      children: [
                        Text(
                          'Price: ',
                          style: TextStyle(
                            fontSize: (16 * fontSizeMultiplier)
                                .round()
                                .toDouble(),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            product.displayPrice,
                            style: TextStyle(
                              fontSize: (20 * fontSizeMultiplier)
                                  .round()
                                  .toDouble(),
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),

                    // Price per unit with label
                    Row(
                      children: [
                        Text(
                          'Per: ',
                          style: TextStyle(
                            fontSize: (15 * fontSizeMultiplier)
                                .round()
                                .toDouble(),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            product.pricePerUnit,
                            style: TextStyle(
                              fontSize: (15 * fontSizeMultiplier)
                                  .round()
                                  .toDouble(),
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),

                    // Stock status with label
                    Row(
                      children: [
                        Text(
                          'Stock: ',
                          style: TextStyle(
                            fontSize: (15 * fontSizeMultiplier)
                                .round()
                                .toDouble(),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            product.stockQuantity > 0
                                ? '${product.stockQuantity} left'
                                : 'Out of Stock',
                            style: TextStyle(
                              fontSize: (15 * fontSizeMultiplier)
                                  .round()
                                  .toDouble(),
                              fontWeight: FontWeight.w600,
                              color: product.stockQuantity == 0
                                  ? Colors.red[700]
                                  : product.stockQuantity < 10
                                  ? Colors.red[700]
                                  : product.stockQuantity < 50
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: product.stockQuantity > 0
                                ? onBuyPressed
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 3.0 : 4.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              product.isRentable ? 'Rent' : 'Buy',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: (16 * fontSizeMultiplier)
                                    .round()
                                    .toDouble(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: IconButton(
                            onPressed: onCallPressed,
                            icon: Icon(
                              Icons.phone,
                              size: isSmallScreen ? 12.0 : 14.0,
                              color: Colors.grey[700],
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 3.0 : 4.0),
                            constraints: BoxConstraints(
                              minWidth: isSmallScreen ? 24.0 : 28.0,
                              minHeight: isSmallScreen ? 24.0 : 28.0,
                            ),
                          ),
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Colors.grey[100],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
