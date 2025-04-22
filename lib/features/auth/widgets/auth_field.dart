import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final IconData? prefixIcon;

  const AuthField({
    Key? key,
    required this.label,
    this.hintText,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _AuthFieldState createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              color: AppColors.textSecondary,
            )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : null,
          ),
        ),
      ],
    );
  }
}