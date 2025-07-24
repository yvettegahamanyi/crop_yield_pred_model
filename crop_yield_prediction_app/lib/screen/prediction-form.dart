import 'package:crop_yield_prediction_app/screen/prediction-result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CropPredictionForm extends StatefulWidget {
  @override
  _CropPredictionFormState createState() => _CropPredictionFormState();
}

class _CropPredictionFormState extends State<CropPredictionForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _rainfallController = TextEditingController();
  final _pesticidesController = TextEditingController();
  final _temperatureController = TextEditingController();

  String? _selectedArea;
  String? _selectedCrop;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _areas = [
    'Algeria',
    'Angola',
    'Benin',
    'Botswana',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cameroon',
    'Central African Republic',
    'Chad',
    'Comoros',
    'Congo (Brazzaville)',
    'Congo (Kinshasa)',
    'Djibouti',
    'Egypt',
    'Equatorial Guinea',
    'Eritrea',
    'Eswatini',
    'Ethiopia',
    'Gabon',
    'Gambia',
    'Ghana',
    'Guinea',
    'Guinea-Bissau',
    'Ivory Coast',
    'Kenya',
    'Lesotho',
    'Liberia',
    'Libya',
    'Madagascar',
    'Malawi',
    'Mali',
    'Mauritania',
    'Mauritius',
    'Morocco',
    'Mozambique',
    'Namibia',
    'Niger',
    'Nigeria',
    'Rwanda',
    'Sao Tome and Principe',
    'Senegal',
    'Seychelles',
    'Sierra Leone',
    'Somalia',
    'South Africa',
    'South Sudan',
    'Sudan',
    'Tanzania',
    'Togo',
    'Tunisia',
    'Uganda',
    'Zambia',
    'Zimbabwe',
  ];

  final List<String> _crops = [
    "Maize",
    "Potatoes",
    "Rice, paddy",
    "Sorghum",
    "Soybeans",
    "Wheat",
    "Cassava",
    "Sweet potatoes",
    "Plantains and others",
    "Yams",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _yearController.dispose();
    _rainfallController.dispose();
    _pesticidesController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(fontSize: 16)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
        isExpanded: true,
        menuMaxHeight: 300,
      ),
    );
  }

  Future<void> _makePrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://crop-yield-api-bocj.onrender.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'year': int.parse(_yearController.text),
          'average_rain_fall_mm_per_year': double.parse(
            _rainfallController.text,
          ),
          'pesticides_tonnes': double.parse(_pesticidesController.text),
          'avg_temp': double.parse(_temperatureController.text),
          'area': _selectedArea,
          'item': _selectedCrop,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionResultPage(
              prediction: data['predicted_yield'],
              inputData: {
                'Year': _yearController.text,
                'Rainfall': '${_rainfallController.text} mm/year',
                'Pesticides': '${_pesticidesController.text} tonnes',
                'Temperature': '${_temperatureController.text}°C',
                'Area': _selectedArea!,
                'Crop': _selectedCrop!,
              },
            ),
          ),
        );
      } else {
        _showErrorDialog('Failed to get prediction. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Network error. Please check your connection.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.agriculture, size: 60, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'Crop Yield Predictor',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Enter crop details to predict yield',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Form Container
                Expanded(
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
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Prediction Parameters',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 30),

                            _buildInputField(
                              controller: _yearController,
                              label: 'Year',
                              hint: 'Enter year (1961-2030)',
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a year';
                                }
                                int? year = int.tryParse(value);
                                if (year == null ||
                                    year < 1961 ||
                                    year > 2030) {
                                  return 'Year must be between 1961 and 2030';
                                }
                                return null;
                              },
                            ),

                            _buildInputField(
                              controller: _rainfallController,
                              label: 'Average Rainfall',
                              hint: 'Enter rainfall in mm/year',
                              icon: Icons.water_drop,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter rainfall amount';
                                }
                                double? rainfall = double.tryParse(value);
                                if (rainfall == null ||
                                    rainfall < 0 ||
                                    rainfall > 5000) {
                                  return 'Rainfall must be between 0 and 5000 mm';
                                }
                                return null;
                              },
                            ),

                            _buildInputField(
                              controller: _pesticidesController,
                              label: 'Pesticides Usage',
                              hint: 'Enter pesticides in tonnes',
                              icon: Icons.bug_report,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter pesticides amount';
                                }
                                double? pesticides = double.tryParse(value);
                                if (pesticides == null || pesticides < 0) {
                                  return 'Pesticides amount must be positive';
                                }
                                return null;
                              },
                            ),

                            _buildInputField(
                              controller: _temperatureController,
                              label: 'Average Temperature',
                              hint: 'Enter temperature in °C',
                              icon: Icons.thermostat,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter temperature';
                                }
                                double? temp = double.tryParse(value);
                                if (temp == null || temp < -10 || temp > 50) {
                                  return 'Temperature must be between -10°C and 50°C';
                                }
                                return null;
                              },
                            ),

                            _buildDropdownField(
                              label: 'Country/Area',
                              value: _selectedArea,
                              items: _areas,
                              onChanged: (value) =>
                                  setState(() => _selectedArea = value),
                              icon: Icons.public,
                            ),

                            _buildDropdownField(
                              label: 'Crop Type',
                              value: _selectedCrop,
                              items: _crops,
                              onChanged: (value) =>
                                  setState(() => _selectedCrop = value),
                              icon: Icons.grass,
                            ),

                            SizedBox(height: 30),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _makePrediction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Predicting...',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.analytics, size: 24),
                                        SizedBox(width: 8),
                                        Text(
                                          'Predict Yield',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
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
      ),
    );
  }
}
