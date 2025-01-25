import 'package:flutter/material.dart';

class CreateProjectDetails extends StatefulWidget {
  const CreateProjectDetails({super.key});

  @override
  State<CreateProjectDetails> createState() => _CreateProjectDetailsState();
}

class _CreateProjectDetailsState extends State<CreateProjectDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Placeholder'),
      ),
      body: Column(
        children: <Widget>[
          //Image(image:,),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: .5),
                bottom: BorderSide(color: Colors.white, width: .5),
              ),
              color: Color(0x699F9F9F),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  "Project Name",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.edit),
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                'Project Description',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: .5),
                bottom: BorderSide(color: Colors.white, width: .5),
              ),
              color: Color(0x699F9F9F),
            ),
            child: Text('data'),
          ),
          SizedBox(height: 30),
          Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: Color(0x699F9F9F),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color(0x98474747),
                  spreadRadius: 3,
                  blurRadius: 3,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 77.5),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  // foregroundColor: foregroundColor,
                  backgroundColor: Colors.black,
                ),
                onPressed: () => {
                  // TODO: Function
                },
                label: Text('Update Map'),
                icon: Icon(Icons.location_on),
                iconAlignment: IconAlignment.start,
              ),
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "Research Activities",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    // foregroundColor: foregroundColor,
                    // backgroundColor: backgroundColor,
                  ),
                  onPressed: () => {
                    // TODO: Function
                  },
                  label: Text('Create'),
                  icon: Icon(Icons.add),
                  iconAlignment: IconAlignment.end,
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0x22535455),
                border: Border(
                  top: BorderSide(color: Colors.white, width: .5),
                ),
              ),
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}