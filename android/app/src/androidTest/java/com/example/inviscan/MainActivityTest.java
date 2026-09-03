package com.example.inviscan;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

// Ponte de instrumentação: executa os testes de integração Dart
// (integration_test/) como testes androidTest instrumentados no dispositivo.
// Rodar: ./gradlew app:connectedAndroidTest  (ou via Firebase Test Lab).
@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule
  public ActivityTestRule<MainActivity> rule =
      new ActivityTestRule<>(MainActivity.class, true, false);
}
