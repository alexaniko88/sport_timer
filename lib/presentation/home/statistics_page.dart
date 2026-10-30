part of 'home.dart';

final class Section {
  final List<Item> items;
  final String title;

  Section(
    this.title,
    this.items,
  );
}

final class Item {
  final String content;

  Item(this.content);
}

class StatisticPage extends StatefulWidget {
  final AccountViewModel accountViewModel;

  const StatisticPage({
    super.key,
    required this.accountViewModel,
  });

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statisticsTitle),
        actions: [
          AccountAvatarButton(viewModel: widget.accountViewModel),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          for (final section in [
            Section(
              l10n.statisticsSectionTitle,
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
            ),
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
