import 'package:flutter/material.dart';
import 'Register.dart';

class LoginPage extends StatefulWidget
{
    @override
    _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
{
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    bool _obscureText = true; // Toggle for password visibility

    @override
    void dispose()
    {
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    void _togglePasswordVisibility()
    {
        setState(() 
        {
            _obscureText = !_obscureText;
        });
    }

    @override
    Widget build(BuildContext context)
    {
        return Scaffold
        (
            backgroundColor: Color(0xFF1A237E),
            body: Padding
            (
                padding: const EdgeInsets.all(16.0),
                child: Column
                (
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                        Center
                        (
                            child: Image.asset
                            (
                                'assets/icons/PTBP.png',
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                            ),
                        ),
                        SizedBox(height: 16),

                        Column
                        (
                            children: 
                            [
                                Text
                                (
                                    'Welcome!',
                                    style: TextStyle
                                    (
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),

                                Text
                                (
                                    'Please login',
                                    style: TextStyle
                                    (
                                        fontSize: 20,
                                        color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                ),
                            ],
                        ),
                        SizedBox(height: 24),

                        Form
                        (
                            key: _formKey,
                            child: Column
                            (
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                    // Email field with limited width
                                    Center
                                    (
                                        child: Container
                                        (
                                            width: 300, // Set desired width here
                                            child: TextFormField
                                            (
                                                controller: _emailController,
                                                decoration: InputDecoration
                                                (
                                                    labelText: 'Email',
                                                    labelStyle: TextStyle(color: Colors.white),
                                                    enabledBorder: OutlineInputBorder
                                                    (
                                                        borderSide: BorderSide(color: Colors.white),
                                                    ),
                                                    focusedBorder: OutlineInputBorder
                                                    (
                                                        borderSide: BorderSide(color: Colors.lightBlue, width: 2.0),
                                                    ),
                                                    prefixIcon: Icon(Icons.email, color: Colors.white),
                                                ),
                                                keyboardType: TextInputType.emailAddress,
                                                style: TextStyle(color: Colors.white),
                                                validator: (value) 
                                                {
                                                    if (value == null || value.isEmpty) 
                                                    {
                                                        return 'Please enter your email';
                                                    }
                                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) 
                                                    {
                                                        return 'Please enter a valid email address';
                                                    }
                                                    return null;
                                                },
                                            ),
                                        ),
                                    ),
                                    SizedBox(height: 16),

                                    // Password field with limited width
                                    Center
                                    (
                                        child: Container
                                        (
                                            width: 300, // Set desired width here
                                            child: TextFormField
                                            (
                                                controller: _passwordController,
                                                decoration: InputDecoration
                                                (
                                                    labelText: 'Password',
                                                    labelStyle: TextStyle(color: Colors.white),
                                                    enabledBorder: OutlineInputBorder
                                                    (
                                                        borderSide: BorderSide(color: Colors.white),
                                                    ),
                                                    focusedBorder: OutlineInputBorder
                                                    (
                                                        borderSide: BorderSide(color: Colors.lightBlue, width: 2.0),
                                                    ),
                                                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                                                    suffixIcon: IconButton
                                                    (
                                                        icon: Icon
                                                        (
                                                            _obscureText ? Icons.visibility : Icons.visibility_off,
                                                            color: Colors.white,
                                                        ),
                                                        onPressed: _togglePasswordVisibility,
                                                    ),
                                                ),
                                                obscureText: _obscureText,
                                                style: TextStyle(color: Colors.white),
                                                validator: (value) 
                                                {
                                                    if (value == null || value.isEmpty) 
                                                    {
                                                        return 'Please enter your password';
                                                    }
                                                    return null;
                                                },
                                            ),
                                        ),
                                    ),
                                    SizedBox(height: 24),

                                    Align
                                    (
                                        alignment: Alignment.center,
                                        child: Container
                                        (
                                            width: 150,
                                            child: ElevatedButton
                                            (
                                                onPressed: () 
                                                {
                                                    if (_formKey.currentState!.validate()) 
                                                    {
                                                        ScaffoldMessenger.of(context).showSnackBar
                                                        (
                                                            SnackBar(content: Text('Logging in...')),
                                                        );
                                                    }
                                                },
                                                child: Text
                                                (
                                                    'Login',
                                                    style: TextStyle(color: Colors.black),
                                                ),
                                                style: ElevatedButton.styleFrom
                                                (
                                                    backgroundColor: Color(0xFFFFB300),
                                                ),
                                            ),
                                        ),
                                    ),
                                    SizedBox(height: 18),

                                    Column
                                    (
                                        children: 
                                        [
                                            Text
                                            (
                                                'New here?',
                                                style: TextStyle(color: Colors.white),
                                            ),
                                            SizedBox(height: 6),
                                            TextButton
                                            (
                                                onPressed: () 
                                                {
                                                    Navigator.push
                                                    (
                                                        context,
                                                        MaterialPageRoute(builder: (context) => RegisterPage()),
                                                    );
                                                },
                                                child: Text
                                                (
                                                    'Create an account',
                                                    style: TextStyle(color: Colors.white),
                                                ),
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}