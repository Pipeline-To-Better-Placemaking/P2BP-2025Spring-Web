import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget
{
    @override
    _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
{
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _fullNameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();
    bool _obscureText = true;
    bool _obscureConfirmText = true;
    double _scale = 1.0;

    @override
    void dispose()
    {
        _fullNameController.dispose();
        _emailController.dispose();
        _passwordController.dispose();
        _confirmPasswordController.dispose();
        super.dispose();
    }

    void _togglePasswordVisibility()
    {
        setState(() {
            _obscureText = !_obscureText;
        });
    }

    void _toggleConfirmPasswordVisibility()
    {
        setState(() {
            _obscureConfirmText = !_obscureConfirmText;
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
                        
                        Text
                        (
                            'Create an Account',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),

                        Form
                        (
                            key: _formKey,
                            child: Column
                            (
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                    Center
                                    (
                                        child: Container
                                        (
                                            width: 300,
                                            child: TextFormField
                                            (
                                                controller: _fullNameController,
                                                decoration: InputDecoration
                                                (
                                                    labelText: 'Full Name',
                                                    labelStyle: TextStyle(color: Colors.white),
                                                    enabledBorder: OutlineInputBorder
                                                    (
                                                        borderSide: BorderSide(color: Colors.white),
                                                    ),
                                                    focusedBorder: OutlineInputBorder
                                                    (
                                                        borderSide: BorderSide(color: Colors.lightBlue, width: 2.0),
                                                    ),
                                                    prefixIcon: Icon(Icons.person, color: Colors.white),
                                                ),
                                                style: TextStyle(color: Colors.white),
                                                validator: (value) 
                                                {
                                                    if (value == null || value.isEmpty) 
                                                    {
                                                        return 'Please enter your full name';
                                                    }
                                                    return null;
                                                },
                                            ),
                                        ),
                                    ),
                                    SizedBox(height: 16),

                                    Center
                                    (
                                        child: Container
                                        (
                                            width: 300,
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

                                    Center
                                    (
                                        child: Container
                                        (
                                            width: 300,
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
                                    SizedBox(height: 16),

                                    Center
                                    (
                                        child: Container
                                        (
                                            width: 300,
                                            child: TextFormField
                                            (
                                                controller: _confirmPasswordController,
                                                decoration: InputDecoration
                                                (
                                                    labelText: 'Confirm Password',
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
                                                            _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
                                                            color: Colors.white,
                                                        ),
                                                        onPressed: _toggleConfirmPasswordVisibility,
                                                    ),
                                                ),
                                                obscureText: _obscureConfirmText,
                                                style: TextStyle(color: Colors.white),
                                                validator: (value) 
                                                {
                                                    if (value == null || value.isEmpty) 
                                                    {
                                                        return 'Please confirm your password';
                                                    }
                                                    if (value != _passwordController.text) 
                                                    {
                                                        return 'Passwords do not match';
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
                                                            SnackBar(content: Text('Registering...')),
                                                        );
                                                    }
                                                },
                                                child: Text
                                                (
                                                    'Register',
                                                    style: TextStyle(color: Colors.black),
                                                ),
                                                style: ElevatedButton.styleFrom
                                                (
                                                    backgroundColor: Color(0xFFFFB300),
                                                ),
                                            ),
                                        ),
                                    ),
                                    SizedBox(height: 10),

                                    SizedBox(height: 12),
                                    Column
                                    (
                                        children: 
                                        [
                                            Text
                                            (
                                                'Already have an account?',
                                                style: TextStyle(color: Colors.white),
                                            ),
                                            SizedBox(height: 8),
                                            MouseRegion
                                            (
                                                onEnter: (_) 
                                                {
                                                    setState(() 
                                                    {
                                                        _scale = 0.95;
                                                    });
                                                },
                                                onExit: (_) 
                                                {
                                                    setState(() 
                                                    {
                                                        _scale = 1.0;
                                                    });
                                                },
                                                child: Transform.scale
                                                (
                                                    scale: _scale,
                                                    child: TextButton
                                                    (
                                                        onPressed: () 
                                                        {
                                                            Navigator.pop(context);
                                                        },
                                                        child: Container
                                                        (
                                                            width: 150,
                                                            child: Text
                                                            (
                                                                'Login here',
                                                                style: TextStyle(color: Colors.white),
                                                                textAlign: TextAlign.center,
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ], // Closing of Column for the Form
                            ), // Closing of Form
                        ),
                    ], //Closing of Column
                ), // Closing of Padding
            ), // Closing of Scaffold
        ); // Closing of build method
    } // Closing of _RegisterPageState
} // Closing of ReegisterPage class