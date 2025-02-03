import 'package:flutter/material.dart';
import 'strings.dart';
import 'theme.dart';
import 'themes.dart';

enum _PageNames { text, compare }

// Nonsense filler until backend is started
const List<String> _testNames = <String>[
  'Acoustical Profile',
  'Spatial Boundaries',
  'Nature Prevalence',
  'Lighting Profile',
  'Absence Of Order Locator',
  'People In Place',
  'People In Motion',
  'Community Survey',
  'Identifying Access',
  'Identifying Program',
  'Section Cutter',
];

const List<String> _projects = [
  'Project Nona',
  'Project Eola',
  'Project Osceola',
  'Project Oviedo',
  'Project Orlando'
];
// End filler
const String _dropdownDefault = 'Select Project';

class ProjectComparisonPage extends StatefulWidget {
  const ProjectComparisonPage({super.key});

  @override
  State<ProjectComparisonPage> createState() => _ProjectComparisonPageState();
}

class _ProjectComparisonPageState extends State<ProjectComparisonPage> {
  static const _pages = [
    _TextPage(),
    _CompareDataPage(),
  ];
  _PageNames currentPage = _PageNames.text;

  // Needs to be initialized in initState() to pass callback, hence late
  late final _DropdownRowForm _dropdownRowForm;

  @override
  void initState() {
    super.initState();
    _dropdownRowForm = _DropdownRowForm(pageChangeCallback);
  }

