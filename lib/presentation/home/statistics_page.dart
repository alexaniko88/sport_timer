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
    final userRepository = getIt<UserRepository>();
    final currentUser = userRepository.getCurrentUser();
    final userName = currentUser?.email?.split('@').first ?? 'User';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Hello, $userName!'),
      ),
      body: CustomScrollView(
        slivers: [
          for (final section in [
            Section(
              "Here are your training statistics",
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
    );
  }
}
