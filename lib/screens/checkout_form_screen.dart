import 'package:flutter/material.dart';
import '../models/cart.dart';
import 'package:flutter/services.dart';

class CheckoutFormScreen extends StatefulWidget {
  const CheckoutFormScreen({super.key});

  @override
  State<CheckoutFormScreen> createState() => _CheckoutFormScreenState();
}

class _CheckoutFormScreenState extends State<CheckoutFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _instructionsController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  } else if (value.length != 10) {
                    return 'Phone number must consist only 10 digits';
                  }
                  return null;
                },
              ),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),

              // Delivery Date Picker
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Text(
                  _selectedDate == null
                      ? 'Choose Delivery Date'
                      : 'Delivery Date: ${_selectedDate!.toLocal()}'.split(
                        ' ',
                      )[0],
                ),
              ),

              // Payment Method Dropdown
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Payment Method'),
                value: _selectedPaymentMethod,
                items:
                    ['Cash', 'Card']
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
                validator:
                    (value) => value == null ? 'Select a payment method' : null,
              ),

              // Delivery Instructions
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Instructions (Optional)',
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order placed successfully!'),
                      ),
                    );
                    Cart.clear();

                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    });
                  }
                },
                child: const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
