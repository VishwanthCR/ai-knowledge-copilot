import 'package:flutter_test/flutter_test.dart';

import 'package:ai_knowledge_copilot/main.dart';

void main() {
  testWidgets(
    'AI Knowledge Copilot loads successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const AIKnowledgeCopilotApp(),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('AI Knowledge Copilot'),
        findsWidgets,
      );

      expect(
        find.text('Document Chat'),
        findsOneWidget,
      );
    },
  );
}