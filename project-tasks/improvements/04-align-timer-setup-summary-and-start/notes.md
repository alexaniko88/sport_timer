
## Blocked

Needs permission for: `python3 - <<'EOF'
p='test/shared/presentation/widgets/app_button_test.dart'
s=open(p).read()
anchor="    group('secondary', () {"
new='''    group('label', () {
      testWidgets('is a single line with an ellipsis, with and without an icon', (tester) async {
        await tester.pumpWidget(_app(AppButton.primary(label: 'Go', onPressed: () {})));
        var text = tester.widget<Text>(find.text('Go'));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);

        await tester.pumpWidget(
          _app(AppButton.secondary(label: 'Go', icon: const Icon(Icons.add), onPressed: () {})),
        );
        text = tester.widget<Text>(find.text('Go'));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      });
    });

'''
s=s.replace(anchor,new+anchor,1)
open(p,'w').write(s)

p='test/features/templates/presentation/templates_page_test.dart'
s=open(p).read()
s=s.replace("import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';","import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';",1)
old="""        final buttonRect = tester.getRect(button);
        final labelRect = tester.getRect(sessionLabel);
"""
new="""        final labelText = tester.widget<Text>(sessionLabel);
        expect(labelText.maxLines, 1);
        expect(labelText.overflow, TextOverflow.ellipsis);
        expect(labelText.style?.fontSize, theme.textTheme.titleMedium?.fontSize);
        expect(labelText.style?.fontWeight, FontWeight.w500);
        expect(labelText.style?.color, theme.colorScheme.onSurfaceVariant);
        final durationText = tester.widget<Text>(find.text('05:10'));
        expect(durationText.maxLines, 1);
        expect(durationText.overflow, TextOverflow.ellipsis);
        expect(durationText.style?.fontSize, theme.textTheme.headlineSmall?.fontSize);
        expect(durationText.style?.fontWeight, FontWeight.w700);
        final buttonRect = tester.getRect(button);
        final labelRect = tester.getRect(sessionLabel);
"""
assert old in s
s=s.replace(old,new,1)
old="""        final material = tester.widget<Material>(find.descendant(of: button, matching: find.byType(Material)).first);
        expect(material.color, theme.colorScheme.primary);
        final node = tester.getSemantics(find.text(label));"""
new="""        final buttonStyle = FilledButtonTheme.of(buttonContext).style!;
        final buttonTextStyle = buttonStyle.textStyle!.resolve({});
        expect(buttonTextStyle?.fontSize, theme.textTheme.headlineSmall?.fontSize);
        expect(buttonTextStyle?.fontWeight, FontWeight.w700);
        expect(buttonStyle.iconSize!.resolve({}), AppSpacing.s40);
        expect(buttonStyle.minimumSize!.resolve({}), const Size(0, 48));
        expect(
          buttonStyle.padding!.resolve({}),
          const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s8),
        );
        final startText = tester.widget<Text>(find.descendant(of: button, matching: find.text(label)));
        expect(startText.maxLines, 1);
        expect(startText.overflow, TextOverflow.ellipsis);
        final icon = find.descendant(of: button, matching: find.byIcon(Icons.play_arrow));
        expect(IconTheme.of(tester.element(icon)).size, AppSpacing.s40);
        final material = tester.widget<Material>(find.descendant(of: button, matching: find.byType(Material)).first);
        expect(material.color, theme.colorScheme.primary);
        final node = tester.getSemantics(find.text(label));"""
assert old in s
s=s.replace(old,new,1)
old="""        await tester.pumpAndSettle();
        expect(tester.getRect(button), buttonRect);"""
new="""        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TimerSettingCard).last);
        await tester.pumpAndSettle();
        expect(tester.getRect(button), buttonRect);"""
assert old in s
s=s.replace(old,new,1)
open(p,'w').write(s)
EOF
fvm dart format test/shared/presentation/widgets/app_button_test.dart test/features/templates/presentation/templates_page_test.dart
fvm flutter test test/shared/presentation/widgets/app_button_test.dart test/features/templates/presentation/templates_page_test.dart 2>&1 | tail -40`, `sed -i 's/final labelText = tester.widget<Text>(sessionLabel);/final appTheme = Theme.of(tester.element(sessionLabel));\n        final labelText = tester.widget<Text>(sessionLabel);/; s/theme\.textTheme\.titleMedium?\.fontSize/appTheme.textTheme.titleMedium?.fontSize/; s/theme\.textTheme\.headlineSmall?\.fontSize/appTheme.textTheme.headlineSmall?.fontSize/' test/features/templates/presentation/templates_page_test.dart && fvm dart format test/features/templates/presentation/templates_page_test.dart && fvm flutter test test/shared/presentation/widgets/app_button_test.dart test/features/templates/presentation/templates_page_test.dart 2>&1 | grep -v "^00:0.*+[0-9]*: /" | tail -30`. Relaunch with --allow="Bash(<program>:*)".
