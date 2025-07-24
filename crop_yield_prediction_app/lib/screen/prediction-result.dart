import 'package:flutter/material.dart';

class PredictionResultPage extends StatefulWidget {
  final double prediction;
  final Map<String, String> inputData;

  const PredictionResultPage({
    Key? key,
    required this.prediction,
    required this.inputData,
  }) : super(key: key);

  @override
  _PredictionResultPageState createState() => _PredictionResultPageState();
}

class _PredictionResultPageState extends State<PredictionResultPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    Future.delayed(
      Duration(milliseconds: 300),
      () => _scaleController.forward(),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _getYieldCategory(double yield) {
    if (yield > 5000) return 'Excellent';
    if (yield > 3000) return 'Good';
    if (yield > 1500) return 'Average';
    return 'Below Average';
  }

  Color _getYieldColor(double yield) {
    if (yield > 5000) return Colors.green;
    if (yield > 3000) return Colors.lightGreen;
    if (yield > 1500) return Colors.orange;
    return Colors.red;
  }

  IconData _getYieldIcon(double yield) {
    if (yield > 5000) return Icons.trending_up;
    if (yield > 3000) return Icons.thumb_up;
    if (yield > 1500) return Icons.trending_flat;
    return Icons.trending_down;
  }

  @override
  Widget build(BuildContext context) {
    final yieldCategory = _getYieldCategory(widget.prediction);
    final yieldColor = _getYieldColor(widget.prediction);
    final yieldIcon = _getYieldIcon(widget.prediction);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [yieldColor.withOpacity(0.8), yieldColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Prediction Result',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Prediction Result Card
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    yieldColor.withOpacity(0.1),
                                    yieldColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: yieldColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(yieldIcon, size: 60, color: yieldColor),
                                  SizedBox(height: 16),
                                  Text(
                                    'Predicted Yield',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${widget.prediction.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: yieldColor,
                                    ),
                                  ),
                                  Text(
                                    'hg/ha',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: yieldColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      yieldCategory,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 30),

                          // Input Parameters Section
                          Text(
                            'Input Parameters',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Parameters Grid
                          ...widget.inputData.entries.map((entry) {
                            IconData icon;
                            switch (entry.key) {
                              case 'Year':
                                icon = Icons.calendar_today;
                                break;
                              case 'Rainfall':
                                icon = Icons.water_drop;
                                break;
                              case 'Pesticides':
                                icon = Icons.bug_report;
                                break;
                              case 'Temperature':
                                icon = Icons.thermostat;
                                break;
                              case 'Area':
                                icon = Icons.public;
                                break;
                              case 'Crop':
                                icon = Icons.grass;
                                break;
                              default:
                                icon = Icons.info;
                            }

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2E7D32).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          SizedBox(height: 30),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.edit),
                                  label: Text('New Prediction'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              // Expanded(
                              //   child: ElevatedButton.icon(
                              //     onPressed: () {
                              //       // Add share functionality here
                              //       ScaffoldMessenger.of(context).showSnackBar(
                              //         SnackBar(
                              //           content: Text(
                              //             'Share functionality would be implemented here',
                              //           ),
                              //         ),
                              //       );
                              //     },
                              //     icon: Icon(Icons.share),
                              //     label: Text('Share Result'),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Color(0xFF2E7D32),
                              //       foregroundColor: Colors.white,
                              //       padding: EdgeInsets.symmetric(vertical: 14),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(12),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
