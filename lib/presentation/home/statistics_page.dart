part of 'home.dart';

final class Section {
  Section(
    this.title,
    this.items,
  );

  final List<Item> items;
  final String title;
}

final class Item {
  Item(this.content);

  final String content;
}

class StatisticPage extends StatelessWidget {
  const StatisticPage({super.key});

  @override
  Widget build(BuildContext context) {
    final timerStyle = Theme.of(context).extension<TimerStyle>()!;
    readData();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Check out your statistics'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            for (final section in [
              Section(
                "title",
                [
                  Item("A"),
                  Item("B"),
                  Item("C"),
                  Item("D"),
                  Item("E"),
                  Item("F"),
                  Item("A"),
                  Item("B"),
                  Item("C"),
                  Item("D"),
                  Item("E"),
                  Item("F"),
                  Item("A"),
                  Item("B"),
                  Item("C"),
                  Item("D"),
                  Item("E"),
                  Item("F"),
                ],
              )
            ])
              SliverMainAxisGroup(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: Text(
                      section.title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ListTile(
                        title: Text(section.items[index].content),
                      ),
                      childCount: section.items.length,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void readData() async {
    final statistics = FirebaseFirestore.instance.collection('statistics');

    await FirebaseFirestore.instance.collection('statistics').get().then((event) {
      for (var doc in event.docs) {
        printLog("THE DATA IS: ${doc.id} => ${doc.data()}");
        final data = doc.data();
        printLog("USER ID: ${doc['userId']}");
      }
    });
  }
}
