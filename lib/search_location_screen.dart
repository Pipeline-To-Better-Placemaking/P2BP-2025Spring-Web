import 'package:flutter/material.dart';
import 'db_schema_classes.dart';
import 'themes.dart';
import 'project_details_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required Project partialProjectData});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool isSearching =
      false; // Track whether the user is typing in the search bar
  bool hasSearched = false; // Track whether the user has already hit Enter
  String searchText = "Search places"; // Default hint text
  double searchBarWidth = 0.0; // Search bar width (initialized dynamically)
  double resultsSearchBarWidth = 0.0;

  @override
  Widget build(BuildContext context) {
    resultsSearchBarWidth = MediaQuery.of(context).size.width * 0.70;
    searchBarWidth = hasSearched
        ? resultsSearchBarWidth
        : MediaQuery.of(context).size.width - 32;
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF2F6DCF)),
            onPressed: () {
              Navigator.pop(context); // Navigate back to the previous screen;
            },
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Row(
                    mainAxisAlignment: hasSearched
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 300), // Animation speed
                        curve: Curves.easeInOut, // Animation curve
                        width: searchBarWidth, // Dynamic width
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 234, 245, 255),
                          borderRadius: BorderRadius.circular(18.0),
                          border:
                              Border.all(color: Color(0xFF2F6DCF), width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: hasSearched
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                    child: Text(
                                      searchText, // Display the search term
                                      style: TextStyle(
                                          color: const Color(0xFF2F6DCF)),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel_outlined,
                                        color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        hasSearched =
                                            false; // Reset to default state
                                        isSearching = false;
                                        searchText = "";
                                      });
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  // Back Arrow (only visible when isSearching == true)
                                  if (isSearching)
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back,
                                            color: Color(0xFF2F6DCF)),
                                        onPressed: () {
                                          setState(() {
                                            isSearching =
                                                false; // Reset isSearching
                                          });
                                          FocusScope.of(context)
                                              .unfocus(); // Hide the keyboard
                                        },
                                      ),
                                    ),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          isSearching = value.isNotEmpty;
                                          searchText = value;
                                        });
                                      },
                                      onSubmitted: (value) {
                                        // Change state when search bar is tapped
                                        setState(() {
                                          hasSearched = true;
                                          searchText = value.isNotEmpty
                                              ? value
                                              : "Search";
                                        });
                                        _showSearchResults(context);
                                      },
                                      onTap: () {
                                        setState(() {
                                          isSearching = true;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: isSearching
                                            ? EdgeInsets.zero
                                            : EdgeInsets.fromLTRB(15, 0, 0, 0),
                                        hintText: "Search places",
                                        hintStyle:
                                            TextStyle(color: Color(0xFF999999)),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  // Show either the Divider/Filter button combo or the clear button
                                  if (!isSearching) ...[
                                    // Vertical Divider
                                    Container(
                                      height: 24.0, // Height of the divider
                                      width: 1.0, // Thickness of the divider
                                      color: Color(0xFF999999), // Divider color
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                    ),
                                    // Filter icon
                                    IconButton(
                                      icon: Icon(Icons.tune,
                                          color: Color(0xFF999999)),
                                      onPressed: () {
                                        // Add filter functionality here
                                      },
                                    ),
                                  ] else
                                    // Clear all button
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined,
                                          color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          searchText =
                                              ""; // Clear all entered text
                                        });
                                      },
                                    )
                                ],
                              ),
                      ),

                      if (hasSearched)
                        const SizedBox(
                            width:
                                8), // Space between search bar and filter button
                      if (hasSearched)
                        //Filter Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle filter action
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                  255, 234, 245, 255), // Background color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                                side: BorderSide(
                                    color: Color(0xFF2F6DCF), width: 1.5),
                              ),
                              padding: const EdgeInsets.all(0),
                              minimumSize: Size(55.0, 55.0),
                            ),
                            child: Icon(Icons.tune, color: Color(0xFF999999)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: hasSearched ? 4.0 : 8.0,
                    runSpacing: 8.0,
                    alignment: hasSearched
                        ? WrapAlignment.start
                        : WrapAlignment.center,
                    children: hasSearched
                        ? _buildFilterChips()
                        : _buildCategoryChips(),
                  ),

                  const SizedBox(height: 16),

                  // Map section
                  if (!isSearching) // Only render the map when the user isn't searching
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(
                                color: Color(0xFF2F6DCF), width: 1.5)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Map View Placeholder",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // Add map interaction functionality
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                  ),
                                  child: Text(
                                    "View Map",
                                    style: TextStyle(color: Colors.white),
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
            const SizedBox(height: 16),
            // Dropdown Search Results
            if (!hasSearched && isSearching)
              Positioned(
                  top: 75,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4.0, // Adds shadow for "hovering" effect
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 234, 245,
                            255), // Background color for search results
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: 10,
                        separatorBuilder: (context, index) => Divider(
                          color: Color(0xFF2F6DCF), // Divider color
                          height: 5.0, // Space around the divider
                        ),
                        itemBuilder: (context, index) {
                          // Build each search result
                          return ListTile(
                              leading: Icon(
                                Icons.search,
                                color: Color(0xFF2F6DCF),
                              ),
                              title: Text("Recent Search ${index + 1}",
                                  style: TextStyle(color: Color(0xFF2F6DCF))),
                              onTap: () {
                                // Handle recent search tap
                              });
                        },
                      ),
                    ),
                  )),
          ],
        ));
  }

  void _showSearchResults(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Search Results",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Result ${index + 1}"),
                    subtitle: Text("${(index + 1) * 10} miles away"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Handle result action
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailsPage(
                                projectData: Project.partialProject(
                                    title: 'No data sent',
                                    description:
                                        'Accessed without project data'),
                              ),
                            ));
                      },
                      child: const Text("Select"),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCategoryChips() {
    return [
      _buildChip("Parks", Icons.park),
      _buildChip("Schools", Icons.school),
      _buildChip("Landmarks", Icons.account_balance),
      _buildChip("Shopping Centers", Icons.store_mall_directory),
      _buildChip("Cultural Centers", Icons.theater_comedy),
      _buildChip("Transit Hubs", Icons.directions_bus),
      _buildChip("Plazas", Icons.apartment),
      _buildChip("More", Icons.more_horiz),
    ];
  }

  List<Widget> _buildFilterChips() {
    return [
      _buildChip("Sort by", Icons.arrow_drop_down),
      _buildChip("Open now"),
      _buildChip("Accessibility", Icons.arrow_drop_down),
    ];
  }

  Widget _buildChip(String label, [IconData? icon]) {
    return GestureDetector(
      onTap: () {
        setState(() {
          searchText = label;
          hasSearched = true;
          _showSearchResults(context); // Update hint text when chip is tapped
        });
      },
      child: Chip(
        label: hasSearched
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 4.0), // Space between text and icon
                    Icon(
                      icon,
                      size: 24.0,
                      color: Color(0xFF999999),
                    ),
                  ],
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24.0, color: Color(0xFF999999)),
                    const SizedBox(width: 4.0), // Space between icon and text
                  ],
                  Text(
                    label,
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                ],
              ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: Color(0xFF2F6DCF), width: 1.5),
        ),
        backgroundColor: const Color.fromARGB(255, 234, 245, 255),
      ),
    );
  }
}

//  // Hint Text
//                       Flexible(
//                         child:
//                       if (isSearching) ...[
//                         // Cancel button for when search bar has been tapped
//                         IconButton(
//                           icon: Icon(Icons.cancel_outlined, color: Colors.grey),
//                           onPressed: () {
//                             setState(() {
//                               isSearching = false; // Deactivate dropdown
//                               hintText = "Search places"; // Reset hint text
//                             });
//                           },
//                         ),
//                       ],
//                       // Filter buttons
//                       if (hasSearched) ...[
//                         IconButton(
//                             icon:
//                                 Icon(Icons.cancel_outlined, color: Colors.grey),
//                             onPressed: () {
//                               setState(() {
//                                 hasSearched = false;
//                                 hintText = "Search places";
//                               });
//                             })
//                       ],
//                     ],
//                   ),
//                 ),
//               ],
//               )

//           const SizedBox(height: 16),

//           if(!hasSearched)
//           Center(

//           )

//