  /// Used to switch to project comparison view once projects are selected.
  /// setState must be called in this class to work but controllers and logic
  /// are within _DropdownRowForm, requiring this callback function.
  void pageChangeCallback(_PageNames newPage) {
    if (currentPage != newPage) {
      setState(() {
        currentPage = newPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[700],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  // Permanent row with dropdowns at top
                  _dropdownRowForm,
                  const SizedBox(height: 25),
                  // Dynamically switches between text default and comparison
                  _pages[currentPage.index],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Form containing row which just has two dropdown menus of projects
class _DropdownRowForm extends StatefulWidget {
  /// Required callback function from parent for passing page to since using
  /// setState() here would not update anything outside this Form.
  final Function pageChangeCallback;

  const _DropdownRowForm(this.pageChangeCallback, {super.key});

  @override
  State<_DropdownRowForm> createState() => _DropdownRowFormState();
}

class _DropdownRowFormState extends State<_DropdownRowForm> {
  final TextEditingController _dropdownController1 = TextEditingController(),
      _dropdownController2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start listening to changes to dropdown selection
    _dropdownController1.addListener(_checkBothDropdownSelected);
    _dropdownController2.addListener(_checkBothDropdownSelected);
  }

  // Passes compare page if two projects have been selected, else text page
  void _checkBothDropdownSelected() {
    if ((_dropdownController1.text.isNotEmpty &&
            _dropdownController1.text != _dropdownDefault) &&
        (_dropdownController2.text.isNotEmpty &&
            _dropdownController2.text != _dropdownDefault)) {
      widget.pageChangeCallback(_PageNames.compare);
    } else {
      widget.pageChangeCallback(_PageNames.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: _ProjectDropdown(
              controller: _dropdownController1,
            ),
          ),
          Spacer(flex: 2),
          Expanded(
            flex: 12,
            child: _ProjectDropdown(
              controller: _dropdownController2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dropdownController1.dispose();
    _dropdownController2.dispose();
    super.dispose();
  }
}

/// Widget for dropdown menu of projects, displayed twice at top of this screen
class _ProjectDropdown extends StatefulWidget {
  final TextEditingController? controller;

  const _ProjectDropdown({super.key, this.controller});

  @override
  State<_ProjectDropdown> createState() => _ProjectDropdownState();
}

class _ProjectDropdownState extends State<_ProjectDropdown> {
  @override
  Widget build(BuildContext context) {
    final dropdownMenuEntries = _buildDropdownEntryList();

    return Container(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        gradient: verticalBlueGrad,
      ),
      child: DropdownMenu<String>(
        controller: widget.controller,
        menuStyle: MenuStyle(
          alignment: Alignment.bottomLeft,
          backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueAccent),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.only(left: 9),
          constraints: BoxConstraints(maxHeight: 55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        trailingIcon: Icon(
          Icons.arrow_drop_down,
          color: Colors.white60,
        ),
        selectedTrailingIcon: Icon(
          Icons.arrow_drop_up,
          color: Colors.white60,
        ),
        initialSelection: _dropdownDefault,
        dropdownMenuEntries: dropdownMenuEntries,
      ),
    );
  }

  /// Constructs the list of entries for project dropdowns
  // Primarily constructed this way to hopefully be easy to
  // use with the backend once that is started
  // This will almost certainly need to be changed significantly once backend
  List<DropdownMenuEntry<String>> _buildDropdownEntryList() {
    List<DropdownMenuEntry<String>> result = [];

    // Default entry
    result.add(
      DropdownMenuEntry(
        value: _dropdownDefault,
        label: _dropdownDefault,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          visualDensity: VisualDensity(vertical: -2.5),
        ),
      ),
    );

    // Loops through all projects
    for (var project in _projects) {
      result.add(
        DropdownMenuEntry(
          value: project,
          label: project,
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            visualDensity: VisualDensity(vertical: -2.5),
          ),
        ),
      );
    }

    return result;
  }
}

/// Default lower/middle section of page with text instructions on how to use.
class _TextPage extends StatelessWidget {
  const _TextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(Strings.compareProjectText1),
        SizedBox(height: 18),
        Text(Strings.compareProjectText2),
      ],
    );
  }
}

/// Page displaying data from tests common to both selected projects.
class _CompareDataPage extends StatefulWidget {
  const _CompareDataPage({super.key});

  @override
  State<_CompareDataPage> createState() => _CompareDataPageState();
}

class _CompareDataPageState extends State<_CompareDataPage>
    with TickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: _testNames.length, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _TestNavigationTabBar(
            tabController: _tabController,
          ),
          Spacer(flex: 1),
          Expanded(
            flex: 40,
            child: _TestTabBarView(
              tabController: _tabController,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// TabBar that displays all tests common to both selected projects.
class _TestNavigationTabBar extends StatefulWidget {
  final TabController tabController;

  const _TestNavigationTabBar({super.key, required this.tabController});

  @override
  State<_TestNavigationTabBar> createState() => _TestNavigationTabBarState();
}

class _TestNavigationTabBarState extends State<_TestNavigationTabBar> {
  @override
  void initState() {
    super.initState();
    // TODO once backend: get list of tests that these projects have in common
  }

  @override
  Widget build(BuildContext context) {
    // final List<ButtonSegment> buttonSegments = _buildButtonSegmentList();
    final List<Tab> testTabList = _buildTestTabList();

    return Container(
      constraints: BoxConstraints(
        minHeight: 56,
        maxHeight: 64,
      ),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        gradient: verticalBlueGrad,
      ),
      child: TabBar(
        controller: widget.tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: 4),
        indicator: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        tabs: testTabList,
      ),
    );
  }

  /// Builds the tabs dynamically based on tests in common.
  List<Tab> _buildTestTabList() {
    // TODO once backend: backend test fetching stuff
    List<Tab> result = [];

    for (var name in _testNames) {
      result.add(
        Tab(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 80),
            child: Text(
              name,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return result;
  }
}

class _TestTabBarView extends StatefulWidget {
  final TabController tabController;

  const _TestTabBarView({super.key, required this.tabController});

  @override
  State<_TestTabBarView> createState() => _TestTabBarViewState();
}

class _TestTabBarViewState extends State<_TestTabBarView> {
  @override
  void initState() {
    super.initState();
    // TODO once backend: get list of tests that these projects have in common
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> testViewList = _buildTestViewList();

    return TabBarView(
      controller: widget.tabController,
      children: testViewList,
    );
  }

  /// Builds the list of views dynamically based on tests in common.
  List<Widget> _buildTestViewList() {
    // TODO once backend: backend test fetching stuff again
    List<Widget> result = [];

    for (var name in _testNames) {
      result.add(
        Card(
          child: Container(
            padding: EdgeInsets.all(15),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              gradient: verticalBlueGrad,
            ),
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return result;
  }
}